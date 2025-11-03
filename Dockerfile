# Permite inyectar la base desde el buildspec (tu imagen estable por defecto)
ARG BASE_IMAGE=607007849260.dkr.ecr.us-east-1.amazonaws.com/lab2-frontend@sha256:7f1ae0dcd122fa0aff3df2673ab58f40b17feff11708ef4531660199ed60ba8f
FROM ${BASE_IMAGE}

WORKDIR /var/www/html

# Vhost (siempre lo refrescamos desde el repo)
COPY apache/default-site.conf /etc/apache2/sites-available/default-site.conf

# Código de la app
COPY . /var/www/html

# Habilitar vhost y módulos
RUN ln -sf /etc/apache2/sites-available/default-site.conf /etc/apache2/sites-enabled/default-site.conf \
 && a2enmod rewrite \
 && apache2ctl -t

# Logs PHP/Apache hacia stdout/stderr (CloudWatch)
RUN mkdir -p /var/log/apache2/example-app \
 && ln -sf /proc/self/fd/1 /var/log/apache2/access.log \
 && ln -sf /proc/self/fd/2 /var/log/apache2/error.log \
 && ln -sf /proc/self/fd/1 /var/log/apache2/example-app/access.log \
 && ln -sf /proc/self/fd/2 /var/log/apache2/example-app/error.log \
 && printf "log_errors=On\ndisplay_errors=Off\nerror_reporting=E_ALL\nerror_log=/dev/stderr\n" > /usr/local/etc/php/conf.d/99-logging.ini

# Build del proyecto (composer/symlink) — no corta si falla
RUN make || true

# Opcional: limpiar sobras de build dentro del docroot (dejalo si lo venías usando)
# RUN rm -rf sql/ apache/ Dockerfile Makefile README.md || true

EXPOSE 80
