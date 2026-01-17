---
last_modified: 2024-01-13
number headings: first-level 2, max 3, 1.1, auto
---

#  Quick Start

## 1 VSCode

- [[vscode|CodeServer]]: Using code-server on EC2 instead of Cloud9 due to it has been deprecated

## 2 Cloud9

- [Quick Setup Cloud9](quick-setup-cloud9): 简化创建 Cloud9 脚本，优先选择使用 Terraform 自动初始化；也可以使用脚本从 CloudShell 中完成初始化
    - [[example_instancestack_ubuntu.yaml]] 
    - [[bootstrapping-python.py]]
- [Setup Cloud9 for EKS](setup-cloud9-for-eks): 使用脚本完成实验环境初始化
    - 初始化 ubuntu
        - [[script-prep-eks-env-part-one.sh]]
        - [[script-ubuntu-prep-eks-env-part-one.sh]]
    - 初始化 eks 相关命令行
        - [[script-prep-eks-env-part-two.sh]]

        ```bash
curl --location https://panlm.github.io/cloud9/script-prep-eks-env-part-two.sh |sh
        ```

    - 初始化其他内容
        - [[script-prep-eks-env-part-three.sh]]


## 3 Others

- [create standard vpc for lab in china region](create-standard-vpc-for-lab-in-china-region.md): 创建实验环境所需要的 VPC ，并且支持直接 attach 到 TGW 方便网络访问

