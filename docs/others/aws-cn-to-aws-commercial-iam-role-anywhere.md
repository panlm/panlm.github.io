---
title: aws-cn-to-aws-commercial-iam-role-anywhere
description: aws 中国区用 role anywhere访问 aws global 区
type: note
permalink: work-notes/aws-cn-aws
---

## Cross-partition access: AWS China to AWS Commercial via IAM Roles Anywhere

Reference: https://aws.amazon.com/blogs/security/transfer-data-across-aws-partitions-with-iam-roles-anywhere/

### Why IAM Roles Anywhere?

```
普通 cross-account:  Account A ──AssumeRole──▶ Account B
                     同一个 IAM 平面，直接信任即可

跨分区 (cn ↔ aws):   aws-cn 的 IAM  ≠  aws 的 IAM
                     两套独立的身份系统
                     trust policy 写对方分区的 principal → 直接报错

所以需要一个「分区外」的身份凭据 → X.509 证书
IAM Roles Anywhere 就是把 X.509 证书翻译成 STS 临时凭证的桥梁
```

一句话：**IAM Roles Anywhere = X.509 证书 → STS 临时凭证的翻译器**。让任何能持有证书的地方（另一个分区、on-prem、IoT 设备）都能像 EC2 instance profile 一样免 AK/SK 地调 AWS API。

### Architecture

```
 cn-north-1 (aws-cn, <CN_ACCOUNT_ID>)                   us-west-2 (aws, <COM_ACCOUNT_ID>)
 ┌─────────────────────────────────┐                    ┌──────────────────────────────────────┐
 │ VPC 10.x.0.0/16                 │                    │ IAM Roles Anywhere                   │
 │  └─ public subnet + IGW         │  ① client cert     │   Trust Anchor ← Root CA (self-sign) │
 │       └─ EC2                    │  (X.509 over TLS)  │   Profile → <ROLE_NAME>              │
 │            Ubuntu 24.04         │──────────────────▶  │                                      │
 │            /etc/ira/client.crt  │                    │ IAM Role                              │
 │            /etc/ira/client.key  │  ② temp creds      │   trust: rolesanywhere.amazonaws.com  │
 │            aws_signing_helper   │◀──────────────────  │   allow: secretsmanager:Get/Describe │
 │                                 │                    │                                      │
 │   aws --profile commercial \    │  ③ GetSecretValue  │ Secrets Manager                      │
 │     secretsmanager              │──────────────────▶  │   <SECRET_NAME>                      │
 │     get-secret-value            │                    │                                      │
 └─────────────────────────────────┘                    └──────────────────────────────────────┘
```

### How it works - 一次性准备（建立信任链）

```
管理员
  │
  ├─➊ 建一个 Root CA（自签名或 AWS Private CA）
  │     产出: root-ca.crt, root-ca.key
  │
  ├─➋ 用 Root CA 签发 client cert 给工作负载
  │     产出: client.crt, client.key
  │
  └─➌ 在目标 AWS 账号 (us-west-2) 做三件事：
        │
        ├─ Trust Anchor: 上传 root-ca.crt
        │   → "我信任这个 CA 签发的所有证书"
        │
        ├─ IAM Role: 创建角色，trust policy 写
        │   Principal: rolesanywhere.amazonaws.com
        │   → "IAM Roles Anywhere 服务可以 AssumeRole"
        │
        └─ Profile: 绑定 Role + 设置 session 时长
            → "用这个 Profile 来的请求，给它这个 Role"
```

建完之后的信任链：

```
root-ca.crt ──签发──▶ client.crt
     │                     │
     ▼                     ▼
Trust Anchor            EC2 上的工作负载
 (us-west-2              持有 client.crt + client.key
  "我认识这个CA")
```

### How it works - 运行时（每次需要凭证时）

这是 `aws_signing_helper credential-process` 每次被调用时干的事：

```
EC2 (cn-north-1)                               IAM Roles Anywhere (us-west-2)
     │                                                       │
     │  ➊ 用 client.key 对请求做数字签名                       │
     │     把 client.crt 附在请求里                            │
     │──── CreateSession (HTTPS) ──────────────────────────▶ │
     │                                                       │
     │                                             ➋ 收到请求，做两件事：
     │                                               a) 从 client.crt 提取 issuer
     │                                                  去 Trust Anchor 里找对应 CA
     │                                                  用 root-ca.crt 验签 client.crt
     │                                                  → 证书链合法？ ✓
     │                                               b) 验证数字签名
     │                                                  → 请求方确实持有 private key？ ✓
     │                                                       │
     │                                             ➌ 两项都通过 → 调用 STS AssumeRole
     │                                               用 Profile 绑定的 Role
     │                                               生成临时凭证 (AK/SK/Token, 1h TTL)
     │                                                       │
     │◀──── 返回临时凭证 ────────────────────────────────────│
     │                                                       │
     │  ➍ 拿到凭证，注入到 AWS CLI / SDK 的请求中              │
     │     正常调 AWS API（如 secretsmanager:GetSecretValue）  │
     │                                                       │
```

**关键**：整个过程没有任何长期 AK/SK 参与。client.key 从不离开 EC2，也不发给 AWS。AWS 只看到 client.crt（公钥）和用 private key 做的签名。

**Flow summary**:
1. EC2 上的 `aws_signing_helper` 用 X.509 client cert 向 Commercial 区 IAM Roles Anywhere 发起认证
2. IAM Roles Anywhere 用 Trust Anchor 中注册的 CA 验证证书，签发临时 STS 凭证 (1h TTL)
3. EC2 用临时凭证调用 us-west-2 Secrets Manager API

### Prerequisites

- Two AWS CLI profiles: one for cn-north-1 (China partition), one for us-west-2 (Commercial partition)
- OpenSSL (生成自签名 CA)
- 本地工作目录用于存放 PKI 文件和脚本

### Step 1 - Generate Root CA and client certificate

CA cert 必须带 `basicConstraints=critical,CA:TRUE` 扩展，否则 `CreateTrustAnchor` 会报 `Incorrect basic constraints for CA certificate`。

```bash
# Root CA key + cert (10 year)
openssl genrsa -out root-ca.key 4096

cat > root-ca.cnf <<'EOF'
[ req ]
distinguished_name = req_distinguished_name
x509_extensions    = v3_ca
prompt             = no

[ req_distinguished_name ]
C  = CN
O  = IRA-Test
OU = PKI
CN = IRA-Test-RootCA

[ v3_ca ]
basicConstraints       = critical, CA:TRUE
keyUsage               = critical, keyCertSign, cRLSign, digitalSignature
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

openssl req -x509 -new -nodes -key root-ca.key -sha256 -days 3650 \
  -config root-ca.cnf -out root-ca.crt

# Client key + cert (1 year, signed by Root CA)
openssl genrsa -out client.key 2048
openssl req -new -key client.key \
  -subj "/C=CN/O=IRA-Test/OU=Workloads/CN=cn-ec2-workload" \
  -out client.csr

cat > client.ext <<'EOF'
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
EOF

openssl x509 -req -in client.csr -CA root-ca.crt -CAkey root-ca.key \
  -CAcreateserial -out client.crt -days 365 -sha256 -extfile client.ext

openssl verify -CAfile root-ca.crt client.crt
```

### Step 2 - Commercial partition setup (us-west-2)

```bash
AWS="aws --profile <COM_PROFILE> --region us-west-2"

# 2.1 Secret
${AWS} secretsmanager create-secret \
  --name "<SECRET_NAME>" \
  --secret-string "hello-from-us-west-2"

# 2.2 IAM Role (trust IAM Roles Anywhere)
cat > trust-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "rolesanywhere.amazonaws.com" },
    "Action": [ "sts:AssumeRole", "sts:TagSession", "sts:SetSourceIdentity" ]
  }]
}
EOF

${AWS} iam create-role \
  --role-name ira-xpart-test-role \
  --assume-role-policy-document file://trust-policy.json

# 2.3 Inline policy - read secret
cat > secret-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [ "secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret" ],
    "Resource": "<SECRET_ARN>"
  }]
}
EOF

${AWS} iam put-role-policy \
  --role-name ira-xpart-test-role \
  --policy-name ira-xpart-test-policy \
  --policy-document file://secret-policy.json

# 2.4 Trust Anchor (upload Root CA cert)
${AWS} rolesanywhere create-trust-anchor \
  --name ira-xpart-test-trust-anchor \
  --source "sourceType=CERTIFICATE_BUNDLE,sourceData={x509CertificateData=\"$(cat root-ca.crt)\"}" \
  --enabled

# 2.5 Profile
${AWS} rolesanywhere create-profile \
  --name ira-xpart-test-profile \
  --role-arns "<ROLE_ARN>" \
  --duration-seconds 3600 \
  --enabled
```

### Step 3 - China partition setup (cn-north-1)

Launch an EC2 (m5.large, Ubuntu 24.04 `ami-062d2c5b771a4b959`) in a public subnet with SSH access.

### Step 4 - EC2 bootstrap

```bash
# Upload certs
scp client.crt client.key root-ca.crt ubuntu@<EC2_IP>:/tmp/
ssh ubuntu@<EC2_IP>

# On EC2:
sudo mkdir -p /etc/ira
sudo mv /tmp/client.crt /tmp/client.key /tmp/root-ca.crt /etc/ira/
sudo chown ubuntu:ubuntu /etc/ira/*    # credential_process runs as ubuntu
sudo chmod 600 /etc/ira/client.key

# Install AWS CLI v2
curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
cd /tmp && unzip -q awscliv2.zip && sudo ./aws/install

# Install aws_signing_helper (v1.8.1)
sudo curl -sSL -o /usr/local/bin/aws_signing_helper \
  https://rolesanywhere.amazonaws.com/releases/1.8.1/X86_64/Linux/Amzn2023/aws_signing_helper
sudo chmod +x /usr/local/bin/aws_signing_helper

# Configure AWS CLI profile
cat > ~/.aws/config <<'CFG'
[profile commercial]
region = us-west-2
credential_process = /usr/local/bin/aws_signing_helper credential-process \
  --certificate /etc/ira/client.crt \
  --private-key /etc/ira/client.key \
  --trust-anchor-arn <TRUST_ANCHOR_ARN> \
  --profile-arn <PROFILE_ARN> \
  --role-arn <ROLE_ARN>
CFG
```

### Step 5 - Verify

```bash
# STS identity — should show assumed-role in your Commercial account
aws --profile commercial sts get-caller-identity

# Read secret from us-west-2
aws --profile commercial secretsmanager get-secret-value \
  --secret-id <SECRET_NAME>
```

### Python SDK example

boto3 原生支持 `credential_process`，配好 `~/.aws/config` 后无需额外凭证代码：

```python
#!/usr/bin/env python3
import boto3

session = boto3.Session(profile_name="commercial")

# who am I?
sts = session.client("sts")
identity = sts.get_caller_identity()
print(f"Account: {identity['Account']}")
print(f"Arn:     {identity['Arn']}")

# read the secret
sm = session.client("secretsmanager", region_name="us-west-2")
resp = sm.get_secret_value(SecretId="<SECRET_NAME>")
print(f"Secret:  {resp['SecretString']}")
```

### Resource reference (replace with your own values)

| Item | Placeholder |
|---|---|
| CN Account ID | `<CN_ACCOUNT_ID>` |
| Commercial Account ID | `<COM_ACCOUNT_ID>` |
| Secret ARN | `arn:aws:secretsmanager:us-west-2:<COM_ACCOUNT_ID>:secret:<SECRET_NAME>` |
| IAM Role ARN | `arn:aws:iam::<COM_ACCOUNT_ID>:role/<ROLE_NAME>` |
| Trust Anchor ARN | `arn:aws:rolesanywhere:us-west-2:<COM_ACCOUNT_ID>:trust-anchor/<TA_ID>` |
| Profile ARN | `arn:aws:rolesanywhere:us-west-2:<COM_ACCOUNT_ID>:profile/<PROFILE_ID>` |
| EC2 Instance | cn-north-1, Ubuntu 24.04 with public IP |

### Troubleshooting / gotchas

1. **CreateTrustAnchor `Incorrect basic constraints for CA certificate`** -- Root CA cert 必须包含 `basicConstraints=critical,CA:TRUE` 扩展。`openssl req -x509 -subj ...` 默认不加这个扩展，必须用 config 文件指定 `v3_ca` section。

2. **aws_signing_helper 下载 URL** -- 当前正确路径是 `releases/1.8.1/X86_64/Linux/Amzn2023/aws_signing_helper`。旧版本路径或随意拼的路径会返回 S3 AccessDenied XML。

3. **`unable to parse private key`** -- `credential_process` 以当前用户 (ubuntu) 运行。如果 `/etc/ira/client.key` owner 是 root:root mode 600，ubuntu 读不到就报这个错。需要 `chown ubuntu:ubuntu`。

### Teardown

```bash
# 清理顺序：先终止 EC2、删 VPC，再删 IAM Roles Anywhere profile/trust-anchor、IAM role、secret
```

