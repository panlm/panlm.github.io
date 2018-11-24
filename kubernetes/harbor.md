
# installation
* Add ```10.132.250.203 harbor.com``` to hosts file. it will be used in harbor.cfg file
* refer the [Guide](https://github.com/goharbor/harbor/blob/master/docs/installation_guide.md), and enable SSH access ([HERE](https://github.com/goharbor/harbor/blob/master/docs/configure_https.md))
* reconfig / start / stop 
```bash
vi harbor.cfg
./prepare
docker-composer down -v
docker-composer up -d
```

# push image
* ensure no proxy used by docker `/usr/lib/systemd/system/docker.service`
* put harbor certification files to ```/etc/docker/certs.d/hostname.com/``` (refer [HERE](https://github.com/goharbor/harbor/blob/master/docs/configure_https.md))
    * hostname.com.cert 
    * hostname.com.key
    * ca.key
* docker login harbor.com (option)
* tag image which one you want to push
    ```docker tag <image-id> harbor.com/library/image_name:image_version```
* push image
    ```docker push```
