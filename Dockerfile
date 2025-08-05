FROM wordpress:latest

# php.ini custom (uploads etc.)
COPY uploads.ini /usr/local/etc/php/conf.d/uploads.ini

# (Opcional) silenciar o aviso AH00558
RUN echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf \
 && a2enconf servername
