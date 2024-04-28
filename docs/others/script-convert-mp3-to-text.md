---
title: script-convert-mp3-to-text
description: script-convert-mp3-to-text
created: 2023-12-09 12:09:31.654
last_modified: 2024-01-17
tags:
  - aws/aiml/transcribe
  - aws/cmd
---
# script-convert-mp3-to-text

i wrote this script several years ago. I have chance to use it in real life today and update to here

## updated version
- ensure you have export the `AWS_DEFAULT_REGION`
- download ([[convert-mp3-to-text.sh]] and [[conv-srt.py]])
```sh
#!/bin/bash
# 

OPTIND=1
OPTSTRING="h?f:"
filename=""
while getopts ${OPTSTRING} opt; do
    case "${opt}" in
        f) filename=${OPTARG} ;;
        h|\?) 
            echo "format: $0 -f filename.mp3"
            return 9
        ;;
    esac
done
: ${filename:?Missing -f}

string=`TZ=EAT-8 date +%Y%m%d%H%M%S`
mp3file=mp3-${string}.mp3
jobname=job-${string}
transcriptfile=${filename%.*}-${string}.txt
srtfile=${filename%.*}-${string}.en.srt
bucket_name=temp-${string}-$(uuidgen |tr 'A-Z' 'a-z')

aws s3 mb s3://${bucket_name}
if [[ $? -ne 0 ]]; then
  echo "create bucket failed"
fi

aws s3 cp $filename s3://${bucket_name}/$mp3file
#aws transcribe start-transcription-job --transcription-job-name $jobname \
# --language-code en-US --media MediaFileUri=s3://$bucket_name/$mp3file
aws transcribe start-transcription-job --transcription-job-name $jobname \
  --identify-language \
  --media MediaFileUri=s3://$bucket_name/$mp3file

if [[ $? -ne 0 ]]; then
  exit 
fi

output=/tmp/$$.output
echo "status file: $output"
while true ; do
  aws transcribe get-transcription-job --transcription-job-name $jobname > $output
  status=$(cat $output |jq -r '.TranscriptionJob.TranscriptionJobStatus')
  if [[ $status == "COMPLETED" ]]; then
    echo
    break
  else
    echo -e '.\c'
  fi
  sleep 60
done

cat $output |jq -r '.TranscriptionJob.Transcript.TranscriptFileUri' |xargs -J {} wget -O $output.wget '{}'
cat $output.wget |jq -r '.results.transcripts[0].transcript' > $transcriptfile
if [[ -f ./conv-srt.py ]]; then
  python3 ./conv-srt.py $output.wget > $srtfile
fi

#clean
aws s3 rm s3://$bucket_name/$mp3file

```



## refer
- https://github.com/panlm/NTNX/blob/master/scripts/translate/speechtext-aws.sh






