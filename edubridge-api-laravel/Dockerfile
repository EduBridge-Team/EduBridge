FROM php:8.4-fpm-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        libonig-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        unzip \
        nginx \
        supervisor \
    && docker-php-ext-install bcmath dom mbstring opcache pdo_pgsql pgsql \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY docker/uploads.ini /usr/local/etc/php/conf.d/99-edubridge-uploads.ini
COPY docker/production.ini /usr/local/etc/php/conf.d/98-edubridge-production.ini
COPY docker/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/edubridge.conf

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader \
    --no-interaction \
    --no-scripts

COPY . .

# Normalize application source permissions: local Git checkout may contain
# mode 600 PHP files, but the runtime executes as the non-root www-data user.
RUN find app routes -type d -exec chmod 755 {} + \
    && find app routes -type f -exec chmod 644 {} +

RUN composer dump-autoload --optimize --no-dev --no-interaction --no-scripts \
    && php artisan package:discover --ansi \
    && mkdir -p \
        storage/framework/cache \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache \
        /tmp/edubridge-nginx/client_body \
        /tmp/edubridge-nginx/proxy \
        /tmp/edubridge-nginx/fastcgi \
        /tmp/edubridge-nginx/uwsgi \
        /tmp/edubridge-nginx/scgi \
    && chown -R www-data:www-data storage bootstrap/cache /tmp/edubridge-nginx

ENV APP_ENV=production \
    APP_DEBUG=false

EXPOSE 8081

STOPSIGNAL SIGTERM

USER www-data

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/edubridge.conf"]
