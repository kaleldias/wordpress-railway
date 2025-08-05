FROM wordpress:latest
COPY uploads.ini /usr/local/etc/php/conf.d/uploads.ini

COPY update-wp-domain.sh /usr/local/bin/update-wp-domain.sh
RUN chmod +x /usr/local/bin/update-wp-domain.sh

ENTRYPOINT ["/usr/local/bin/update-wp-domain.sh"]