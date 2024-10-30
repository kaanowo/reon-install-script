#!/usr/bin/bash

if [ "$(id -u)" -ne "0" ]; then
   echo "This script must be run as sudo!";
   exit 1;
fi

set -eo pipefail

#creating variables for names the user wants

# logfile path
logfile=$(pwd)/server-install_$(date -Iseconds).log

# my_db_name="USER INPUT"
read -p "Enter database name: " my_db_name

# my_db_user="USER INPUT"
read -p "Enter database username: " my_db_user

# my_db_password="USER INPUT"
read -p "Enter database user-password: " my_db_password

# subdomain="USER INPUT"
read -p "Enter your preferred subdomain (USE EXACTLY 4 LETTERS): " subdomain

. ./installpackages.sh 2>&1 | tee -a $logfile
. ./installservices.sh 2>&1 | tee -a $logfile
. ./addingcronjobs.sh 2>&1 | tee -a $logfile
. ./mailservice.sh 2>&1 | tee -a $logfile
. ./newsscript.sh 2>&1 | tee -a $logfile

systemctl start reonmail.service

echo "Your Server is now installed."
