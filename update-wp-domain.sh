#!/bin/sh
set -e

# VARIÁVEIS
DB_HOST="${WORDPRESS_DB_HOST:-mysql}"
DB_USER="${WORDPRESS_DB_USER:-root}"
DB_PASS="${WORDPRESS_DB_PASSWORD}"
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"

# Novos domínios das variáveis Railway ou padrão WP
NEW_URL="${WP_HOME:-https://${RAILWAY_PUBLIC_DOMAIN}}"

# Aguarda banco subir (até 30 tentativas)
MAX_TRIES=30
TRIES=0
until mysql --host="$DB_HOST" --user="$DB_USER" --password="$DB_PASS" -e "SELECT 1" > /dev/null 2>&1; do
  TRIES=$((TRIES+1))
  if [ $TRIES -ge $MAX_TRIES ]; then
    echo "Erro: não conseguiu conectar ao banco MySQL em $DB_HOST"
    exit 1
  fi
  echo "Aguardando banco subir... tentativa $TRIES/$MAX_TRIES"
  sleep 2
done

# Atualiza URLs se variável estiver definida
if [ -n "$NEW_URL" ]; then
  echo "Atualizando domínio do WordPress para: $NEW_URL"
  mysql --host="$DB_HOST" --user="$DB_USER" --password="$DB_PASS" "$DB_NAME" \
    -e "UPDATE wp_options SET option_value='$NEW_URL' WHERE option_name IN ('siteurl','home');"
fi

# Chama o entrypoint padrão
exec docker-entrypoint.sh apache2-foreground
