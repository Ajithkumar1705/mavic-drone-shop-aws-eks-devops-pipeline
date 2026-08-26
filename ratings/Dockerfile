# Stage 1: install Composer dependencies separately from the runtime image
FROM composer:latest AS vendor

WORKDIR /app

COPY html/composer.json ./
RUN composer install --no-dev --ignore-platform-reqs

# Stage 2: actual runtime
FROM php:7.4-apache

# MySQL driver (not Postgres — this app connects to MySQL)
RUN docker-php-ext-install pdo pdo_mysql

# .htaccess needs mod_rewrite; status.conf needs mod_status
RUN a2enmod rewrite status

# Apache's default config ignores .htaccess unless AllowOverride is enabled
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

COPY status.conf /etc/apache2/conf-enabled/status.conf

COPY html/ /var/www/html/
COPY --from=vendor /app/vendor /var/www/html/vendor

EXPOSE 80

CMD ["apache2-foreground"]