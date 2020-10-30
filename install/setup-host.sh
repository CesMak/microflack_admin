#!/bin/bash -e

# This script installs all the requireed dependencies on a host

# install system dependencies
apt-get update -y
apt-get install -y python3 python3-pip python3-venv build-essential pwgen mysql-client
pip3 install --upgrade pip wheel

# install docker before give it the rights to run without sudo
