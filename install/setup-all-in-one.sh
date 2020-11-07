#!/bin/bash -e

# This script performs a complete install on a single host. Intended for
# development, staging and testing.

## Setup some Color
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'

HTTPS_SERVERNAME=NOT_USE # set to NOT_USE if you do not want to use it alternative set to idgaming.de

# to delete all docker containers use: docker rmi -f $(docker images -a -q)
echo -e "${GREEN}Docker Containers:${NC}"
docker container ls

echo ''
echo -e "${RED}Stop all Docker Containers${NC}"
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
export HOST_IP_ADDRESS=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
export SECRET_KEY=$(pwgen -1 -c -n -s 32)
export JWT_SECRET_KEY=$(pwgen -1 -c -n -s 32)
export PATH=$PATH:$PWD/microflack_admin/bin
export HTTPS_SERVERNAME=$HTTPS_SERVERNAME
echo export INSTALL_PATH=$INSTALL_PATH >> $INSTALL_PATH/.profile
echo export HOST_IP_ADDRESS=$HOST_IP_ADDRESS >> $INSTALL_PATH/.profile
echo export SECRET_KEY=$SECRET_KEY >> $INSTALL_PATH/.profile
echo export JWT_SECRET_KEY=$JWT_SECRET_KEY >> $INSTALL_PATH/.profile
echo export PATH=\$PATH:$PWD/microflack_admin/bin >> $INSTALL_PATH/.profile
echo export HTTPS_SERVERNAME=$HTTPS_SERVERNAME >> $INSTALL_PATH/.profile

echo ''
echo -e "${GREEN}Install public Docker containers:${NC}"

# logging
docker run --name logspout -d --restart always -p 1095:80 -v /var/run/docker.sock:/var/run/docker.sock gliderlabs/logspout:latest

# deploy etcd
docker run --name etcd -d --restart always -p 2379:2379 -p 2380:2380 miguelgrinberg/easy-etcd:latest
export ETCD=http://$HOST_IP_ADDRESS:2379
echo export ETCD=$ETCD >> $INSTALL_PATH/.profile

# install etcdtool - service registry
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
    # use the haproxy load balancer (recommended this one is currently used!)
    echo export LOAD_BALANCER=haproxy >> $INSTALL_PATH/.profile
    #before: docker run --name lb -d --restart always -p 80:80 -e ETCD_PEERS=$ETCD -e HAPROXY_STATS=1 miguelgrinberg/easy-lb-haproxy:latest
    # Args:
    # HAPROXY_STATS=1 (stats page shown!)
    # HAPROXY_STATS_AUTH: if stats are enabled, this sets login credentials to access the stats page. (Optional, auth is disabled by default)
    # HAPROXY_SERVERNAME=idgaming.de #if you want to use ssl etc. in this case you need an all.pem file in your git repro.
    # available at: https://hub.docker.com/r/miguelgrinberg/easy-lb-haproxy

    if [ -d "$INSTALL_PATH/easy-lb-haproxy" ]
    then
        echo -e "easy-lb-haproxy ${GREEN} exists. ${NC}"
    else
        echo ""
        echo -e "easy-lb-haproxy ${RED} does not exist. -> I install it ${NC}"
        git clone https://github.com/CesMak/easy-lb-haproxy.git
        cd $INSTALL_PATH/easy-lb-haproxy

        #copy your all.pem file!
        # use certbot and letsencrypt first to generate your pem files
        # see: https://certbot.eff.org/lets-encrypt/ubuntufocal-haproxy

        if [[ "$HTTPS_SERVERNAME" == "NOT_USE" ]]; then
              echo "....HTTPS_SERVERNAME is ${RED}not${NC} used."
        else
          sudo cat /etc/letsencrypt/live/idgaming.de/cert.pem /etc/letsencrypt/live/idgaming.de/privkey.pem > "$INSTALL_PATH/easy-lb-haproxy"/all.pem
          ./build.sh
          rm "$INSTALL_PATH/easy-lb-haproxy"/all.pem
        fi
    fi
    echo ""
    echo -e "RUN easy-lb-haproxy NOW:"
    if [[ "$HTTPS_SERVERNAME" == "NOT_USE" ]]; then
          docker run --name lb -d --restart always -p 80:80 -e ETCD_PEERS=$ETCD -e HAPROXY_STATS=1 cesmak/easy-lb-haproxy:latest
    else
          docker run --name lb -d --restart always -p 80:80 -e ETCD_PEERS=$ETCD -e HAPROXY_STATS=1 -e HAPROXY_SERVERNAME=idgaming.de cesmak/easy-lb-haproxy:latest
    fi

    echo ""
    echo ""
    echo -e "${GREEN} This is your final haproxy.cfg file:${NC}"
    sleep 0.6
    docker exec -it lb sed -i '/^[[:space:]]*$/d' /usr/local/etc/haproxy/haproxy.cfg
    docker exec -it lb cat /usr/local/etc/haproxy/haproxy.cfg
fi

# download the code and build containers
#git clone $GITROOT/microflack_admin

echo ''
echo -e "${GREEN}Finished starting docker containers${NC}"
docker container ls

echo ''
echo -e "${GREEN}Install pw mysql_passwords${NC}"
cd $INSTALL_PATH/microflack_admin

set -o allexport # required such that variables are outside available!
source mfvars
set +o allexport

install/make-db-passwords.sh
echo "source $PWD/mfvars" >> $INSTALL_PATH/.profile

echo ''
echo -e "${GREEN}Do mfenv showing environment variables${BLUE}"
mfenv

echo ''
echo -e "${GREEN}Clone services now ${NC}"
mfclone ..

echo ''
echo -e "${GREEN}Build all services ${NC}"
mfbuild all


sleep 2

# run services
for SERVICE in $SERVICES; do
  echo ''
  echo -e "${BLUE}Do mfrun $SERVICE ${NC}"
  mfrun $SERVICE
done

# TODO you might use ./rebuild inside easy-lb-haproxy
if [[ "$HTTPS_SERVERNAME" == "NOT_USE" ]]; then
      echo "do not rebuild the load balancer to register all the server services correctly cause LOCAL MODE (NOT HTTPS)"
else
  echo "Rebuild.... lb"
  cd $INSTALL_PATH/easy-lb-haproxy
  chmod +x rebuild
  ./rebuild
fi


echo ''
echo -e "${GREEN}Finished starting docker containers${NC}"
docker container ls

popd

# use mflogs to show all the logs of the docker containers

# echo MicroFlack is now deployed!
# echo - Run "source $INSTALL_PATH/.profile" or log back in to update your environment.
# echo - You may need some variables from $INSTALL_PATH/.profile if you intend to run services in another host.
