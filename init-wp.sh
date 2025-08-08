#!/bin/bash
set -e

WP_DIR="/var/www/html"

# 1) Se o volume estiver vazio, popula com o core do WP
if [ ! -e "$WP_DIR/wp-includes/version.php" ]; then
  echo "[init] Populando $WP_DIR com o WordPress core..."
  tar cf - -C /usr/src/wordpress . | tar xf - -C "$WP_DIR"
fi

# 2) .htaccess padrão, se não existir
if [ ! -f "$WP_DIR/.htaccess" ]; then
  cat > "$WP_DIR/.htaccess" <<'HT'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
HT
fi

# 3) Permissões
chown -R www-data:www-data "$WP_DIR"

# 4) Entrega para o entrypoint oficial do WordPress
exec docker-entrypoint.sh apache2-foreground
