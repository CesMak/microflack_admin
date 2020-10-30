#!/bin/bash -e
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
BLUE='\033[0;34m'

export INSTALL_PATH=$PWD/../..

pushd $INSTALL_PATH/
export PATH=$PATH:$PWD/microflack_admin/bin
cd microflack_admin
source mfvars
mfenv
