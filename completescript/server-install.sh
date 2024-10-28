#!/usr/bin/bash

if [ "$(id -u)" -ne "0" ]; then
   echo "This script must be run as sudo!";
   exit 1;
fi

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


echo "Installing needed packages..."


apt-get --yes update &>>$logfile
apt-get --yes install apache2 php php-mysqli mariadb-server unzip make bison libpng-dev pkg-config nodejs npm python-is-python3 &>>$logfile


echo "Managing files..."


mkdir -p /var/www/
cd /var/www/
git clone https://github.com/REONTeam/reon.git web
cd web/
mv /var/www/web/web/* .
rmdir web
rm -rf app/crystal-trade-corner


#permissions for www-data
sudo chown -R www-data /var/www
sudo find /var/www -type d -exec chmod 2750 {} \+
sudo find /var/www -type f -exec chmod 640 {} \+


echo "Installing comoposer locally for /var/www/web/..."


sudo -u www-data php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo -u www-data php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo -u www-data php composer-setup.php
sudo -u www-data php -r "unlink('composer-setup.php');"

#using composer
sudo -u www-data php composer.phar install
sudo -u www-data php composer.phar update

echo "<VirtualHost *:80>
ServerName gameboy.datacenter.ne.jp
ServerAlias mgb.dion.ne.jp

DocumentRoot /var/www/web/htdocs/

<Directory /var/www/web/htdocs/>
  Options Indexes FollowSymLinks
  AllowOverride All
  Require all granted
</Directory>

</VirtualHost>" > /etc/apache2/sites-enabled/000-default.conf

#services
a2enmod rewrite
systemctl restart apache2


echo "Setting up the database..."


cp /var/www/web/tables.sql /var/www/web/tablesbak.sql
echo -n "CREATE SCHEMA if NOT EXISTS " > /var/www/web/tables.sql
echo -n '`' >> /var/www/web/tables.sql
echo -n "$my_db_name" >> /var/www/web/tables.sql
echo -n '`' >> /var/www/web/tables.sql
echo ";" >> /var/www/web/tables.sql
echo -n "USE " >> /var/www/web/tables.sql
echo -n '`' >> /var/www/web/tables.sql
echo -n "$my_db_name" >> /var/www/web/tables.sql
echo -n '`' >> /var/www/web/tables.sql
echo ";" >> /var/www/web/tables.sql
cat /var/www/web/tablesbak.sql |tail -n+3 >> /var/www/web/tables.sql
rm /var/www/web/tablesbak.sql


echo "Creating a new MariaDB user for the database..."


cat > /var/www/web/createmariadbuser.sql <<EOF
CREATE DATABASE $my_db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$my_db_user'@'%' IDENTIFIED VIA mysql_native_password USING PASSWORD ('$my_db_password');
GRANT ALL ON $my_db_name.* TO '$my_db_user'@'%';
FLUSH PRIVILEGES;
EOF

echo "source /var/www/web/createmariadbuser.sql" |mariadb


echo "Creating the database..."
echo "[INFO] To use MariaDB as $my_db_user, use: mariadb -u $my_db_user -uyourpassword"


echo "source /var/www/web/tables.sql;" |mariadb


echo "Configuring the mail-server..."


cd /var/www/
cat > /var/www/config.json <<EOF
{
        "hostname": "localhost",
        "email_domain": "mail.example.net",
        "email_domain_dion": "$subdomain.dion.ne.jp",
        "mysql_host": "127.0.0.1",
        "mysql_user": "$my_db_user",
        "mysql_password": "$my_db_password",
        "mysql_database": "$my_db_name",
        "amoj_regist": "h200"
}
EOF

cd /var/www/web/
ln -s ../config.json .
cd mail
sudo -u www-data npm install
sudo -u www-data npm update
sudo -u www-data npm audit

echo "Setting up the Mail-Service..."



echo "Setting up the pokemon-exchange..."


cd /var/www/web/app/pokemon-exchange
sudo -u www-data npm install
sudo -u www-data npm update
sudo -u www-data npm audit


echo "Creating the script for pokemon-exchange-cronjob..."


echo "#!/usr/bin/bash
cd /var/www/web/app/pokemon-exchange/
sudo -u root npm run start" > /var/www/web/app/pokemon-exchange/exchange.sh

chmod +x /var/www/web/app/pokemon-exchange/exchange.sh


echo "*/10 * * * * root /var/www/web/app/pokemon-exchange/exchange.sh >> /var/www/web/app/pokemon-exchange/exchange.log 2>&1" >> exchangejob
mv /var/www/web/app/pokemon-exchange/exchangejob /etc/cron.d

echo "Setting up the battle-tower script..."


cd /var/www/web/app/pokemon-battle
sudo -u www-data npm install
sudo -u www-data npm update
sudo -u www-data npm audit


echo "Creating the script for pokemon-battle-cronjob..."


echo "#!/usr/bin/bash
cd /var/www/web/app/pokemon-battle/
sudo -u root npm run start" > /var/www/web/app/pokemon-battle/battle.sh

chmod +x /var/www/web/app/pokemon-battle/battle.sh

echo "*/10 * * * * root /var/www/web/app/pokemon-battle/battle.sh >> /var/www/web/app/pokemon-battle/battle.log 2>&1" >> battlejob
mv /var/www/web/app/pokemon-battle/battlejob /etc/cron.d

echo "Setting up the news-machine..."
echo "Building news for all languages..."


mkdir /tmp/reon_news/
cd /tmp/reon_news/
git clone https://github.com/gb-mobile/pokecrystal-news-en
cd pokecrystal-news-en/
wget https://github.com/gbdev/rgbds/releases/download/v0.6.0/rgbds-0.6.0.tar.gz
tar xvf rgbds-0.6.0.tar.gz &>>$logfile
cd rgbds/
make install PREFIX=../ &>>$logfile
cd ..
make RGBDS=./bin/ news all &>>$logfile
#mv news news_en news_de news_es news_fr news_it ../


echo "Adding news to the database..."


cd /tmp/reon_news/
mv pokecrystal-news-en/first_issue* .
cat > /tmp/reon_news/add_news.sql <<EOF
use $my_db_name;
DELETE FROM $my_db_name.bxt_news;
INSERT INTO $my_db_name.bxt_news (ranking_category_1,ranking_category_2,ranking_category_3,
message_j,message_e,message_d,message_f,message_i,message_s,
news_binary_j,news_binary_e,news_binary_d,news_binary_f,news_binary_i,news_binary_s) VALUES
(5,39,41,
    UNHEX('E8E8E8E8E8E8'),
    UNHEX('93A7A8B27FA8B27FA07FB3A4B2B3E8'),
    UNHEX('93A7A8B27FA8B27FA07FB3A4B2B3E8'),
    UNHEX('93A7A8B27FA8B27FA07FB3A4B2B3E8'),
    UNHEX('93A7A8B27FA8B27FA07FB3A4B2B3E8'),
    UNHEX('93A7A8B27FA8B27FA07FB3A4B2B3E8'),
    LOAD_FILE('/tmp/reon_news/first_issue.bin'),
    LOAD_FILE('/tmp/reon_news/first_issue_en.bin'),
    LOAD_FILE('/tmp/reon_news/first_issue_de.bin'),
    LOAD_FILE('/tmp/reon_news/first_issue_fr.bin'),
    LOAD_FILE('/tmp/reon_news/first_issue_it.bin'),
    LOAD_FILE('/tmp/reon_news/first_issue_es.bin'));
EOF

echo 'source /tmp/reon_news/add_news.sql' |mariadb


echo "Done! Please use createuser.sh to create a user for your server! To install the mobile-relay-server to use the phone functions, please use mobile-relay server files! Now start the Mail Server in /var/www/web/mail/ with npm run start"














