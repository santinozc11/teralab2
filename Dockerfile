FROM php:7.2-apache

# Vhost primero (se queda en /etc, no depende del repo luego)
COPY ./apache/default-site.conf /etc/apache2/sites-available/default-site.conf

WORKDIR /var/www/html

# Repos archive para Debian stretch + paquetes básicos
RUN sed -i -e 's/deb.debian.org/archive.debian.org/g' \
           -e 's|security.debian.org|archive.debian.org/|g' \
           -e '/stretch-updates/d' /etc/apt/sources.list \
 && apt-get update && apt-get upgrade -y \
 && apt-get install -y wget git \
 && rm -rf /var/lib/apt/lists/*

# Código de la app
COPY . /var/www/html

# Tu flujo (composer/symlink) tal como lo usás
RUN make

# Habilitar vhost y módulos necesarios
RUN ln -sf /etc/apache2/sites-available/default-site.conf /etc/apache2/sites-enabled/default-site.conf \
 && a2dissite 000-default.conf && a2ensite default-site.conf \
 && docker-php-ext-install pdo pdo_mysql \
 && a2enmod rewrite

# 👉 FIX permisos y carpeta de logs de la app
RUN mkdir -p /var/www/html/logs /var/log/apache2/example-app \
 && chown -R www-data:www-data /var/www/html /var/log/apache2/example-app

# 👉 Enviar logs de Apache a stdout/stderr (CloudWatch)
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log \
 && ln -sf /proc/self/fd/2 /var/log/apache2/error.log \
 && ln -sf /proc/self/fd/1 /var/log/apache2/example-app/access.log \
 && ln -sf /proc/self/fd/2 /var/log/apache2/example-app/error.log

# No reiniciamos Apache en build (lo hace apache2-foreground en runtime)
# (tu línea previa 'service apache2 restart' removida a propósito)

# Limpieza del árbol copiado (el vhost ya quedó en /etc)
RUN rm -rf sql/ apache/ Dockerfile Makefile README.md || true

EXPOSE 80
