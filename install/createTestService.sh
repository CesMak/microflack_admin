#!/bin/bash -e

# Description here:  ./createTestService.sh messages -u -env

RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'


LOCALBUILDSERVICE=$1 # ui messages socketio tokens users
DOUPGRADE=$2
USEENV=$3

if [[ "$LOCALBUILDSERVICE" == "" ]]; then
    echo "Usage: createTestService <service-name e.g. ui, messages, socketio, tokens, users> <-u> <-env>"
    exit 1
fi

if [[ "$DOUPGRADE" == "" ]]; then
    echo "Do not upgrade requirements to newest version to upgrade use"
    echo "Usage: createTestService $1 -u"
    echo ""
fi

if [[ "$USEENV" == "" ]]; then
    echo "Using env file = .profile is not used!"
    echo "Usage: createTestService $1 $2 -env"
    echo ""
fi


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
echo -e "${GREEN}Build your $LOCALBUILDSERVICE SERVICE locally: ${NC}"
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
if [[ "$DOUPGRADE" == "-u" ]]; then
  echo -e "${BLUE}UPGRADE requiremnts.txt to newest versions: ${NC}"
  pip install pip-upgrader
  pip-upgrade
  pip install -r requirements.txt
else
  pip install -r requirements.txt
fi

if [[ "$USEENV" == "-env" ]]; then
  echo ''
  echo -e "${BLUE}Your variables: ${NC}"
  source $INSTALL_PATH/.profile # then all keys etc are available
  rm -f .env
  mfenv >> .env
  cat .env
fi

cd $INSTALL_PATH/microflack_$LOCALBUILDSERVICE
echo ''
echo -e "${BLUE}Do now mfdev start $LOCALBUILDSERVICE ${NC}"
../microflack_admin/bin/mfdev start $LOCALBUILDSERVICE

echo ''
echo ''
echo -e "${GREEN}Start flask app: flask run${NC}"
export FLASK_DEBUG=1
flask run --host 0.0.0.0
