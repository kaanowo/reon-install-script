#!/usr/bin/bash

if [ "$(id -u)" -ne "0" ]; then
   echo "This script must be run as sudo!";
   exit 1;
fi

set -eo pipefail


echo "Building news for the news-machine."


cd /var/www/

git clone https://github.com/kabili207/pokecrystal-news-en

cp config.json /var/www/pokecrystal-news-en/

cd pokecrystal-news-en

wget https://github.com/gbdev/rgbds/releases/download/v0.6.0/rgbds-0.6.0.tar.gz

tar xvf rgbds-0.6.0.tar.gz &>>$logfile

cd rgbds/

make install PREFIX=../ &>>$logfile

cd ..

make RGBDS=./bin/ news all &>>$logfile

./deploy.py

echo "News have been added to the database."
