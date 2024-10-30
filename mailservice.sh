#!/usr/bin/bash

if [ "$(id -u)" -ne "0" ]; then
   echo "This script must be run as sudo!";
   exit 1;
fi

set -eo pipefail


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


cat > /etc/systemd/system/reonmail.service <<EOF
[Unit]
Description=Mobile-Adapter-GB Mail-Server
After=network.target


[Service]
ExecStart=/usr/bin/npm --prefix /var/www/web/mail/ run start
Type=main
Restart=always


[Install]
WantedBy=default.target
RequiredBy=network.target
EOF

echo "Mail-Service has been set up."
