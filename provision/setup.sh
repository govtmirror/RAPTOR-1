#!/bin/bash -xi
# set up base box through vagrant file with these commands
cacheInstallerPath=/vagrant/provision/cache 
cacheInstaller=cache-2014.1.3.775.14809-lnxrhx64.tar.gz
parametersIsc=parameters.isc 
cacheDatabase=/VISTA.zip
cacheInstallTargetPath=/srv 
# configure selinux ###################
#
echo configuring ipv4 firewall
echo -----------------------
sudo service iptables stop
sudo cp /vagrant/provision/iptables /etc/sysconfig/
sudo service iptables start 

# install EPEL and REMI Repos ##################
#
echo installing epel-release and remi for CentOS/RHEL 6
echo --------------------------------------------------
sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
sudo rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm
# sed -i s'/enabled=1/enabled=0/' /etc/yum.repos.d/remi.repo
sudo cp /vagrant/provision/remi.repo /etc/yum.repos.d/

# Install Apache, PHP, and other tidbits ##############
#
echo installing apache, php, and other tidbits
sudo yum -y install parted vim zip unzip wget drush httpd php php-gd php-mcrypt php-curl
sudo chkconfig httpd on

# install Nodejs and Development Tools such as gcc & make
sudo yum -y groupinstall 'Development Tools'
sudo yum -y install nodejs npm
# sudo npm -g install bower

# copy php.ini from provision folder to prepare for Drupal 7
# 'expose_php' and 'allow_url_fopen' will be set to 'Off'
sudo cp /vagrant/provision/php.ini /etc/

# Change 'AllowOverride None' to 'All' in httpd.conf 
sudo cp /vagrant/provision/httpd.conf /etc/httpd/conf/
sudo service httpd start

#echo update repositories
#echo -------------------
#sudo yum update

# Install MySQL ######################
#
echo install mysql
echo -------------
cd
wget http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm
# note:
# maybe better to wget the rpm's instead and put them in /vagrant/provision to install
# that way they will be available for a quicker install upon subsequent builds...
sudo rpm -Uvh mysql-community-release-el6-5.noarch.rpm
sudo yum -y install dos2unix mysql mysql-server php-mysql php-soap php-mbstring php-dom php-xml rsync
sudo rpm -qa | grep mysql
sudo chkconfig mysqld on
sudo service mysqld start
export DATABASE_PASS='raptor1!'
mysqladmin -u root password "$DATABASE_PASS"
mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD('$DATABASE_PASS') WHERE User='root'"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"

# set up database for Drupal 7
mysql -u root -p"$DATABASE_PASS" -h localhost -e "create database raptor500;"
# add standard tables from a clean installation of Drupal 7
mysql -u root -p"$DATABASE_PASS" -h localhost raptor500 < /vagrant/provision/drupal.sql
# don't add RAPTOR specific tables ...they will be automatically created when
# drush installs the RAPTOR modules...
# mysql -u root -p"$DATABASE_PASS" -h localhost raptor500 < /vagrant/provision/raptor_tables.sql
# add RAPTOR database user and assign access
mysql -u root -p"$DATABASE_PASS" -h localhost -e "create user raptoruser@localhost identified by '$DATABASE_PASS';"
mysql -u root -p"$DATABASE_PASS" -h localhost -e "GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON raptor500.* TO raptoruser@localhost;"
mysql -u root -p"$DATABASE_PASS" -h localhost -e "FLUSH PRIVILEGES;"

# DRUPAL 7 ################################
#

# Install Drush ###########################

# Download latest stable release using the code below or browse to github.com/drush-ops/drush/releases.
cd
wget http://files.drush.org/drush.phar
# Or use our upcoming release: wget http://files.drush.org/drush-unstable.phar  

# Test your install.
php drush.phar core-status

# Rename to `drush` instead of `php drush.phar`. Destination can be anywhere on $PATH. 
sudo chmod +x drush.phar
sudo mv drush.phar /usr/local/bin/drush

# Enrich the bash startup file with completion and aliases.
/usr/local/bin/drush -y init

# Get Drupal 7 ###########################

wget http://ftp.drupal.org/files/projects/drupal-7.41.tar.gz
tar xzvf drupal*
cd drupal*
sudo mkdir /var/www/html/RSite500
sudo rsync -avz . /var/www/html/RSite500/
sudo mkdir /var/www/html/RSite500/sites/default/files

# RAPTOR Application #####################

# copy RAPTOR modules and themes to drupal installation
sudo cp -R /vagrant/modules/* /var/www/html/RSite500/sites/all/modules/
sudo cp -R /vagrant/themes/* /var/www/html/RSite500/sites/all/themes/

# create tmp folder 
sudo mkdir /var/www/html/RSite500/sites/default/files/tmp

# configure RSite500 to use raptor500 database
sudo cp /vagrant/provision/settings500.php /var/www/html/RSite500/sites/default/settings.php
sudo chmod 664 /var/www/html/RSite500/sites/default/settings.php

# set permissions so vagrant has access to write
#sudo chown vagrant -R /var/www/html/RSite500
sudo chown $USER -R /var/www/html/RSite500

# remove the $ from the end of this file which causes drush to fail
sudo sed -i '$ d' /root/.drush/drushrc.php

# enable RAPTOR Modules
cd /var/www/html/RSite500/sites/all/modules/
/usr/local/bin/drush -y en raptor_contraindications raptor_graph raptor_workflow raptor_datalayer raptor_imageviewing raptor_ewdvista raptor_mdwsvista simplerulesengine_core raptor_floatingdialog raptor_protocollib simplerulesengine_demo raptor_formulas raptor_reports simplerulesengine_ui raptor_glue raptor_scheduling

# automatically download the front-end libraries used by Omega
cd /var/www/html/RSite500/sites/all/themes/omega/omega
#sudo chown -R vagrant /var/www/html/RSite500/sites/all/themes/omega/omega
sudo chown -R $USER /var/www/html/RSite500/sites/all/themes/omega/omega
/usr/local/bin/drush -y make libraries.make --no-core --contrib-destination=.
sudo chmod a+rx /var/www/html/RSite500/sites/all/themes/omega/omega/libraries
sudo chown -R apache /var/www/html/RSite500/sites/all/themes/omega/omega

# enable and set raptor theme
cd /var/www/html/RSite500/sites/all/themes/
/usr/local/bin/drush -y -l http://localhost/RSite500/ pm-enable raptor_omega

# I'm sure ownership is borked from all the sudo commands...
sudo chown -R apache:apache /var/www

# restart apache so all php modules are loaded...
sudo service httpd restart

sudo groupadd cacheserver

# get cache installer
wget -P $cacheInstallerPath/ http://vaftl.us/vagrant/cache-2014.1.3.775.14809-lnxrhx64.tar.gz

if [ -e "$cacheInstallerPath/$cacheInstaller" ]
then
  echo "Installing Cache from: $cacheInstaller"
  # install from tar.gz 
  sudo mkdir -p $cacheInstallTargetPath/tmp
  cd $cacheInstallTargetPath/tmp
  sudo cp $cacheInstallerPath/$cacheInstaller .
  sudo tar -xzvf $cacheInstaller   

  # install from parameters file
  sudo $cacheInstallTargetPath/tmp/package/installFromParametersFile $cacheInstallerPath/parameters.isc

else
  echo "You are missing: $cacheInstaller"
  echo "You cannot provision this system until you have downloaded Intersystems Cache"
  echo "in 64-bit tar.gz format and placed it under the provision/cache folder."
  exit 
fi

# add vista and vagrant to cacheusr group
sudo usermod -a -G cacheusr $USER

## add disk to store CACHE.DAT was sdb 
#parted /dev/sdb mklabel msdos
#parted /dev/sdb mkpart primary 0 100%
#mkfs.xfs /dev/sdb1
#mkdir /srv
#echo `blkid /dev/sdb1 | awk '{print$2}' | sed -e 's/"//g'` /srv   xfs   noatime,nobarrier   0   0 >> /etc/fstab
#mount /srv

# check for cache.dat and put it where it goes
if [ -e "$cacheInstallerPath/VISTA/CACHE.DAT" ]
then
  echo "CACHE.DAT has already been unzipped..."
else
  if [ -e "$cacheInstallerPath/$cacheDatabase" ]
  then
    cd $cacheInstallerPath
    echo "Unzipping $cacheDatabase..."
    unzip $cacheDatabase
  else
    echo "$cacheDatabase is missing.  Downloading from FTL and place it under provision/cache folder..."
    # create path and get CACHE.DAT
    mkdir -p $cacheInstallerPath/VISTA 
    wget -P $cacheInstallerPath/VISTA/ http://vaftl.us/vagrant/CACHE.DAT 
  fi
fi

# stop cache before we move database 
#sudo chown -R vagrant:cacheusr /srv
sudo chown -R $USER:cacheusr /srv
sudo chmod g+wx /srv/bin

sudo ccontrol stop cache quietly
echo "Copying CACHE.DAT to /srv/mgr/"
echo "This will take a while... Get some coffee or a cup of tea..."
sudo mkdir -p $cacheInstallTargetPath/mgr/VISTA
sudo cp -R $cacheInstallerPath/VISTA/CACHE.DAT /srv/mgr/VISTA/
echo "Setting permissions on database."
sudo chmod 775 /srv/mgr/VISTA 
sudo chmod 660 /srv/mgr/VISTA/CACHE.DAT
#sudo chown -R vagrant:cacheusr /srv/mgr/VISTA 
sudo chown -R $USER:cacheusr /srv/mgr/VISTA 
# missing steps
echo "Copying cache.cpf"
sudo cp $cacheInstallerPath/cache.cpf $cacheInstallTargetPath/

# start cache 
# sudo /etc/init.d/cache start 
sudo ccontrol start cache

# enable cache' os authentication and %Service_CallIn required by EWD.js 
csession CACHE -U%SYS <<EOE
$USER
innovate
s rc=##class(Security.System).Get("SYSTEM",.SP),d=SP("AutheEnabled") f i=1:1:4 s d=d\2 i i=4 s r=+d#2
i 'r s NP("AutheEnabled")=SP("AutheEnabled")+16,rc=##class(Security.System).Modify("SYSTEM",.NP)

n p
s p("Enabled")=1
D ##class(Security.Services).Modify("%Service_CallIn",.p)

h
EOE

# install VEFB_1_2 ~RAPTOR Specific KIDS into VistA
cp /vagrant/OtherComponents/VistAConfig/VEFB_1_2.KID /srv/mgr/
csession CACHE -UVISTA "^ZU" <<EOI
vt320
^^load a distribution
/srv/mgr/VEFB_1_2.KID
yes
^^install package
VEFB 1.2
no
no

^
^
h
EOI

# EWD.js and Federator installation ############################
sudo mkdir /var/log/raptor 
sudo touch /var/log/raptor/federatorCPM.log
sudo touch /var/log/raptor/ewdjs.log
#sudo chown -R vagrant:vagrant /var/log/raptor
sudo chown -R $USER:$USER /var/log/raptor

cd /vagrant/OtherComponents/EWDJSvistalayer
sudo cp -R ewdjs /opt/
sudo chown -R $USER:$USER /opt/raptor 
cd /opt/ewdjs 
npm install ewdjs 
npm install ewd-federator
sudo npm install -g inherits@2.0.0
sudo npm install -g node-inspector

# get database interface from cache version we are running
sudo cp /srv/bin/cache0100.node /opt/ewdjs/node_modules/cache.node

# copy node_modules for ewd into RAPTOR Module space...
cd /opt/ewdjs/node_modules/ewdjs/essentials
sudo cp -R node_modules /var/www/html/RSite500/sites/all/modules/raptor_glue/core/
sudo chown -R apache:apache /var/www/html/RSite500/sites/all/modules/raptor_glue/core/node_modules/

# start EWD and EWD Federator
cd /opt/ewdjs

# add ewdfederator access to EWD
node registerEWDFederator.js

# start EWD and Federator 
sudo dos2unix startEverything.sh 
sudo chmod a+x startEverything.sh 
sudo ./startEverything.sh 

# /opt/ewdjs/node_modules/ewdjs/extras/OSEHRA 

# add ewd to vista
# cp /opt/ewdjs/zewd*.zip /srv/mgr/
# cd /opt/mgr 
# sudo unzip zewd*zip 
# csession cache
# zn "%sys"
# s ^zewd("config","routinePath","cache")="/srv/mgr/"
# D $SYSTEM.OBJ.Load("zewd.xml")
# check it: w $$version^%zewdAPI()
# wget  http://gradvs1.mgateway.com/download/ewdMgr.zip
#

# user notifications 
echo VistA is now installed.  

echo CSP is here: http://192.168.33.11:57772/csp/sys/UtilHome.csp
echo username: cache password: innovate 
echo See Readme.md from root level of this repository... 
echo EWD Monitor: http://192.168.33.11:8082/ewd/ewdMonitor/ password: innovate 
echo EWD: http://192.168.33.11:8082/ewdjs/EWD.js ewdBootstrap3.js 
echo EWD Federator: http://192.168.33.11:8081/RaptorEwdVista/raptor/
echo password: innovate 
echo RAPTOR is now installed to a test instance for site 500
echo Browse to: http://192.168.33.11/RSite500/ after completing steps 1-3...
echo to kill EWD and Federator sudo sh /opt/ewdjs/killEverything.sh 