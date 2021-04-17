#!/usr/bin/env bash
#
# Follow up commands are best suitable for clean Ubuntu 16.04 installation
# All commands are executed by the root user
# Nginx library is installed from custom ppa/ repository
# https://launchpad.net/~hda-me/+archive/ubuntu/nginx-stable
# This will not be available for any other OS rather then Ubuntu

#COLORS
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
# Disable user promt
DEBIAN_FRONTEND=noninteractive
echo -e "${CYAN}Update list of available packages${NC}"
# Update list of available packages
apt-get update -y -q
echo -e "${CYAN}Install language pack PT and Set Timezone${NC}"
# Install language pack PT
apt-get install language-pack-pt-base -y -q
# Set new language (needs restart)
update-locale LANG=pt_BR.UTF-8
# Change timezone na primeira linha e após a primeira linha deleta tudo
sed -e '1i America/Campo_Grande' -e '1,$d' /etc/timezone

echo -e "${CYAN}Update installed packages${NC}"
# Update installed packages
apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" dist-upgrade

echo -e "${CYAN}Install the most common packages${NC}"
# Install the most common packages that will be usefull under development environment
apt-get install zip unzip htop nano expect software-properties-common -y -q

echo -e "${CYAN}Install MariaDB${NC}"
# Use md5 hash of your hostname to define a root password for MariDB
#db_root_password=$(hostname | md5sum | awk '{print $1}')
db_root_password=root
debconf-set-selections <<< "mariadb-server-10.5 mysql-server/root_password password $db_root_password"
debconf-set-selections <<< "mariadb-server-10.5 mysql-server/root_password_again password $db_root_password"
# Install MariaDB package
apt-get install mariadb-server -y -q

echo -e "${CYAN}Install MariaDB and configure mysql_secure_installation${NC}"
# Secure Configuration Maria DB

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect {Set root password? [Y/n] }
send \"y\r\"
expect {New password: }
send \"$db_root_password\r\"
expect {Re-enter new password:}
send \"$db_root_password\r\"
expect {Remove anonymous users? [Y/n] }
send \"y\r\"
expect {Disallow root login remotely? [Y/n] }
send \"y\r\"
expect {Remove test database and access to it? [Y/n] }
send \"y\r\"
expect {Reload privilege tables now? [Y/n] }
send \"y\r\"
expect eof
")

echo $SECURE_MYSQL


echo -e "${CYAN}Custom Configuration MYSQL${NC}"
# Add custom configuration for your Mysql
# All modified variables are available at https://mariadb.com/kb/en/library/server-system-variables/
echo -e "\n[mysqld]\nmax_connections=24\nconnect_timeout=10\nwait_timeout=10\nthread_cache_size=24\nsort_buffer_size=1M\njoin_buffer_size=1M\ntmp_table_size=8M\nmax_heap_table_size=8M\nbinlog_cache_size=8M\nperformance_schema=ON\nbinlog_stmt_cache_size=8M\nkey_buffer_size=1M\ntable_open_cache=64\nread_buffer_size=1M\nquery_cache_limit=1M\nquery_cache_type=OFF\nquery_cache_size=0\ninnodb_buffer_pool_size=8M\ninnodb_open_files=1024\ninnodb_io_capacity=1024\ninnodb_buffer_pool_instances=1\ndefault-storage-engine=InnoDB\nskip-name-resolve" >> /etc/mysql/my.cnf
# Write down current password for MariaDB in my.cnf
echo -e "\n[client]\nuser = root\npassword = $db_root_password" >> /etc/mysql/my.cnf

echo -e "${CYAN}Restart MariaDB${NC}"
# Restart MariaDB
service mysql restart

echo -e "${CYAN}Install Mysqltuner for future improvements of MariaDB installation${NC}"
# Install Mysqltuner for future improvements of MariaDB installation
apt-get install mysqltuner -y -q

echo -e "${GREEN}All installed. Now restart server.${NC}"