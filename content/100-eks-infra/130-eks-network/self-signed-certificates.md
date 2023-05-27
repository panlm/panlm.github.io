---
title: self-signed-certificates
description: 使用自签名证书，用根证书签发或者中间证书签发用于 api gateway
chapter: true
created: 2022-05-17 15:49:16.687
last_modified: 2023-03-23 01:33:16.924
tags: 
- aws/security/acm 
- aws/container/eks 
---

```ad-attention
title: This is a github note

```

# self-signed-certificates

- [1. has certificate chain](#1-has-certificate-chain)
	- [1.1. has certificate chain (with intermediate)](#11-has-certificate-chain-with-intermediate)
		- [refer](#refer)
	- [1.2. has certificate chain (root only)](#12-has-certificate-chain-root-only)
		- [refer](#refer)
- [2. no certificate chain](#2-no-certificate-chain)
- [refer](#refer)


## 1. has certificate chain

### 1.1. has certificate chain (with intermediate)
- works for api gateway and alb
- http endpoint in integration request need this kind certificate, and also set `insecureSkipVerification` to `true`

```sh
mkdir myrootca
cd myrootca/
git clone https://github.com/OpenVPN/easy-rsa.git
# create root ca and no password
./easy-rsa/easyrsa3/easyrsa init-pki
./easy-rsa/easyrsa3/easyrsa build-ca nopass
cd ..

```

```sh
mkdir myinterca
cd myinterca/
ln -sf ../myrootca/easy-rsa
# create intermedia ca and no password
./easy-rsa/easyrsa3/easyrsa init-pki
./easy-rsa/easyrsa3/easyrsa build-ca subca nopass

# sign intermedia ca
cd ../myrootca/
./easy-rsa/easyrsa3/easyrsa import-req ../myinterca/pki/reqs/ca.req myinterca
./easy-rsa/easyrsa3/easyrsa sign-req ca myinterca
cp -i pki/issued/myinterca.crt ../myinterca/pki/ca.crt
cd ..

```

```sh
mkdir mycert
cd mycert
ln -sf ../myrootca/easy-rsa/
# create certificate req and no password
./easy-rsa/easyrsa3/easyrsa init-pki
./easy-rsa/easyrsa3/easyrsa gen-req mycert nopass
# Common Name --> poc.aws.panlm.xyz

# sign certificate
cd ../myinterca/
./easy-rsa/easyrsa3/easyrsa import-req ../mycert/pki/reqs/mycert.req mycert
./easy-rsa/easyrsa3/easyrsa sign-req server mycert
cp ./pki/issued/mycert.crt ../mycert/
cd ..

```

```sh
cd mycert
openssl x509 -inform PEM -in mycert.crt >mycert.pem
openssl rsa -in ./pki/private/mycert.key >mycert-key.pem
openssl x509 -inform PEM -in ../myinterca/pki/ca.crt >mycert-chain-interca.pem
openssl x509 -inform PEM -in ../myrootca/pki/ca.crt >mycert-chain-root.pem
# first pem is certificate body 
# second pem is certificate private key
# rest of pems are certificate chain (last one should be root ca)
```

#### refer
- https://wavecn.com/content.php?id=334
- https://docs.aws.amazon.com/acm/latest/userguide/import-certificate-format.html


### 1.2. has certificate chain (root only)
- works for api gateway and alb
- http endpoint in integration request need this kind certificate, and also set `insecureSkipVerification` to `true`

```sh
mkdir mycert
cd mycert
git clone https://github.com/OpenVPN/easy-rsa.git

# create root ca and no password
./easy-rsa/easyrsa3/easyrsa init-pki
./easy-rsa/easyrsa3/easyrsa build-ca nopass

# create cert req
openssl genrsa -out my-server.key
openssl req -new -key my-server.key -out my-server.req
# Common Name --> *.aws.panlm.xyz
# display. if you want to modify, check the first link below
openssl req -in my-server.req -noout -subject

# sign cert
./easy-rsa/easyrsa3/easyrsa import-req my-server.req my-server
./easy-rsa/easyrsa3/easyrsa sign-req server my-server
# need root ca password

# convert to pem
openssl x509 -inform PEM -in pki/issued/my-server.crt >my-server.pem
openssl rsa -in my-server.key  > my-server-key.pem
openssl x509 -inform PEM -in pki/ca.crt >my-server-chain.pem
# 3 pems for certificate body / certificate private key / certificate chain

```

#### refer
- [How To Set Up and Configure a Certificate Authority (CA) On Ubuntu 20.04 | DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04)
- https://github.com/OpenVPN/easy-rsa/blob/master/README.quickstart.md


## 2. no certificate chain
- works for alb, not for api gateway

1. create self-signed certificate
```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out certificate.crt

# ... need input Common Name at least

openssl rsa -in privateKey.key -check
openssl x509 -in certificate.crt -text -noout
openssl rsa -in privateKey.key -text > private.pem
openssl x509 -inform PEM -in certificate.crt > public.pem

```
2. import certificate (2 pem files) to ACM in your region
3. add following to ingress yaml and apply it
```yaml
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
alb.ingress.kubernetes.io/ssl-redirect: '443'
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:xxxxxx:certificate/xxxxxx
```
4. add certificate to local keychain (1 crt file) / just type `thisisunsafe`
5. access URL



## refer

- works for api gateway and alb
- [[acm-issue-certificates]]

