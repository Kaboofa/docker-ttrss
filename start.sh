#!/bin/bash

# Disable Strict Host checking for non interactive git clones
mkdir -p -m 0700 /root/.ssh
echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

# Tweak nginx to match the workers to cpu's
procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf
sed -i "s|user nginx;|user ${PHP_FPM_USER};|g" /etc/nginx/nginx.conf

if ! [ -d /var/www/app/tt-rss ]; then
  cd /var/www/app
  git clone -v https://tt-rss.org/git/tt-rss.git tt-rss
  chown -R ${PHP_FPM_USER}:${PHP_FPM_USER} /var/www/app/tt-rss
fi

# if ! [ -d /var/www/app/tt-rss ]; then
#   cd /var/www/app
#   mkdir tt-rss && cd tt-rss
#   touch index.php
#   echo "<?php phpinfo(); ?>" >> index.php
#   chown -R ${PHP_FPM_USER}:${PHP_FPM_USER} /var/www/app/tt-rss
# fi


# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf