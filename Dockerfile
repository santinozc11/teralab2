FROM php:7.2-apache

# Vhost (queda fuera del docroot)
COPY ./apache/default-site.conf /etc/apache2/sites-available/default-site.conf

WORKDIR /var/www/html

# Repos stretch + paquetes básicos
RUN sed -i -e 's/deb.debian.org/archive.debian.org/g' \
           -e 's|security.debian.org|archive.debian.org/|g' \
           -e '/stretch-updates/d' /etc/apt/sources.list \
 && apt-get update && apt-get upgrade -y \
 && apt-get update && apt-get install -y wget git \
 && rm -rf /var/lib/apt/lists/*

# 🔴 Forzá PHP a loguear a stderr (CloudWatch) y que reporte TODO
RUN set -eux; \
  { \
    echo 'display_errors=Off'; \
    echo 'log_errors=On'; \
    echo 'error_reporting=E_ALL'; \
    echo 'error_log=/dev/stderr'; \
    echo 'date.timezone=UTC'; \
  } > /usr/local/etc/php/conf.d/99-logging.ini

# Código de la app
COPY . /var/www/html

# Tu build (composer/symlink); si falla no frena, pero idealmente pasa
RUN make || true

# Sitio y módulos
RUN ln -sf /etc/apache2/sites-available/default-site.conf /etc/apache2/sites-enabled/default-site.conf \
 && a2dissite 000-default.conf && a2ensite default-site.conf \
 && docker-php-ext-install pdo pdo_mysql \
 && a2enmod rewrite

# Permisos y logs de Apache a stdout/stderr
RUN mkdir -p /var/www/html/logs /var/log/apache2/example-app \
 && chown -R www-data:www-data /var/www/html /var/log/apache2/example-app \
 && ln -sf /proc/self/fd/1 /var/log/apache2/access.log \
 && ln -sf /proc/self/fd/2 /var/log/apache2/error.log \
 && ln -sf /proc/self/fd/1 /var/log/apache2/example-app/access.log \
 && ln -sf /proc/self/fd/2 /var/log/apache2/example-app/error.log

# Limpieza de cosas innecesarias en el docroot
RUN rm -rf sql/ apache/ Dockerfile Makefile README.md || true

EXPOSE 80
