#!/bin/bash -e

# This script performs a complete install on a single host. Intended for
# development, staging and testing.

## Setup some Color
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'

echo -e "${GREEN}Docker Containers:${NC}"
docker container ls

echo ''
echo 'Stop all Docker Containers'
if [[ ! "$(docker ps -aq)" == "" ]]; then
docker stop $(docker ps -aq)
fi

echo ''
echo 'Remove all Docker Containers'
if [[ ! "$(docker ps -aq)" == "" ]]; then
docker rm $(docker ps -aq)
fi

export INSTALL_PATH=$PWD/../..

echo ''
echo 'Remove profile'
rm -f $INSTALL_PATH/.profile
rm -f $INSTALL_PATH/.mysql_root_password
rm -f $INSTALL_PATH/.mysql_passwords
#rm -f mysql-data-dir

GITROOT=https://github.com/cesmak
pushd $INSTALL_PATH/

# environment variables
export HOST_IP_ADDRESS=192.168.178.26  #$(ip route get 1 | awk '{print $NF;exit}')
export SECRET_KEY=$(pwgen -1 -c -n -s 32)
export JWT_SECRET_KEY=$(pwgen -1 -c -n -s 32)
export PATH=$PATH:$PWD/microflack_admin/bin
echo export INSTALL_PATH=$INSTALL_PATH >> $INSTALL_PATH/.profile
echo export HOST_IP_ADDRESS=$HOST_IP_ADDRESS >> $INSTALL_PATH/.profile
echo export SECRET_KEY=$SECRET_KEY >> $INSTALL_PATH/.profile
echo export JWT_SECRET_KEY=$JWT_SECRET_KEY >> $INSTALL_PATH/.profile
echo export PATH=\$PATH:$PWD/microflack_admin/bin >> $INSTALL_PATH/.profile

echo ''
echo -e "${GREEN}Install public Docker containers:${NC}"

# logging
docker run --name logspout -d --restart always -p 1095:80 -v /var/run/docker.sock:/var/run/docker.sock gliderlabs/logspout:latest

# deploy etcd
docker run --name etcd -d --restart always -p 2379:2379 -p 2380:2380 miguelgrinberg/easy-etcd:latest
export ETCD=http://$HOST_IP_ADDRESS:2379
echo export ETCD=$ETCD >> $INSTALL_PATH/.profile

# install etcdtool
docker pull mkoppanen/etcdtool

# deploy mysql
mkdir -p $INSTALL_PATH/mysql-data-dir
MYSQL_ROOT_PASSWORD=$(pwgen -1 -c -n -s 16)
docker run --name mysql -d --restart always -p 3306:3306 -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD -v $INSTALL_PATH/mysql-data-dir:/var/lib/mysql mysql:5.7
export DATABASE_SERVER=$HOST_IP_ADDRESS:3306
echo export DATABASE_SERVER=$DATABASE_SERVER >> $INSTALL_PATH/.profile
echo MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD >> $INSTALL_PATH/.mysql_root_password

# deploy redis
docker run --name redis -d --restart always -p 6379:6379 redis:3.2-alpine
export REDIS=$HOST_IP_ADDRESS:6379
echo export REDIS=$REDIS >> $INSTALL_PATH/.profile

# deploy load balancer
if [[ "$LOAD_BALANCER" == "traefik" ]]; then
    # use the traefik load balancer
    echo export LOAD_BALANCER=traefik >> $INSTALL_PATH/.profile
    docker run --name lb -d --restart always -p 80:80 -p 8080:8080 traefik:1.3 --etcd --etcd.endpoint="$HOST_IP_ADDRESS:2379" --web --web.address=":8080"
else
    # use the haproxy load balancer (recommended)
    echo export LOAD_BALANCER=haproxy >> $INSTALL_PATH/.profile
    docker run --name lb -d --restart always -p 80:80 -e ETCD_PEERS=$ETCD -e HAPROXY_STATS=1 miguelgrinberg/easy-lb-haproxy:latest
fi

# download the code and build containers
#git clone $GITROOT/microflack_admin

echo ''
echo -e "${GREEN}Finished starting docker containers${NC}"
docker container ls

echo ''
echo -e "${GREEN}Install pw mysql_passwords${NC}"
cd microflack_admin
source mfvars
install/make-db-passwords.sh
echo "source $PWD/mfvars" >> $INSTALL_PATH/.profile

echo ''
echo -e "${BLUE}Do mfenv showing environment variables${NC}"
mfenv

#mfclone ..
# mfbuild all
#
# # run services
# for SERVICE in $SERVICES; do
#     mfrun $SERVICE
# done
#
# popd
# echo MicroFlack is now deployed!
# echo - Run "source $INSTALL_PATH/.profile" or log back in to update your environment.
# echo - You may need some variables from $INSTALL_PATH/.profile if you intend to run services in another host.
