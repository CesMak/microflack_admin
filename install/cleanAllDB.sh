#!/bin/bash -e

# This script deletes the mysql and reinstalls it!

## Setup some Color
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'

export INSTALL_PATH=$PWD/../..
source $INSTALL_PATH/.mysql_root_password

echo ''
echo -e "${RED}Stop all and remove mysql container${NC}"
docker stop mysql
docker rm mysql

echo -e "${RED}DELETE mysql-data-dir folder${NC}"
sudo rm -rf $INSTALL_PATH/mysql-data-dir
mkdir -p $INSTALL_PATH/mysql-data-dir

echo -e "${BLUE}Restart docker${NC}"
docker run --name mysql -d --restart always -p 3306:3306 -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD -v $INSTALL_PATH/mysql-data-dir:/var/lib/mysql mysql:5.7

#YOU HAVE TO MANUALLY REBUILD AFTERWARDS MESSAGES AND USERS SERVICE!
# however this does not solve all issues yet! (users db seems to be deleted afterwards but not messages!)
