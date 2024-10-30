#!/usr/bin/bash

if [ "$(id -u)" -ne "0" ]; then
   echo "This script must be run as sudo!";
   exit 1;
fi

set -eo pipefail


echo "Installing needed packages..."


apt-get --yes update 2>&1 | tee -a $logfile
apt-get --yes install apache2 php php-mysqli mariadb-server unzip make bison libpng-dev pkg-config nodejs npm python-is-python3 python3-pymysql php-twig 2>&1 | tee -a $logfile

echo "Packages installed!"
