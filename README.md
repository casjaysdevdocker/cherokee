## 👋 Welcome to cherokee 🚀  

cherokee README  
  
  
## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update cherokee
```
  
## Install and run container
  
```shell
dockerHome="/var/lib/srv/$USER/docker/casjaysdevdocker/cherokee/cherokee/latest/rootfs"
mkdir -p "/var/lib/srv/$USER/docker/cherokee/rootfs"
git clone "https://github.com/dockermgr/cherokee" "$HOME/.local/share/CasjaysDev/dockermgr/cherokee"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/cherokee/rootfs/." "$dockerHome/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-cherokee-latest \
--hostname cherokee \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$dockerHome/data:/data:z" \
-v "$dockerHome/config:/config:z" \
-p 80:80 \
casjaysdevdocker/cherokee:latest
```
  
## via docker-compose  
  
```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdevdocker/cherokee
    container_name: casjaysdevdocker-cherokee
    environment:
      - TZ=America/New_York
      - HOSTNAME=cherokee
    volumes:
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/cherokee/cherokee/latest/rootfs/data:/data:z"
      - "/var/lib/srv/$USER/docker/casjaysdevdocker/cherokee/cherokee/latest/rootfs/config:/config:z"
    ports:
      - 80:80
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src casjaysdevdocker/cherokee
```
  
OR
  
```shell
git clone "https://github.com/casjaysdevdocker/cherokee" "$HOME/Projects/github/casjaysdevdocker/cherokee"
```
  
## Build container  
  
```shell
cd "$HOME/Projects/github/casjaysdevdocker/cherokee"
buildx 
```
  
## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  
