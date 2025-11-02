FROM php:7.2-apache

# Copiamos el virtual host personalizado antes de habilitarlo
COPY ./apache/default-site.conf /etc/apache2/sites-available/default-site.conf

WORKDIR /var/www/html

# Fix de repos Debian stretch + paquetes básicos
RUN sed -i -e 's/deb.debian.org/archive.debian.org/g' \
           -e 's|security.debian.org|archive.debian.org/|g' \
           -e '/stretch-updates/d' /etc/apt/sources.list \
 && apt-get update && apt-get upgrade -y \
 && apt-get update && apt-get install -y wget git \
 && rm -rf /var/lib/apt/lists/*

# Copiamos el código de la app
COPY . /var/www/html

# Ejecutamos tu make (composer install + symlinks config-dev → config)
# Si make falla que no rompa la build, pero idealmente debería pasar
RUN make || true

# Habilitamos sitio y módulos que la app necesita
RUN ln -sf /etc/apache2/sites-available/default-site.conf /etc/apache2/sites-enabled/default-site.conf \
 && a2dissite 000-default.conf \
 && a2ensite default-site.conf \
 && docker-php-ext-install pdo pdo_mysql \
 && a2enmod rewrite

# Ajustes de Apache + permisos correctos para que PHP pueda escribir
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf \
 && mkdir -p /var/log/apache2/example-app \
 && mkdir -p /var/www/html/logs \
 && chown -R www-data:www-data /var/www/html /var/log/apache2/example-app

# Redirigimos logs de Apache a stdout/stderr
# Esto hace que lo que normalmente iría a error.log quede en stderr,
# y lo ves en CloudWatch automáticamente con awslogs.
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log \
 && ln -sf /proc/self/fd/2 /var/log/apache2/error.log \
 && ln -sf /proc/self/fd/1 /var/log/apache2/example-app/access.log \
 && ln -sf /proc/self/fd/2 /var/log/apache2/example-app/error.log

# Limpieza final de cosas que no queremos en runtime dentro de la imagen
# (ya copiamos default-site.conf al /etc, así que podemos borrar ./apache del docroot)
RUN rm -rf sql/ apache/ Dockerfile Makefile README.md || true

EXPOSE 80

# Importante: NO hacemos "service apache2 restart" en build.
# La imagen base php:7.2-apache ya arranca Apache en foreground cuando corre el contenedor.
# CMD se mantiene el default de esa imagen (apache2-foreground)
