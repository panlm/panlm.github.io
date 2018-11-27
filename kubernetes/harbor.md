
# installation
* Add `10.132.250.203    harbor.com` to hosts file. it will be used in harbor.cfg file
* refer the [Guide](https://github.com/goharbor/harbor/blob/master/docs/installation_guide.md), and enable SSH access ([HERE](https://github.com/goharbor/harbor/blob/master/docs/configure_https.md))
* reconfig / start / stop 
    ```bash
    vi harbor.cfg
    ./prepare
    docker-composer down -v
    docker-composer up -d
    ```

# push image
* ensure no proxy settings used by docker `/usr/lib/systemd/system/docker.service`
* put harbor certification files to `/etc/docker/certs.d/hostname.com/` (refer [HERE](https://github.com/goharbor/harbor/blob/master/docs/configure_https.md))
    * hostname.com.cert 
    * hostname.com.key
    * ca.key
* docker login harbor.com (option)
* tag image which one you want to push
    ```
    docker tag <image-id> harbor.com/library/image_name:image_version
    ```
* push image
    ```
    docker push
    ```

# customized
## requirement
I want to push common images to local harbor server for quick access. These images come from different site, such as gcr.io, docker.io, quay.io. Common solution is setup one docker node and get all these images and re-tag them and push to harbor. Others host need to get these images with a different name, such as `<myhaber>/<mylibrary>/<image_name>;<version>`    

my thought is if these domain are point to one local ip address, host could get these images without change anything. Big problem is server certification, so in this chapter, i create a server certification and put Altname in it. If you connenct harbar server with another domain name, it also could get certification.

## solution
* create certifications
```bash
#!/bin/bash
set -x

openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
    -subj "/C=TW/ST=Taipei/L=Taipei/O=example/OU=Personal/CN=myca.com" \
    -key ca.key \
    -out ca.crt

for i in harbor.com ; do
    openssl genrsa -out $i.key 4096
    openssl req -sha512 -new \
        -subj "/C=TW/ST=Taipei/L=Taipei/O=example/OU=Personal/CN=$i" \
        -key $i.key \
        -out $i.csr
    cat > v3-$i.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=$i
DNS.2=${i%.*}
DNS.3=quay.io
DNS.4=k8s.gcr.io
DNS.5=gcr.io
DNS.6=docker.io
EOF
    openssl x509 -req -sha512 -days 3650 \
        -extfile v3-$i.ext \
        -CA ca.crt -CAkey ca.key -CAcreateserial \
        -in $i.csr \
        -out $i.crt
    openssl x509 -inform PEM -in $i.crt -out $i.cert
done
```

* stop harbor
```
cd harbar installation directory
docker-composer down -v
```

* copy server certification to harber /data/cert directory
```
cp harbor.com.[crt|key] /data/cert
```

* start harbor
```
./prepare
docker-composer up -d
```

* copy ca & server certifications to docker node
```
scp ca.crt /etc/docker/certs.d/harbor.com/
scp harbor.com.[crt|key] /etc/docker/certs.d/harbor.com/
```

* create link point to harbor.co
```
cd /etc/docker/certs.d/
ln -sf harbor.com quay.io
ln -sf harbor.com k8s.gcr.io
ln -sf harbor.com gcr.io
ln -sf harbor.com docker.io
```

* test on docker host
    * add lines to `/etc/hosts`
        ```
        10.132.250.203 harbor harbor.com quay.io docker.io gcr.io k8s.gcr.io
        ```
    * try login
        ```
        docker login harbor.com
        docker login quay.io
        docker login k8s.gcr.io
        ...
        ```

!!! docker.io could not work with this way 
