#!/bin/bash
set -Eeuo pipefail
cd /powerdns-admin

GUNICORN_TIMEOUT="${GUINCORN_TIMEOUT:-120}"
GUNICORN_WORKERS="${GUNICORN_WORKERS:-4}"
LOG_LEVEL="${LOG_LEVEL:-info}"
PDNS_PROTO="${PDNS_PROTO:-http}"
PDNS_PROTO="${PDNS_PROTO:-8081}"

# Wait for us to be able to connect to MySQL before proceeding
echo "===> Waiting for $SQLA_DB_HOST MySQL service"
until nc -zv \
  $SQLA_DB_HOST \
  $SQLA_DB_PORT;
do
  echo "MySQL ($SQLA_DB_HOST) is unavailable - sleeping 5 seconds"
  sleep 5
done

echo "===> Update PDNS API connection info"
# initial setting if not available in the DB
#mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'pdns_api_url', '${PDNS_PROTO}://${PDNS_HOST}:${PDNS_PORT}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'pdns_api_url') LIMIT 1;"
#mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'pdns_api_key', '${PDNS_API_KEY}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'pdns_api_key') LIMIT 1;"

# update pdns api setting if environment variable is changed.
#mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "UPDATE setting SET value='${PDNS_PROTO}://${PDNS_HOST}:${PDNS_PORT}' WHERE name='pdns_api_url';"
#mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "UPDATE setting SET value='${PDNS_API_KEY}' WHERE name='pdns_api_key';"

GUNICORN_ARGS="-t ${GUNICORN_TIMEOUT} --workers ${GUNICORN_WORKERS}"
if [ "$1" == gunicorn ]; then
    flask db upgrade
    exec "$@" $GUNICORN_ARGS
else
    exec "$@"
fi
