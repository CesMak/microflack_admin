#!/bin/bash -e

# source .profile
# Description here:  ./startDEVService users|messages

RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'



LOCALBUILDSERVICE=$1 # ui messages socketio tokens users
PORT=$2

if [[ "$PORT" == "" ]]; then
    PORT=5000
fi

cd ../bin
#./mfkill $LOCALBUILDSERVICE

cd $INSTALL_PATH/microflack_$LOCALBUILDSERVICE

. env/bin/activate

echo ''
echo -e "${BLUE}Do now mfdev start $LOCALBUILDSERVICE ${NC}"
../microflack_admin/bin/mfdev start $LOCALBUILDSERVICE $PORT

echo ''
echo -e "${BLUE}Delete your local db (in case of column changes adding roomid)${NC}"
rm -rf migrations
rm $LOCALBUILDSERVICE.sqlite
flask db init
flask db migrate -m "initial migration"
flask db upgrade

echo ''
echo ''
echo -e "${GREEN}Start flask app: flask run${NC}"
flask run --host 0.0.0.0 -p $PORT
