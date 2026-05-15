ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-fpm-alpine

# Build arguments
ARG UID=1000
ARG GID=1000
ARG PHP_VERSION

# Install system dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    unzip \
    zip \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    libxml2-dev \
    oniguruma-dev \
    postgresql-dev \
    sqlite-dev \
    autoconf \
    g++ \
    make \
    linux-headers \
    nodejs \
    npm \
    mysql-client \
    postgresql-client \
    sqlite

# Configure and install PHP extensions
# PHP 7.2 uses old GD configuration syntax
# commit updated
RUN docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pdo_sqlite \
        mysqli \
        opcache \
        intl \
        zip \
        bcmath \
        soap \
        exif \
        pcntl \
        sockets

# Install Redis extension (specific version for PHP 7.2)
RUN pecl install redis-5.3.7 && docker-php-ext-enable redis

# Install Xdebug (version depends on PHP version)
RUN if [ "${PHP_VERSION}" = "7.2" ] || [ "${PHP_VERSION}" = "7.4" ]; then \
        pecl install xdebug-3.1.6; \
    else \
        pecl install xdebug; \
    fi \
    && docker-php-ext-enable xdebug

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Install Laravel Installer
RUN composer global require laravel/installer

# Install Symfony CLI
RUN curl -sS https://get.symfony.com/cli/installer | bash \
    && mv /root/.symfony*/bin/symfony /usr/local/bin/symfony

# Install PHPUnit
RUN composer global require phpunit/phpunit

# Install PHP CS Fixer
RUN composer global require friendsofphp/php-cs-fixer

# Install PHPStan
RUN composer global require phpstan/phpstan

# Add Composer global bin to PATH
ENV PATH="/root/.composer/vendor/bin:${PATH}"

# Create user with same UID/GID as host
RUN addgroup -g ${GID} appuser \
    && adduser -D -u ${UID} -G appuser appuser

# Create working directory
RUN mkdir -p /var/www \
    && chown -R appuser:appuser /var/www

# Create log directory
RUN mkdir -p /var/log/php \
    && chown -R appuser:appuser /var/log/php

# Set working directory
WORKDIR /var/www

# Expose PHP-FPM port
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD php-fpm -t || exit 1

# Switch to non-root user
USER appuser

CMD ["php-fpm"]
