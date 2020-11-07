#!/bin/bash -e

# This script performs a complete install on a single host. Intended for
# development, staging and testing.

## Setup some Color
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'

if [[ "$INSTALL_PATH" == "" ]]; then
    echo Variable INSTALL_PATH is undefined.
    echo -e "set this variable or source your .profile file"
    source ../../.profile
    exit 1
fi

source $INSTALL_PATH/.profile

for SERVICE in $SERVICES; do
  echo ""
  echo -e "git status of ${GREEN} ${SERVICE} ${NC}"
  cd $INSTALL_PATH/microflack_${SERVICE}
  git status
done

echo ""
echo -e "git status of ${GREEN} easy-lb-haproxy ${NC}"
cd $INSTALL_PATH/easy-lb-haproxy
git status

echo ""
echo -e "git status of ${GREEN} admin ${NC}"
cd $INSTALL_PATH/microflack_admin
git status
