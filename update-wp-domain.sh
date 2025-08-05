#!/bin/sh
set -e

# 1) Fonte principal: variáveis WORDPRESS_DB_* (padrão da imagem oficial)
DB_HOST="${WORDPRESS_DB_HOST:-mysql}"
DB_USER="${WORDPRESS_DB_USER:-root}"
DB_PASS="${WORDPRESS_DB_PASSWORD}"
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"

# 2) Se existir MYSQL_URL (ou WORDPRESS_DB_HOST vier como URI), extrair tudo
#    Formatos aceitos: mysql://user:pass@host:port/db
parse_uri() {
  uri="$1"
  # Remove o esquema
  no_scheme="${uri#mysql://}"
  creds_host_db="${no_scheme%%\?*}"       # descarta querystring se houver
  creds="${creds_host_db%@*}"
  host_db="${creds_host_db#*@}"

  user="${creds%%:*}"
  pass="${creds#*:}"
  pass="${pass%%@*}"

  host_port="${host_db%%/*}"
  db="${host_db#*/}"

  host="${host_port%%:*}"
  port="${host_port#*:}"
  [ "$host" = "$port" ] && port="3306"

  echo "$user;$pass;$host;$port;$db"
}

# Preferência 1: MYSQL_URL completa
if [ -n "$MYSQL_URL" ]; then
  IFS=';' read -r u p h pr d <<EOF
$(parse_uri "$MYSQL_URL")
EOF
  DB_USER="${u:-$DB_USER}"
  DB_PASS="${p:-$DB_PASS}"
  DB_NAME="${d:-$DB_NAME}"
  HOST_PART="${h:-$DB_HOST}"
  PORT_PART="${pr:-3306}"
else
  # Preferência 2: WORDPRESS_DB_HOST pode ser "host:porta" OU, se vier como URI, tratamos também
  if echo "$DB_HOST" | grep -q "://"; then
    IFS=';' read -r u p h pr d <<EOF
$(parse_uri "$DB_HOST")
EOF
    DB_USER="${u:-$DB_USER}"
    DB_PASS="${p:-$DB_PASS}"
    DB_NAME="${d:-$DB_NAME}"
    HOST_PART="${h:-mysql}"
    PORT_PART="${pr:-3306}"
  else
    HOST_PART="$DB_HOST"
    PORT_PART="3306"
    if echo "$DB_HOST" | grep -q ':'; then
      HOST_PART="$(echo "$DB_HOST" | cut -d: -f1)"
      PORT_PART="$(echo "$DB_HOST" | cut -d: -f2)"
    fi
  fi
fi

# 3) Domínio a aplicar no banco: WP_HOME prioritário; senão, RAILWAY_PUBLIC_DOMAIN
NEW_URL="${WP_HOME:-https://${RAILWAY_PUBLIC_DOMAIN}}"

# 4) Espera banco ficar pronto
MAX_TRIES="${MAX_TRIES:-60}"
SLEEP_SEC="${SLEEP_SEC:-3}"
TRIES=0
until mysql --host="$HOST_PART" --port="$PORT_PART" --user="$DB_USER" --password="$DB_PASS" -e "SELECT 1" >/dev/null 2>&1; do
  TRIES=$((TRIES+1))
  if [ $TRIES -ge $MAX_TRIES ]; then
    echo "Erro: não conseguiu conectar ao MySQL em $HOST_PART:$PORT_PART (user=$DB_USER, db=$DB_NAME)"
    exit 1
  fi
  echo "Aguardando MySQL... tentativa $TRIES/$MAX_TRIES"
  sleep "$SLEEP_SEC"
done

# 5) Atualiza siteurl/home se NEW_URL estiver definido
if [ -n "$NEW_URL" ]; then
  echo "Atualizando siteurl/home para: $NEW_URL"
  mysql --host="$HOST_PART" --port="$PORT_PART" --user="$DB_USER" --password="$DB_PASS" "$DB_NAME" \
    -e "UPDATE wp_options SET option_value='${NEW_URL}' WHERE option_name IN ('siteurl','home');"
fi

# 6) Sobe o Apache/PHP do WordPress
exec docker-entrypoint.sh apache2-foreground
