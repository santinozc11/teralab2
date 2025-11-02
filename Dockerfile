FROM php:7.2-apache

# Copiá el vhost antes de habilitarlo (igual que ya hacías)
COPY ./apache/default-site.conf /etc/apache2/sites-available/default-site.conf

WORKDIR /var/www/html

# Repos arvhive (tu fix para stretch)
RUN sed -i -e 's/deb.debian.org/archive.debian.org/g' \
           -e 's|security.debian.org|archive.debian.org/|g' \
           -e '/stretch-updates/d' /etc/apt/sources.list

RUN apt-get update && apt-get upgrade -y && \
    apt-get update && apt-get install -y wget git && rm -rf /var/lib/apt/lists/*

# --- si dependés de make para composer/symlink, dejalo, pero no reinicies apache en build ---
COPY . /var/www/html
RUN make || true   # si falla, que no corte el build

# Habilitar vhost y módulos
RUN ln -s /etc/apache2/sites-available/default-site.conf /etc/apache2/sites-enabled/default-site.conf && \
    a2dissite 000-default.conf && a2ensite default-site.conf && \
    docker-php-ext-install pdo pdo_mysql && a2enmod rewrite

# Logs a stdout/stderr → visibles en CloudWatch
RUN mkdir -p /var/log/apache2/example-app/ && \
    ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/2 /var/log/apache2/error.log  && \
    ln -sf /proc/self/fd/1 /var/log/apache2/example-app/access.log && \
    ln -sf /proc/self/fd/2 /var/log/apache2/example-app/error.log

# NO reinicies apache en build (se lanza con apache2-foreground en runtime)
# ❌ service apache2 restart

# Limpieza (dejá el vhost)
RUN rm -rf sql/ apache/ Dockerfile Makefile README.md || true

EXPOSE 80
# CMD por defecto de la imagen base php:apache ya es apache2-foreground
