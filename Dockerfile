# use uma tag estável do WP
FROM wordpress:6.6-php8.2-apache

# limites PHP (ajuste como preferir)
COPY uploads.ini /usr/local/etc/php/conf.d/uploads.ini

# módulos do Apache que o WP precisa
RUN a2enmod rewrite headers expires

# wrapper de inicialização
COPY init-wp.sh /usr/local/bin/init-wp.sh
RUN chmod +x /usr/local/bin/init-wp.sh

# delega ao wrapper (que chama o entrypoint oficial no final)
ENTRYPOINT ["init-wp.sh"]
