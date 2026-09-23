# Stage 1: install Composer dependencies
FROM php:8.3.15-cli-bookworm AS vendor

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY html/composer.json ./

RUN composer install --no-dev --prefer-dist --no-interaction --no-progress


# Stage 2: actual runtime
FROM php:8.3.15-apache-bookworm

# MySQL driver and APCu
RUN apt-get update \
    && apt-get install -y --no-install-recommends $PHPIZE_DEPS curl ca-certificates \
    && docker-php-ext-install pdo pdo_mysql \
    && curl -fsSL https://github.com/krakjoe/apcu/archive/refs/tags/v5.1.24.tar.gz | tar xz \
    && cd apcu-5.1.24 \
    && phpize \
    && ./configure \
    && make -j"$(nproc)" \
    && make install \
    && docker-php-ext-enable apcu \
    && cd .. \
    && rm -rf apcu-5.1.24 \
    && apt-get purge -y --auto-remove $PHPIZE_DEPS \
    && rm -rf /var/lib/apt/lists/*

RUN echo "apc.enable_cli=1" \
    >> /usr/local/etc/php/conf.d/apc.ini

# Enable required Apache modules
RUN a2enmod rewrite status

# Allow .htaccess overrides
RUN sed -i \
    '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' \
    /etc/apache2/apache2.conf

COPY status.conf /etc/apache2/conf-enabled/status.conf

COPY html/ /var/www/html/

COPY --from=vendor /app/vendor /var/www/html/vendor

EXPOSE 80