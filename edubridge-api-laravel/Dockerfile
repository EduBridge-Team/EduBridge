FROM php:8.4-cli-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        libpq-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-install pdo_pgsql pgsql bcmath \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader \
    --no-interaction \
    --no-scripts

COPY . .

RUN composer dump-autoload --optimize --no-dev --no-interaction --no-scripts \
    && php artisan package:discover --ansi \
    && mkdir -p \
        storage/framework/cache \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

ENV APP_ENV=production \
    APP_DEBUG=false

EXPOSE 8081

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8081"]
