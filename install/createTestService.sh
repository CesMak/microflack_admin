#!/bin/bash -e


LOCALBUILDSERVICE=$1 # ui common messages socketio tokens users

# Description here:
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'

export INSTALL_PATH=$PWD/../..

pushd $INSTALL_PATH/
export PATH=$PATH:$PWD/microflack_admin/bin
cd microflack_admin
source mfvars

echo ''
echo -e "${GREEN}Clone all${NC}"
mfclone ..

echo ''
echo -e "${GREEN}Make all wheels of common${NC}"
cd $INSTALL_PATH/microflack_common
./mkwheel all

echo ''
echo -e "${GREEN}Your wheels${NC}"
cd $WHEELHOUSE
ls


echo ''
echo -e "${GREEN}Build your $LOCALBUILDSERVICE locally: ${NC}"
cd $INSTALL_PATH/microflack_$LOCALBUILDSERVICE
# check if folder env exists
if [[ -d $INSTALL_PATH/microflack_$LOCALBUILDSERVICE/env ]]; then
  echo -e "${BLUE}Your env already exists...${NC}"
else
  echo -e "${BLUE}Create env ${NC}"
  python3 -m venv env
fi
. env/bin/activate

echo ''
echo -e "${GREEN}Install requirements: ${NC}"
pip install --upgrade pip wheel
pip install -r requirements.txt
flask run # in case of app not found do setup-all-in-one.sh first
          # in case of .env file not found do ....?
