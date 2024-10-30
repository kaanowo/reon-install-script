#!/usr/bin/bash

if [ "$(id -u)" -ne "0" ]; then
   echo "This script must be run as sudo!";
   exit 1;
fi


set -eo pipefail


echo "Managing files..."


mkdir -p /var/www/
cd /var/www/
git clone https://github.com/REONTeam/reon.git web
cd web/
mv /var/www/web/web/* .
rmdir web
rm -rf app/crystal-trade-corner


echo "Setting permissions for www-data..."


sudo chown -R www-data /var/www
sudo find /var/www -type d -exec chmod 2750 {} \+
sudo find /var/www -type f -exec chmod 640 {} \+


#echo "Installing comoposer locally for /var/www/web/..."


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

echo "Restarting apache..."
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


echo "MariaDB set up."



