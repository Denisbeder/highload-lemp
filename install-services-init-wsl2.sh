#!/usr/bin/env bash

#COLORS
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

service_start_php='\n## Start PHP if is stopped
status=`service php7.4-fpm status`
if [[ $status == *"php-fpm7.4 is not running" ]]
then
sudo service php7.4-fpm start
fi'
service_logout_php='\n## Stop PHP if is running
status=`service php7.4-fpm status`
if [[ $status == *"php-fpm7.4 is running" ]]
then
sudo service php7.4-fpm stop
fi'

####################################################

service_start_nginx='\n## Start NGINX if is stopped\n
status=`service nginx status`\n
if [[ $status == *"nginx is not running" ]]\n
then\n
sudo service nginx start\n
fi'
service_logout_nginx='\n## Stop NGINX if is running
status=`service nginx status`
if [[ $status == *"nginx is running" ]]
then
sudo service nginx stop
fi'

####################################################

service_start_mysql='\n## Start MySQL if is stopped\n
status=`service mysql status`\n
if [[ $status == *"MariaDB is stopped." ]]\n
then\n
sudo service mysql start\n
fi'
service_logout_mysql='\n## Stop MYSQL if is running
status=`service mysql status`
if [[ $status != *"MariaDB is stopped." ]]
then
sudo service nginx stop
fi'

####################################################

service_start_redis='\n## Start REDIS if is stopped\n
status=`service redis-server status`\n
if [[ $status == *"redis-server is not running" ]]\n
then\n
sudo service redis-server start\n
fi'
service_logout_redis='\n## Stop REDIS if is running
status=`service redis-server status`
if [[ $status == *"redis-server is running" ]]
then
sudo service redis-server stop
fi'

####################################################

service_start_memcached='\n## Start MEMCACHED if is stopped\n
status=`service memcached status`\n
if [[ $status == "memcached: memcached is not running" ]]\n
then\n
sudo service memcached start\n
fi'
service_logout_memcached='\n## Stop MEMCACHED if is running
status=`service memcached status`
if [[ $status != "memcached: memcached is not running" ]]
then
sudo service memcached stop
fi'

####################################################

service_start_monit='\n## Start MONIT if is stopped\n
status=`service monit status`\n
if [[ $status == *"monit is not running" ]]\n
then\n
sudo service monit start\n
fi'
service_logout_monit='\n## Stop MONIT if is running
status=`service monit status`
if [[ $status == *"monit is running" ]]
then
sudo service monit stop
fi'

####################################################

echo -e "${CYAN}Add servide PHP to ~/.bash${NC}"
echo -e $service_start_php >> ~/.bash
echo -e $service_logout_php >> ~/.bash_logout

echo -e "${CYAN}Add servide NGINX to ~/.bash${NC}"
echo -e $service_start_nginx >> ~/.bash
echo -e $service_logout_nginx >> ~/.bash_logout

echo -e "${CYAN}Add servide MYSQL to ~/.bash${NC}"
echo -e $service_start_mysql >> ~/.bash
echo -e $service_logout_mysql >> ~/.bash_logout

echo -e "${CYAN}Add servide REDIS to ~/.bash${NC}"
echo -e $service_start_redis >> ~/.bash
echo -e $service_logout_redis >> ~/.bash_logout

echo -e "${CYAN}Add servide MEMCACHED to ~/.bash${NC}"
echo -e $service_start_memcached >> ~/.bash
echo -e $service_logout_memcached >> ~/.bash_logout

echo -e "${CYAN}Add servide MONIT to ~/.bash${NC}"
echo -e $service_start_monit >> ~/.bash
echo -e $service_logout_monit >> ~/.bash_logout