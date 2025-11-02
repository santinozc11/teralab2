FROM php:7.2-apache

# Trabajamos siempre dentro del docroot
WORKDIR /var/www/html

# Copiá el código al contenedor
COPY . .

# Si 'config/' no viene en el repo (está en .gitignore), crealo a partir de config-dev/
RUN if [ ! -d config ]; then \
      mkdir -p config; \
      if [ -d config-dev ]; then cp -r config-dev/* config/; fi; \
    fi

# Site de Apache
COPY ./apache/default-site.conf /etc/apache2/sites-available/default-site.conf

# (stretch en archivo)
RUN sed -i -e 's/deb.debian.org/archive.debian.org/g' \
           -e 's|security.debian.org|archive.debian.org/|g' \
           -e '/stretch-updates/d' /etc/apt/sources.list

RUN apt-get update && apt-get upgrade -y
RUN apt-get update && apt-get install -y wget git

# Tu build de app
RUN make

# Enlaces y sitios
RUN ln -s /etc/apache2/sites-available/default-site.conf /etc/apache2/sites-enabled/default-site.conf \
 && a2dissite 000-default.conf \
 && a2ensite  default-site.conf

# Extensiones PHP
RUN docker-php-ext-install pdo pdo_mysql \
 && docker-php-ext-configure pdo \
 && docker-php-ext-configure pdo_mysql

# Apache y permisos
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf \
 && chown -R www-data:www-data /var/www/html/ \
 && mkdir -p /var/log/apache2/example-app/ \
 && chown -R www-data:www-data /var/log/apache2/example-app/ \
 && a2enmod rewrite

# Limpieza (ya copiamos el vhost arriba, borrar fuentes innecesarias)
RUN rm -rf sql/ apache/ Dockerfile Makefile README.md

EXPOSE 80
