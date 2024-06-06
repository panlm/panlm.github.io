---
title: llm-llama3
description: 
created: 2024-04-29 11:36:37.548
last_modified: 2024-04-29
tags:
  - aws/aiml/llm
  - aws/aiml/sagemaker
---

# llm-llama3

## blog
- https://aws.amazon.com/blogs/machine-learning/meta-llama-3-models-are-now-available-in-amazon-sagemaker-jumpstart/
- https://www.philschmid.de/sagemaker-llama3

## llama2 fine tunning
- https://github.com/aws/amazon-sagemaker-examples/blob/main/introduction_to_amazon_algorithms/jumpstart-foundation-models/aws-trainium-inferentia-finetuning-deployment/llama-2-trainium-inferentia-finetuning-deployment.ipynb
- https://github.com/aws/amazon-sagemaker-examples/blob/main/introduction_to_amazon_algorithms/jumpstart-foundation-models/llama-2-finetuning.ipynb

### notebook
- https://github.com/xiaoqunnaws/Training_On_SageMaker?tab=readme-ov-file

### hardware

| Model     | Instance Type     | Quantization | # of GPUs per replica |
| --------- | ----------------- | ------------ | --------------------- |
| Llama 8B  | (ml.)g5.2xlarge   | -            | 1                     |
| Llama 70B | (ml.)g5.12xlarge  | gptq / awq   | 8                     |
| Llama 70B | (ml.)g5.48xlarge  | -            | 8                     |
| Llama 70B | (ml.)p4d.24xlarge | -            | 8                     |

refer: https://www.philschmid.de/sagemaker-llama3


