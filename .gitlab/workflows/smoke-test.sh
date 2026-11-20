#!/usr/bin/env bash
# Smoke-Test fuer eine wp-battery-Site. Laeuft im Job smoke-test
# (.gitlab/workflows/checks.yml); erwartet eine MariaDB unter dem Host "db".
#
# Baut die Site wie der Deploy (composer --no-dev, npm build), installiert
# WordPress in eine leere Datenbank, aktiviert alle Plugins und das Theme
# und ruft Startseite und Login auf. Rot bei HTTP != 200 oder PHP-Fatal.
# Bei Fehlern liegen Seiten und Logs als Artefakt unter smoke/.
set -euo pipefail

if [ -z "${SMOKE_THEME:-}" ]; then
  themes=$(find packages/themes -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
  if [ "$(printf '%s\n' "$themes" | grep -c .)" != 1 ]; then
    echo "Mehrere oder keine Themes unter packages/themes, SMOKE_THEME in checks.yml setzen:"
    printf '%s\n' "$themes"
    exit 1
  fi
  SMOKE_THEME=$themes
fi
echo "Theme: $SMOKE_THEME"
: "${WP_CLI_VERSION:?}" "${WP_CLI_SHA512:?}"
out=smoke
mkdir -p "$out"
port=8080
url="http://127.0.0.1:${port}"

echo "== Build wie beim Deploy"
composer install --no-ansi --no-interaction --no-dev --no-progress
if [ -f package.json ]; then
  npm ci --no-audit --no-fund
  npm run build
fi

echo "== WP-CLI ${WP_CLI_VERSION}"
curl -fsSL -o wp-cli.phar \
  "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar"
echo "${WP_CLI_SHA512}  wp-cli.phar" | sha512sum -c -
wp() { php wp-cli.phar --allow-root "$@"; }

echo "== .env"
salt() { php -r 'echo bin2hex(random_bytes(32));'; }
{
  echo "DB_NAME='wp'"
  echo "DB_USER='wp'"
  echo "DB_PASSWORD='wp'"
  echo "DB_HOST='db'"
  # production: dieselben Debug- und Indexing-Einstellungen wie live.
  echo "WP_ENV='production'"
  echo "WP_PROTOCOL='http://'"
  echo "WP_DOMAIN='127.0.0.1:${port}'"
  echo "WP_HOME='${url}'"
  echo "WP_SITEURL='${url}/wp'"
  for k in AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT; do
    echo "${k}='$(salt)'"
  done
} > .env

echo "== Warten auf MariaDB"
for i in $(seq 1 60); do
  php -r 'exit(@mysqli_connect("db","wp","wp","wp") ? 0 : 1);' && break
  [ "$i" = 60 ] && { echo "MariaDB nicht erreichbar"; exit 1; }
  sleep 1
done

echo "== WordPress installieren"
wp core install --url="$url" --title="Smoke-Test" --admin_user=smoke \
  --admin_password="$(salt)" --admin_email=smoke@example.invalid --skip-email
wp plugin activate --all
wp theme activate "$SMOKE_THEME"
wp plugin list --fields=name,status,version
wp theme list --fields=name,status,version

echo "== HTTP"
errlog="$PWD/$out/php-errors.log"
: > "$errlog"
php -d log_errors=On -d display_errors=Off -d error_log="$errlog" \
  -S "127.0.0.1:${port}" -t web > "$out/server.log" 2>&1 &
server=$!
trap 'kill "$server" 2>/dev/null || true' EXIT
for i in $(seq 1 30); do
  curl -s -o /dev/null "$url/wp/wp-login.php" && break
  sleep 1
done

fail=0
check() {
  local name=$1 path=$2 code
  code=$(curl -s -o "$out/$name.html" -w '%{http_code}' "$url$path")
  echo "$path -> HTTP $code"
  [ "$code" = 200 ] || fail=1
}
check home /
check login /wp/wp-login.php

if grep -E "PHP (Fatal|Parse) error" "$errlog"; then
  fail=1
fi
if grep -liE "critical error|kritischer Fehler" "$out"/*.html; then
  fail=1
fi

if [ "$fail" != 0 ]; then
  echo "Smoke-Test rot. Seiten und Logs: Job-Artefakt smoke/."
  exit 1
fi
echo "Smoke-Test gruen."
