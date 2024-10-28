#!/usr/bin/bash

if [ "$(id -u)" -ne "0" ]; then
   echo "This script must be run as sudo!";
   exit 1;
fi

set -eo pipefail

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


echo "Pokemon-Exchange and Battle-Services have been setup!"
