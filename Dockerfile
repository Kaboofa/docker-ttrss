FROM alpine:latest

LABEL maintainer="Romain BOURGUIGNON <romain.bourguignon@gmail.com>"

ENV PHP_FPM_USER="www"
ENV PHP_FPM_GROUP="www"
ENV PHP_FPM_LISTEN_MODE="0660"
ENV PHP_MEMORY_LIMIT="512M"
ENV PHP_MAX_UPLOAD="50M"
ENV PHP_MAX_FILE_UPLOAD="200"
ENV PHP_MAX_POST="100M"
ENV PHP_DISPLAY_ERRORS="On"
ENV PHP_DISPLAY_STARTUP_ERRORS="On"
ENV PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR"
ENV PHP_CGI_FIX_PATHINFO=0


RUN apk update \
    && apk add --no-cache \
    nginx \
    supervisor \
    bash \
    curl \
    git \
    php7 \
    php7-fpm \
    php7-pgsql \
    php7-pdo_pgsql \
    php7-json \
    php7-dom \
    php7-xml \
    php7-ctype \
    php7-mbstring \
    php7-fileinfo \
    php7-curl \
    php7-posix \
    php7-gd \
    php7-iconv \
    php7-intl \
    php7-session \
    php7-pcntl \
    && rm /var/cache/apk/* \
    && adduser -D -g ${PHP_FPM_USER} ${PHP_FPM_GROUP} \
    && mkdir -p /etc/nginx \
    && mkdir -p /var/www/app \
    && chown -R ${PHP_FPM_USER}:${PHP_FPM_GROUP} /var/www/app \
    && mkdir -p /run/nginx \
    && mkdir -p /var/log/supervisor \
    && rm /etc/nginx/nginx.conf

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./tt-rss.conf /etc/nginx/tt-rss.conf
COPY ./supervisord.conf /etc/supervisord.conf
COPY ./start.sh /start.sh

RUN sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php7/php.ini \
    && sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php7/php.ini \
    && sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php7/php.ini \
    && sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini \
    && sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php7/php.ini \
    && sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini \
    && sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini \
    && sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php7/php.ini \
    && sed -i "s|variables_order = \"GPCS\"|variables_order = \"EGPCS\"|g" /etc/php7/php.ini \
    && sed -i "s|;daemonize\s*=\s*yes|daemonize = no|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|error_log = /var/log/php-fpm.log;|error_log = /proc/self/fd/2;|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|;catch_workers_output\s*=\s*yes|catch_workers_output = yes|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|pm.max_children = 5|pm.max_children = 9|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|pm.start_servers = 2|pm.start_servers = 3|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|pm.min_spare_servers = 1|pm.min_spare_servers = 2|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|pm.max_spare_servers = 3|pm.max_spare_servers = 4|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|;pm.max_requests = 500|pm.max_requests = 200|g" /etc/php7/php-fpm.d/www.conf \
    && sed -i "s|listen = 127.0.0.1:9000|listen = /var/run/php-fpm.sock|g" /etc/php7/php-fpm.d/www.conf \
    && rm -Rf /etc/nginx/conf.d/* \
    && rm -Rf /etc/nginx/sites-available/default \
    && mkdir -p /etc/nginx/ssl/ \
    && chmod 755 /start.sh \
    && find /etc/php7/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# Expose Volumes
VOLUME "/var/www/app"

# Expose Ports
EXPOSE 80

# Start Supervisord
CMD ["/bin/sh", "/start.sh"]