# Stage 1: install Composer dependencies using PHP 7.4 (matching the
# actual runtime below), not composer:latest's own bundled PHP interpreter
# — that image's internal PHP version is unrelated to this app's target
# PHP and had drifted to 8.5, causing Composer's platform compatibility
# checks to validate against the wrong PHP version entirely. Copying just
# the composer binary (a portable phar file) into a real php:7.4 image
# fixes this at the root, rather than working around it with
# --ignore-platform-reqs, which masks genuine incompatibilities too.
FROM php:7.4-cli AS vendor

# bullseye has aged out of the live Debian mirrors — deb.debian.org and
# security.debian.org only serve current releases, so any package version
# still pinned to bullseye 404s. Repoint apt at the permanent archive.
RUN sed -i 's|deb.debian.org|archive.debian.org|g; s|security.debian.org|archive.debian.org|g' /etc/apt/sources.list \
    && apt-get update -o Acquire::Check-Valid-Until=false && apt-get install -y --no-install-recommends unzip && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY html/composer.json ./
RUN composer install --no-dev

# Stage 2: actual runtime
FROM php:7.4-apache

# MySQL driver (not Postgres — this app connects to MySQL)
RUN docker-php-ext-install pdo pdo_mysql

# APCu — required by the Prometheus PHP client to share counter state
# across requests, since each PHP request otherwise starts with a blank
# memory space (unlike Node.js/Go's persistent in-process state).
#
# NOTE: two prior approaches (plain `pecl install`, then
# install-php-extensions) both failed identically — both ultimately depend
# on PECL's channel XML from pecl.php.net, which is broken/unparseable
# against this old base image's bundled pear/pecl tooling. Building from
# source, fetched directly from GitHub, sidesteps PECL entirely. The exact
# release tag is resolved dynamically via GitHub's API rather than
# hardcoded, so this can't go stale the way a pinned version could.
RUN sed -i 's|deb.debian.org|archive.debian.org|g; s|security.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    apt-get update -o Acquire::Check-Valid-Until=false && \
    apt-get install -y --no-install-recommends $PHPIZE_DEPS curl ca-certificates \
    && LATEST_TAG=$(curl -s https://api.github.com/repos/krakjoe/apcu/releases/latest | grep '"tag_name"' | cut -d '"' -f4) \
    && curl -sSL "https://github.com/krakjoe/apcu/archive/refs/tags/${LATEST_TAG}.tar.gz" | tar xz \
    && cd apcu-* \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable apcu \
    && cd .. && rm -rf apcu-* \
    && apt-get purge -y --auto-remove $PHPIZE_DEPS \
    && rm -rf /var/lib/apt/lists/*
RUN echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

# .htaccess needs mod_rewrite; status.conf needs mod_status
RUN a2enmod rewrite status

# Apache's default config ignores .htaccess unless AllowOverride is enabled
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

COPY status.conf /etc/apache2/conf-enabled/status.conf

COPY html/ /var/www/html/
COPY --from=vendor /app/vendor /var/www/html/vendor

EXPOSE 80

CMD ["apache2-foreground"]