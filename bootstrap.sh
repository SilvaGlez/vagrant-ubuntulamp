!/usr/bin/env bash

PASSWORD='vagrant'
IP_ADDRESS=$1
SITE_NAME=$2
DATABASE_NAME=$3
MYSQL_PASSWORD=$4
PHPMYADMIN_PASSWORD=$5

echo -e "\n--- Aggiorna l'indice dei pacchetti ---\n"
sudo apt-get update

echo -e "\n--- Installa Apache ---\n"
sudo apt-get install -y apache2

echo -e "\n--- Installa PHP 7.1 ---\n"
sudo apt-get install -y software-properties-common
sudo apt-get install -y language-pack-en-base
sudo LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt install -y php7.1 libapache2-mod-php7.1 php7.1-common php7.1-mbstring php7.1-xmlrpc php7.1-soap php7.1-gd php7.1-xml php7.1-intl php7.1-mysql php7.1-cli php7.1-mcrypt php7.1-zip php7.1-curl

echo -e "\n--- Installa MySQL ---\n"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD"
sudo apt-get -y install mysql-server

echo -e "\n--- Installa phpMyAdmin ---\n"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PHPMYADMIN_PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin

# echo -e "\n--- Crea Virtual Host ---\n"
# VHOST=$(cat <<EOF
# <VirtualHost *:80>
#     ServerName local.dev
#     ServerAlias www.local.dev
#     DocumentRoot /var/www/html
#     <Directory /var/www/html>
#         Options Indexes FollowSymLinks MultiViews
#         AllowOverride All
#         Require all granted
#     </Directory>
# </VirtualHost>
# EOF
# )

echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

echo -e "\n--- Crea index.php ---\n"
sudo rm /var/www/html/index.html
sudo touch /var/www/html/index.php
echo "<?php phpinfo(); ?>" > /var/www/html/index.php

echo -e "\n--- Attiva mod_rewrite ---\n"
sudo a2enmod rewrite

echo -e "\n--- Restart Apache ---\n"
sudo service apache2 restart

echo -e "\n--- Ferma MySQL ---\n"
sudo /etc/init.d/mysql stop

echo -e "\n--- Installa GIT ---\n"
sudo apt-get -y install git

echo -e "\n--- Installa Composer ---\n"
curl -s https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# if [ $MYSQL_PASSWORD != 'password' ];
# then
#     echo "Updating MySQL root password..."
#     mysql -uroot -ppassword -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_PASSWORD'); FLUSH PRIVILEGES;"
# fi

echo "Creating database, if it doesn't already exist..."
mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;"

PHP_INFO_FILE="/var/www/public/info.php"
if [ ! -f "$PHP_INFO_FILE" ]
then
    echo "Creating phpinfo file..."
    echo '<?php echo phpinfo(); ?>' > /var/www/public/info.php
fi

echo "Updating Apache ServerName..."
echo "ServerName $SITE_NAME" | sudo tee /etc/apache2/conf-available/servername.conf

echo "Setting xdebug IP address in PHP ini..."
echo "xdebug.remote_host=$IP_ADDRESS" | sudo tee -a /etc/php/7.0/apache2/conf.d/user.ini

## Fixing errors in php-gettext
## Remove this once the Ubuntu package gets updated
# echo "Fixing deprecation errors in php-gettext"
# sudo sed -i 's/function StringReader/function __construct/g' /usr/share/php/php-gettext/streams.php
# sudo sed -i "s/function FileReader/function __construct/g" /usr/share/php/php-gettext/streams.php
# sudo sed -i "s/function CachedFileReader/function __construct/g" /usr/share/php/php-gettext/streams.php
# sudo sed -i 's/function gettext_reader/function __construct/g' /usr/share/php/php-gettext/gettext.php

echo "Restarting web server..."
sudo service apache2 restart

echo "Setup complete."
