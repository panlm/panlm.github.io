---
title: docker-image-customized
description: 
created: 2023-06-01 12:06:05.890
last_modified: 2023-11-03 09:19:37.087
tags:
  - docker
---
> [!WARNING] This is a github note
# docker-image-sample

## flask app

- python_app.py
```python
#!/usr/bin/env python3
from flask import Flask
import os

app = Flask(__name__)
@app.route('/')
def index():
    return f"{{ OS Architecture: {os.uname().machine} }}"

if __name__ == '__main__':
    app().run(host='0.0.0.0')

```
- Dockerfile
```dockerfile
FROM public.ecr.aws/bitnami/python:3.7
EXPOSE 5000
WORKDIR /
COPY ./python_app.py /app.py
RUN pip install flask
CMD ["flask", "run", "--host", "0.0.0.0"]
```


## ubuntu-based

```
FROM python:2.7
#RUN ["apt-get", "update"]
#RUN ["apt-get", "install", "-y", "vim"]
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 5000
CMD python ./app.py

```


## centos-based

```
FROM centos:7
RUN ["yum", "install", "-y", "epel-release", "gcc", "python-devel", "python2-pip"]
RUN ["rpm", "-Uvh", "https://repo.mysql.com/mysql80-community-release-el7-3.noarch.rpm"]
RUN ["yum", "install", "-y", "--enablerepo=mysql80-community", "mysql-community-devel"]
COPY . /app
WORKDIR /app
RUN pip install -r requirements.txt
EXPOSE 5000
CMD python ./app.py

```


