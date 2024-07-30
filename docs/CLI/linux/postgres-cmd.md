---
title: postgres-cmd
description: 常用命令
created: 2023-08-23 08:21:46.893
last_modified: 2024-07-16
tags:
  - postgresql
---

# postgres-cmd

## install pg 16 client on amazon linux 2023
```sh
yum install -y gcc readline-devel libicu-devel zlib-devel openssl-devel systemd-devel
wget https://ftp.postgresql.org/pub/source/v16.3/postgresql-16.3.tar.gz  # PostgreSQL 16.1
tar -xzf postgresql-16.3.tar.gz
cd postgresql-16.3

./configure --with-systemd --with-openssl
make && make install

```

## dump
```sh
pg_dump -U postgres -d brconnector_db -a -h 172.17.0.1 > filename.sql

```

## H1

```
select table_name from information_schema.tables;
```

## replication in postgres

```
select client_addr, state, sent_lsn, write_lsn,
    flush_lsn, replay_lsn, sync_state from pg_stat_replication;
```


## running in docker
### run postgres in docker
```
docker run --name postgres \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p 5432:5432 \
  -d postgres

```

### create db
```
docker exec -it postgres psql -U postgres
CREATE DATABASE brproxydb;

```

### list db
```
docker exec -it postgres01 /bin/sh
 # psql -U postgres
CREATE DATABASE nutanix with owner postgres;

\l list database
\q quit psql

```

### others
```
docker-machine ssh docker01

./start-volume-plugin.sh
check ip address on interface docker0 and add to "filesystem whilelist"

docker inspect postgres01
docker inspect --format '{{.Config.Volumes}}' postgres01

docker run -d --name postgres01 -p 5432:5432 --volume-driver nutanix -v pgdata01:_var_lib_postgresql_data postgres:latest

```

```
docker ps
`docker exec -it NutanixVolumePlugin /bin/sh`
```

