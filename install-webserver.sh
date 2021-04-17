#!/usr/bin/bash
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
apt-get install zip unzip fail2ban htop sqlite3 nload nano memcached redis-server software-properties-common -y -q
echo -e "${CYAN}Install Nginx && PHP-FPM stack${NC}"
# Adicione o pacote ondrej/php que possui o PHP 7.4 e outras extensões PHP necessárias.
add-apt-repository ppa:ondrej/php -y
# baixa as listas de pacotes dos repositórios e as "atualiza" para obter informações sobre as versões mais recentes dos pacotes e suas dependências. Isso será feito para todos os repositórios e PPAs.
apt update
# Install Nginx && PHP-FPM stack
apt-get install php7.4-curl php7.4-fpm php7.4-gd php7.4-mbstring php7.4-mcrypt php7.4-opcache php7.4-xml php7.4-sqlite php7.4-mysql php7.4-fileinfo php7.4-bcmath php7.4-imagick php7.4-zip php7.4-common -y -q
# Delete previous Nginx installation
apt-get purge nginx-core nginx-common nginx -y -q
apt-get autoremove -y -q
# Add custom repository for Nginx
add-apt-repository ppa:hda-me/nginx-stable -y
# Update list of available packages
apt-get update -y -q
# Install custom Nginx package
apt-get install nginx -y -q
echo -e "${CYAN}Backup cinfiguration NGINX, PHP, REDIS${NC}"
# Create a folder to backup current installation of Nginx && PHP-FPM
now=$(date +"%Y-%m-%d_%H-%M-%S") 
mkdir /backup/
mkdir -p /backup/$now/nginx/ && mkdir -p /backup/$now/php/ && mkdir -p /backup/$now/redis/
# Create a full backup of previous Nginx configuration
cp -r /etc/nginx/ /backup/$now/nginx/ 
# Create a full backup of previous PHP configuration
cp -r /etc/php/ /backup/$now/php/
# Create a full backup of previous REDIS configuration
cp -r /etc/redis/ /backup/$now/redis/
echo -e "${CYAN}Configure REDIS${NC}"
# This directive allows you to declare an init system to manage Redis as a service, giving you more control over an operation of your operation
sed -i "s/^supervised no/supervised systemd/" /etc/redis/redis.conf


echo -e "${CYAN}Configure NGINX${NC}"
# Download list of bad bots, bad ip's and bad referres
# https://github.com/mitchellkrogza/nginx-badbot-blocker
wget -O /etc/nginx/conf.d/blacklist.conf https://raw.githubusercontent.com/denisbeder/highload-lemp/master/blacklist.conf
wget -O /etc/nginx/conf.d/blockips.conf https://raw.githubusercontent.com/denisbeder/highload-lemp/master/blockips.conf
# Create default file for Nginx for where to find new websites that are pointed to this IP
wget -O /etc/nginx/sites-enabled/default.conf https://raw.githubusercontent.com/denisbeder/highload-lemp/master/default.conf
# Create fastcgi.conf
echo -e 'fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;\nfastcgi_param  QUERY_STRING       $query_string;\nfastcgi_param  REQUEST_METHOD     $request_method;\nfastcgi_param  CONTENT_TYPE       $content_type;\nfastcgi_param  CONTENT_LENGTH     $content_length;\n\nfastcgi_param  SCRIPT_NAME        $fastcgi_script_name;\nfastcgi_param  REQUEST_URI        $request_uri;\nfastcgi_param  DOCUMENT_URI       $document_uri;\nfastcgi_param  DOCUMENT_ROOT      $document_root;\nfastcgi_param  SERVER_PROTOCOL    $server_protocol;\nfastcgi_param  HTTPS              $https if_not_empty;\n\nfastcgi_param  GATEWAY_INTERFACE  CGI/1.1;\nfastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;\n\nfastcgi_param  REMOTE_ADDR        $remote_addr;\nfastcgi_param  REMOTE_PORT        $remote_port;\nfastcgi_param  SERVER_ADDR        $server_addr;\nfastcgi_param  SERVER_PORT        $server_port;\nfastcgi_param  SERVER_NAME        $server_name;\n\n# PHP only, required if PHP was built with --enable-force-cgi-redirect\nfastcgi_param  REDIRECT_STATUS    200;' > /etc/nginx/fastcgi.conf
# Create fastcgi-php.conf
echo -e '# regex to split $uri to $fastcgi_script_name and $fastcgi_path\nfastcgi_split_path_info ^(.+\.php)(/.+)$;\n\n# Check that the PHP script exists before passing it\ntry_files $fastcgi_script_name =404;\n\n# Bypass the fact that try_files resets $fastcgi_path_info\n# see: http://trac.nginx.org/nginx/ticket/321\nset $path_info $fastcgi_path_info;\nfastcgi_param PATH_INFO $path_info;\n\nfastcgi_index index.php;\ninclude fastcgi.conf;' > /etc/nginx/fastcgi-php.conf
# Create nginx.conf
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/denisbeder/highload-lemp/master/nginx.conf

echo -e "${CYAN}Configure MEMCACHED${NC}"
# Tweak memcached configuration
# Disable memcached vulnerability https://thehackernews.com/2018/03/memcached-ddos-exploit-code.html
sed -i "s/^-p 11211/#-p 11211/" /etc/memcached.conf
sed -i "s/^-l 127.4.0.1/#-l 127.4.0.1/" /etc/memcached.conf
# Increase memcached performance by using sockets https://guides.wp-bullet.com/configure-memcached-to-use-unix-socket-speed-boost/
echo -e "-s /tmp/memcached.sock" >> /etc/memcached.conf
echo -e "-a 775" >> /etc/memcached.conf

# Create Hello World page
mkdir /var/www/test.com
echo -e "<html>\n<body>\n<h1>Hello World\!<h1>\n</body>\n</html>" > /var/www/test.com/index.html
# Create opcache page
wget -O /var/www/test.com/opcache.php https://github.com/rlerdorf/opcache-status/blob/master/opcache.php
# Create phpinfo page
echo -e "<?php phpinfo();" > /var/www/test.com/info.php
# Give Nginx permissions to be able to access these websites
chown -R www-data:www-data /var/www/*
echo -e "${CYAN}Configure PHP${NC}"
# Disable external access to PHP-FPM scripts
sed -i "s/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.4/fpm/php.ini
# Maximize the limits of file system usage
echo -e "*       soft    nofile  1000000" >> /etc/security/limits.conf
echo -e "*       hard    nofile  1000000" >> /etc/security/limits.conf
# Switch to the ondemand state of PHP-FPM
sed -i "s/^pm = .*/pm = ondemand/" /etc/php/7.4/fpm/pool.d/www.conf
# Use such number of children that will not hurt other parts of the system
# Let's assume that system itself needs 128 MB of RAM
# Let's assume that we let have MariaDB another 256 MB to run
# And finally let's assume that Nginx will need something like 8 MB to run
# On the 1 GB system that leads up to 632 MB of free memory
# If we give one PHP-FPM child a moderate amount of RAM for example 32 MB that will let us create 19 PHP-FPM proccesses at max
# Check median of how much PHP-FPM child consumes with the following command
# ps --no-headers -o "rss,cmd" -C php-fpm7.0 | awk '{ sum+=$1 } END { printf ("%d%s\n", sum/NR/1024,"M") }'
ram=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
free=$(((ram/1024)-128-256-8))
php=$(((free/32)))
children=$(printf %.0f $php)
sed -i "s/^pm.max_children = .*/pm.max_children = $children/" /etc/php/7.4/fpm/pool.d/www.conf
# Comment default dynamic mode settings and make them more adequate
sed -i "s/^pm.start_servers = .*/;pm.start_servers = 5/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/^pm.min_spare_servers = .*/;pm.min_spare_servers = 2/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/^pm.max_spare_servers = .*/;pm.max_spare_servers = 2/" /etc/php/7.4/fpm/pool.d/www.conf
# State what amount of request one PHP-FPM child can sustain
sed -i "s/^;pm.max_requests = .*/pm.max_requests = 400/" /etc/php/7.4/fpm/pool.d/www.conf
# State after what amount of time unused PHP-FPM children will stop
sed -i "s/^;pm.process_idle_timeout = .*/pm.process_idle_timeout = 10s;/" /etc/php/7.4/fpm/pool.d/www.conf
# Create a /status path for your webserver in order to track current requests to it
# Use IP/status to check PHP-FPM stats or IP/status?full&html for more detailed results
sed -i "s/^;pm.status_path = \/status/pm.status_path = \/status/" /etc/php/7.4/fpm/pool.d/www.conf
# Create a /ping path for your PHP-FPM installation in order to be able to make heartbeat calls to it
sed -i "s/^;ping.path = \/ping/ping.path = \/ping/" /etc/php/7.4/fpm/pool.d/www.conf
# Enable PHP-FPM Opcache
sed -i "s/^;opcache.enable=0/opcache.enable=1/" /etc/php/7.4/fpm/php.ini
# Set maximum memory limit for OPcache
sed -i "s/^;opcache.memory_consumption=64/opcache.memory_consumption=64/" /etc/php/7.4/fpm/php.ini
# Raise the maximum limit of variable that can be stored in OPcache
sed -i "s/^;opcache.interned_strings_buffer=4/opcache.interned_strings_buffer=16/" /etc/php/7.4/fpm/php.ini
# Set maximum amount fo files to be cached in OPcache
sed -i "s/^;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=65536/" /etc/php/7.4/fpm/php.ini
# Enabled using directory path in order to avoid collision between two files with identical names in OPcache
sed -i "s/^;opcache.use_cwd=1/opcache.use_cwd=1/" /etc/php/7.4/fpm/php.ini
# Enable validation of changes in php files
sed -i "s/^;opcache.validate_timestamps=1/opcache.validate_timestamps=1/" /etc/php/7.4/fpm/php.ini
# Set validation period in seconds for OPcache file
sed -i "s/^;opcache.revalidate_freq=2/opcache.revalidate_freq=2/" /etc/php/7.4/fpm/php.ini
# Disable comments to be put in OPcache code
sed -i "s/^;opcache.save_comments=1/opcache.save_comments=0/" /etc/php/7.4/fpm/php.ini
# Enable fast shutdown
sed -i "s/^;opcache.fast_shutdown=0/opcache.fast_shutdown=1/" /etc/php/7.4/fpm/php.ini
# Set period in seconds in which PHP-FPM should restart if OPcache is not accessible
sed -i "s/^;opcache.force_restart_timeout=180/opcache.force_restart_timeout=30/" /etc/php/7.4/fpm/php.ini

echo -e "${CYAN}Restart Services${NC}"
# Restart service redis
/etc/init.d/redis-server restart
# Restart memcached service
service memcached restart
# Reload Nginx installation
/etc/init.d/nginx reload 
# Reload PHP-FPM installation
/etc/init.d/php7.4-fpm reload

echo -e "${CYAN}Install a Monit service in order to maintain system fault tolerance${NC}"
# Add a rule for iptables in order to make Monit be able to work on this port
iptables -A INPUT -p tcp -m tcp --dport 2812 -j ACCEPT
# Install a Monit service in order to maintain system fault tolerance
apt-cache search monit
apt-get update
apt-get install monit

echo -e "${CYAN}Create a full backup of default Monit configuration${NC}"
# Create a full backup of default Monit configuration
now=$(date +"%Y-%m-%d_%H-%M-%S") 
mkdir -p /backup/$now/
mkdir -p /backup/$now/monit/
cp -r /etc/monit/ /backup/$now/monit/

echo -e "${CYAN}Configure Monit${NC}"
# Set time interval in which Monit will check the services
sed -i "s/^.*set daemon 120.*/set daemon 10/" /etc/monit/monitrc
# Set port on which Monit will be listening
sed -i "s/^#.*set httpd port 2812 and.*/set httpd port 2812 and/" /etc/monit/monitrc
# Set credentials for Monit to autentithicate itself on the server
sed -i "s/^#.*use address localhost.*/use address localhost/" /etc/monit/monitrc
sed -i "s/^#.*allow localhost.*/allow localhost/" /etc/monit/monitrc
sed -i "s/^#.*allow admin:monit.*/allow admin:monit/" /etc/monit/monitrc
# Tell monit to not search *.conf files in this directory
sed -i "s/^.*include \/etc\/monit\/conf-enabled\/\*/#include \/etc\/monit\/conf-enabled\/\*/" /etc/monit/monitrc

echo -e "${CYAN}Add configuration Monit to PHP${NC}"
# Create a Monit configuration file to watch after PHP-FPM
# Monit will check the availability of php7.4-fpm.sock
# And restart php7.4-fpm service if it can't be accessible
# If Monit tries to many times to restart it withour success it will take a timeout and then proceed to restart again
echo -e 'check process php7.4-fpm with pidfile /var/run/php/php7.4-fpm.pid\nstart program = "/etc/init.d/php7.4-fpm start"\nstop program = "/etc/init.d/php7.4-fpm stop"\nif failed unixsocket /run/php/php7.4-fpm.sock then restart\nif 5 restarts within 5 cycles then timeout' > /etc/monit/conf.d/php7.4-fpm.conf

echo -e "${CYAN}Add configuration Monit to NGINX${NC}"
# Create a Monit configuration file to watch after Nginx
# This one doesn't need Monit to restart it because Nginx is basically unbreakable
echo -e 'check process nginx with pidfile /var/run/nginx.pid\nstart program = "/etc/init.d/nginx start"\nstop program = "/etc/init.d/nginx stop"' > /etc/monit/conf.d/nginx.conf

echo -e "${CYAN}Add configuration Monit to SSH${NC}"
# Create a Monit configuration file to watch after SSH
# This is a fool safe tool if you occasionally restarted ssh process and can't get into your server again
echo -e 'check process sshd with pidfile /var/run/sshd.pid\nstart program "/etc/init.d/ssh start"\nstop program "/etc/init.d/ssh stop"\nrestart program = "/etc/init.d/ssh restart"\nif failed port 22 protocol ssh then restart\nif 5 restarts within 5 cycles then timeout' > /etc/monit/conf.d/sshd.conf

echo -e "${CYAN}Add configuration Monit to MEMCACHED${NC}"
# Create a Monit configuration file to watch after Memcached
echo -e 'check process memcached with match memcached\ngroup memcache\nstart program = "/etc/init.d/memcached start"\nstop program = "/etc/init.d/memcached stop"' > /etc/monit/conf.d/memcached.conf

echo -e "${CYAN}Add configuration Monit to REDIS${NC}"
# Create a Monit configuration file to watch after REDIS
echo -e 'check process redis-server\nwith pidfile "/var/run/redis/redis-server.pid"\nstart program = "/etc/init.d/redis-server start"\nstop program = "/etc/init.d/redis-server stop"\nif 2 restarts within 3 cycles then timeout\nif totalmem > 100 Mb then alert\nif children > 255 for 5 cycles then stop\nif cpu usage > 95% for 3 cycles then restart\nif failed host 127.0.0.1 port 6379 then restart\nif 5 restarts within 5 cycles then timeout' > /etc/monit/conf.d/redis.conf

echo -e "${CYAN}Start Monit ALL${NC}"
# Reload main Monit configuration
update-rc.d monit enable
# Reload Monit in order to pickup new included *.conf files
/etc/init.d/monit reload
# Tell Monit to start all services
/etc/init.d/monit start all
# Tell Monit to Monitor all services
monit monitor all
# Get status of processes watched by Monit
/etc/init.d/monit status

echo -e "${GREEN}All installed. Now restart server.${NC}"