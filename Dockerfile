FROM wordpress:latest

# PHP limits
COPY uploads.ini /usr/local/etc/php/conf.d/uploads.ini

# Garante que o MU-plugin estará presente:
#  - /usr/src/wordpress -> é copiado para /var/www/html quando o diretório estiver vazio (caso volume em /var/www/html)
#  - /var/www/html      -> cobre o caso sem volume
RUN mkdir -p /usr/src/wordpress/wp-content/mu-plugins \
    && mkdir -p /var/www/html/wp-content/mu-plugins
COPY wp-content/mu-plugins/force-domain.php /usr/src/wordpress/wp-content/mu-plugins/force-domain.php
COPY wp-content/mu-plugins/force-domain.php /var/www/html/wp-content/mu-plugins/force-domain.php
