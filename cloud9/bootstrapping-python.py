from __future__ import print_function
import boto3
import json
import os
import time
import traceback
import cfnresponse
import logging
logger = logging.getLogger()
logger.setLevel("INFO")

def lambda_handler(event, context):
    logger.info('event: {}'.format(event))
    logger.info('context: {}'.format(context))
    responseData = {}

    status = cfnresponse.SUCCESS
    
    if event['RequestType'] == 'Delete':
        responseData = {'Success': 'Custom Resource removed'}
        cfnresponse.send(event, context, status, responseData, 'CustomResourcePhysicalID')              

    if event['RequestType'] == 'Create':
        try:
            # Open AWS clients
            ec2 = boto3.client('ec2')

            # Get the InstanceId of the Cloud9 IDE
            instance = ec2.describe_instances(Filters=[{'Name': 'tag:Name','Values': ['aws-cloud9-'+event['ResourceProperties']['StackName']+'-'+event['ResourceProperties']['EnvironmentId']]}])['Reservations'][0]['Instances'][0]
            logger.info('instance: {}'.format(instance))

            # Create the IamInstanceProfile request object
            iam_instance_profile = {
                'Arn': event['ResourceProperties']['LabIdeInstanceProfileArn'],
                'Name': event['ResourceProperties']['LabIdeInstanceProfileName']
            }
            logger.info('iam_instance_profile: {}'.format(iam_instance_profile))

            # Wait for Instance to become ready before adding Role
            instance_state = instance['State']['Name']
            logger.info('instance_state: {}'.format(instance_state))
            while instance_state != 'running':
                time.sleep(5)
                instance_state = ec2.describe_instances(InstanceIds=[instance['InstanceId']])
                logger.info('instance_state: {}'.format(instance_state))

            instance_status = ec2.describe_instance_status(InstanceIds=[instance['InstanceId']])
            logger.info('instance_status: {}'.format(instance_status))
            instance_instancestatus = instance_status['InstanceStatuses'][0]['InstanceStatus']['Status']
            instance_systemstatus = instance_status['InstanceStatuses'][0]['SystemStatus']['Status']
            while instance_instancestatus != 'ok' or instance_systemstatus != 'ok': 
                time.sleep(15)
                instance_status = ec2.describe_instance_status(InstanceIds=[instance['InstanceId']])
                instance_instancestatus = instance_status['InstanceStatuses'][0]['InstanceStatus']['Status']
                instance_systemstatus = instance_status['InstanceStatuses'][0]['SystemStatus']['Status']
                logger.info('instance_status: {}'.format(instance_status))

            associations = ec2.describe_iam_instance_profile_associations(
                Filters=[
                    {
                        'Name': 'instance-id',
                        'Values': [instance['InstanceId']],
                    },
                    {
                        'Name': 'state',
                        'Values': ['associated']
                    }
                ],
            )
            logger.info('associations: {}'.format(associations))

            if len(associations['IamInstanceProfileAssociations']) > 0:
                for association in associations['IamInstanceProfileAssociations']:
                    instance_profile_arn = associations['IamInstanceProfileAssociations'][0]['IamInstanceProfile']['Arn']
                    instance_profile_name = instance_profile_arn.split('/')[-1]
                    iam = boto3.client('iam')
                    role_response = iam.get_instance_profile(InstanceProfileName=instance_profile_name)
                    role_name = role_response['InstanceProfile']['Roles'][0]['RoleName']
                    logger.info('role_name: {}'.format(role_name))
                    # add adminstratoraccess policy to role
                    policy_response = iam.attach_role_policy(RoleName=role_name, PolicyArn='arn:aws:iam::aws:policy/AdministratorAccess')
            else:
                # attach instance profile
                response = ec2.associate_iam_instance_profile(IamInstanceProfile=iam_instance_profile, InstanceId=instance['InstanceId'])
                logger.info('response - associate_iam_instance_profile: {}'.format(response))
                r_ec2 = boto3.resource('ec2')

            # reboot instance to 
            response1 = ec2.reboot_instances(InstanceIds=[instance['InstanceId']], DryRun=False)
            logger.info('response - reboot_instances: {}'.format(response1))
            time.sleep(10)
            instance_state = ec2.describe_instances(InstanceIds=[instance['InstanceId']])

            # Wait for Instance to become ready after reboot
            instance_state = instance['State']['Name']
            logger.info('instance_state: {}'.format(instance_state))
            while instance_state != 'running':
                time.sleep(5)
                instance_state = ec2.describe_instances(InstanceIds=[instance['InstanceId']])
                logger.info('instance_state: {}'.format(instance_state))

            responseData = {'Success': 'Started bootstrapping for instance: '+instance['InstanceId']}
            cfnresponse.send(event, context, status, responseData, 'CustomResourcePhysicalID')
            
        except Exception as e:
            status = cfnresponse.FAILED
            print(traceback.format_exc())
            responseData = {'Error': traceback.format_exc(e)}
        finally:
            cfnresponse.send(event, context, status, responseData, 'CustomResourcePhysicalID')
