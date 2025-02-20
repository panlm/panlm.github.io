---
title: deepseek-poc
description: Deepseek POC
created: 2025-02-20 08:45:09.344
last_modified: 2025-02-20
tags:
  - llm/deepseek
---

# deepseek-poc

## llama.cpp
量化版本 on sagemaker
https://github.com/aws-samples/llm_deploy_gcr/tree/main/sagemaker/DeepSeek-R1-671b_dynamic-quants

## vllm
refer: https://github.com/aws-samples/llm_deploy_gcr/tree/main/sagemaker/sagemaker_vllm
edited version: [deploy_and_test_vllm_djl.ipynb](file:///Users/panlm/Documents/customers/C-CDFSunrise/202501-deepseek/deploy_and_test_vllm_djl.ipynb)
in chapter 3.3
```
endpoint_model_name = sagemaker.utils.name_from_base(model_name, short=True)
local_code_path = endpoint_model_name
s3_code_path = f"s3://{default_bucket}/endpoint_code/vllm_byoc/{endpoint_model_name}.tar.gz"

%mkdir -p {local_code_path}

print("local_code_path:", local_code_path)

with open(f"{local_code_path}/start.sh", "w") as f:
    f.write(f"""
#!/bin/bash

# download model to local
s5cmd sync --concurrency 64 \
    {s3_model_path}/* /temp/model_weight

# the start script need to be adjust as you needed
# port needs to be $SAGEMAKER_BIND_TO_PORT

python3 -m vllm.entrypoints.openai.api_server \\
    --port $SAGEMAKER_BIND_TO_PORT \\
    --trust-remote-code \\
    --tensor-parallel-size 1 --max-model-len 8192 --enable-chunked-prefill=False \\
    --served-model-name {MODEL_ID} \\
    --model /temp/model_weight
""")

# delete --enforce-eager
# change model len 65536
# parallel size from 4 to 1
# no chunked prefill

```

## djl
same notebook with previous chapter 
[deploy_and_test_vllm_djl.ipynb](file:///Users/panlm/Documents/customers/C-CDFSunrise/202501-deepseek/deploy_and_test_vllm_djl.ipynb)
```
# import dotenv
import os
import sagemaker
import boto3

# dotenv.load_dotenv(".env", override=True)

# role_name = os.environ.get("role_name")

model_id="deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"
endpoint_name = "deepseek-15"

# model_id="llava-hf/llava-1.5-7b-hf"

sagemaker_session = sagemaker.session.Session()
region = sagemaker_session._region_name


try:
    role = sagemaker.get_execution_role() # If you online sagemaker notebook
except ValueError:
    iam = boto3.client("iam")
    role = iam.get_role(RoleName=role_name)["Role"]["Arn"]


image_uri = sagemaker.image_uris.retrieve(framework="djl-lmi", version="0.28.0", region=region)
instance_type = "ml.g5.2xlarge"

role_name, model_id, image_uri

```

```
model = sagemaker.Model(
  image_uri=image_uri,
  role=role,
  env={
      "HF_MODEL_ID": model_id,
      # "OPTION_ROLLING_BATCH": "vllm",
      "HF_MODEL_TRUST_REMOTE_CODE": "True",
      # "GPU_MEMORY_UTILIZATION": "0.99"
  }
)

model.deploy(
  instance_type=instance_type, 
  initial_instance_count=1, 
  endpoint_name=endpoint_name
)
```


