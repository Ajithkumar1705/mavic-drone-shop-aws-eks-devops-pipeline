# Stage 1: install Composer dependencies using PHP 7.4
FROM php:7.4-cli AS vendor

# PHP 7.4 uses Debian Bullseye, which is now archived.
# Replace all Debian mirrors with the archive and remove the obsolete
# Debian security repository.
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null || true && \
    sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null || true && \
    rm -f /etc/apt/sources.list.d/*security* && \
    find /etc/apt/sources.list.d -type f -name '*.sources' -exec sed -i '/debian-security/Id' {} \; && \
    apt-get update -o Acquire::Check-Valid-Until=false && \
    apt-get install -y --no-install-recommends unzip && \
    rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY html/composer.json ./

RUN composer install --no-dev


# Stage 2: actual runtime
FROM php:7.4-apache

# MySQL driver
RUN docker-php-ext-install pdo pdo_mysql

# APCu
# Build APCu directly from GitHub instead of using PECL.
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null || true && \
    sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null || true && \
    rm -f /etc/apt/sources.list.d/*security* && \
    find /etc/apt/sources.list.d -type f -name '*.sources' -exec sed -i '/debian-security/Id' {} \; && \
    apt-get update -o Acquire::Check-Valid-Until=false && \
    apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        curl \
        ca-certificates \
    && LATEST_TAG=$(curl -s https://api.github.com/repos/krakjoe/apcu/releases/latest | grep '"tag_name"' | cut -d '"' -f4) \
    && curl -sSL "https://github.com/krakjoe/apcu/archive/refs/tags/${LATEST_TAG}.tar.gz" | tar xz \
    && cd apcu-* \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable apcu \
    && cd .. \
    && rm -rf apcu-* \
    && apt-get purge -y --auto-remove \
        $PHPIZE_DEPS \
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