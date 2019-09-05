#!/bin/bash
set -e

ADMIN_USER_PASSWORD_HASHED=

# Webserver settings
if [[ -z ${BIND_ADDRESS} ]]; then
  BIND_ADDRESS=0.0.0.0;
fi

if [[ -z ${PORT} ]]; then
  PORT=9191;
fi

if [[ -z ${LOG_LEVEL} ]]; then
  LOG_LEVEL=info;
fi

if [[ -z ${GUNICORN_TIMEOUT} ]]; then
  GUNICORN_TIMEOUT=120;
fi

if [[ -z ${GUNICORN_WORKERS} ]]; then
  GUNICORN_WORKERS=4;
fi

# PowerDNS settings
if [[ -z ${PDNS_HOST} ]]; then
  PDNS_HOST=pdns-server;
fi

if [[ -z ${PDNS_API_KEY} ]]; then
  PDNS_API_KEY=changeme;
fi

if [[ -z ${PDNS_PORT} ]]; then
  PDNS_PORT=8081;
fi

if [[ -z ${PDNS_PROTO} ]]; then
  PDNS_PROTO=http;
fi

if [[ -z ${PDNS_VERSION} ]]; then
  PDNS_VERSION=4.1.1;
fi

# SQL settings
if [[ -z ${SQLA_DB_HOST} ]]; then
  SQLA_DB_HOST=powerdns-admin-mysql;
fi

if [[ -z ${SQLA_DB_NAME} ]]; then
  SQLA_DB_NAME=powerdns-admin;
fi

if [[ -z ${SQLA_DB_USER} ]]; then
  SQLA_DB_USER=powerdns-admin-svc-user;
fi

if [[ -z ${SQLA_DB_PASSWORD} ]]; then
  SQLA_DB_PASSWORD=powerdns-admin-svc-user-pw;
fi

if [[ -z ${SQLA_DB_PORT} ]]; then
  SQLA_DB_PORT=3306;
fi

# User authentication settings
if [[ -z ${SIGNUP_ENABLED} ]]; then
  SIGNUP_ENABLED=false;
fi

if [[ -z ${ADMIN_USER} && ${SIGNUP_ENABLED} -eq false ]]; then
  ADMIN_USER=admin;
  echo "A ADMIN_USER must be configured if you disable signup. Defaulting: $ADMIN_USER".
fi

if [[ -z ${ADMIN_USER_PASSWORD} ]]; then
  ADMIN_USER_PASSWORD=12345
  echo "A ADMIN_USER_PASSWORD must be configured if you disable signup. Default: $ADMIN_USER_PASSWORD".
fi

#if [[ ${SIGNUP_ENABLED} -eq false ]]; then
  # Hash the PW
  #ADMIN_USER_PASSWORD_HASHED=$(python3 -c "import os; import bcrypt; print(bcrypt.hashpw(str(os.getenv('ADMIN_USER_PASSWORD', '12345')), bcrypt.gensalt()))")
#fi

# Wait for us to be able to connect to #mysql before proceeding
echo "===> Waiting for $SQLA_DB_HOST #mysql service"
until nc -zv \
  $SQLA_DB_HOST \
  $SQLA_DB_PORT;
do
  echo "mysql ($SQLA_DB_HOST) is unavailable - sleeping 2 seconds"
  sleep 2
done

echo "===> DB management"
# DB Migration directory
DB_MIGRATION_DIR='/powerdns-admin/migrations'
# Go in Workdir
cd /powerdns-admin

if [ ! -d "${DB_MIGRATION_DIR}" ]; then
  echo "---> Running DB Init"
  flask db init --directory ${DB_MIGRATION_DIR}
  flask db migrate -m "Init DB" --directory ${DB_MIGRATION_DIR}
  flask db upgrade --directory ${DB_MIGRATION_DIR}
  ./init_data.py

else
  echo "---> Running DB Migration"
  set +e
  flask db migrate -m "Upgrade DB Schema" --directory ${DB_MIGRATION_DIR}
  flask db upgrade --directory ${DB_MIGRATION_DIR}
  set -e
fi

echo "===> Update PDNS API connection info"
# Initial setting if not available in the DB
mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'pdns_api_url', '${PDNS_PROTO}://${PDNS_HOST}:${PDNS_PORT}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'pdns_api_url') LIMIT 1;"
mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'pdns_api_key', '${PDNS_API_KEY}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'pdns_api_key') LIMIT 1;"
mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'pdns_version', '${PDNS_VERSION}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'pdns_version') LIMIT 1;"
#if [[ ${SIGNUP_ENABLED} = false ]]; then
#  echo "===> Update default admin account"
#  mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'local_db_enabled', 'True') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'local_db_enabled') LIMIT 1;"
#  mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'signup_enabled', '${SIGNUP_ENABLED}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'signup_enabled') LIMIT 1;"
#  mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "INSERT INTO user (username, password, firstname, lastname, email, avatar, otp_secret) SELECT * FROM (SELECT '${ADMIN_USER}' as username, '${ADMIN_USER_PASSWORD_HASHED}' as password, 'admin' as firstname, 'admin' as lastname, 'admin@example.com' as email, NULL as avatar, NULL as otp_secret) AS tmp WHERE NOT EXISTS (SELECT username FROM user WHERE username = '${ADMIN_USER}') LIMIT 1;"
#fi

# Update pdns api setting if environment variable is changed.
mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "UPDATE setting SET value='${PDNS_PROTO}://${PDNS_HOST}:${PDNS_PORT}' WHERE name='pdns_api_url';"
mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "UPDATE setting SET value='${PDNS_API_KEY}' WHERE name='pdns_api_key';"
mysql -h${SQLA_DB_HOST} -u${SQLA_DB_USER} -p${SQLA_DB_PASSWORD} -P${SQLA_DB_PORT} ${SQLA_DB_NAME} -e "UPDATE setting SET value='${PDNS_VERSION}' WHERE name='pdns_version';"


GUNICORN_ARGS="-t ${GUNICORN_TIMEOUT} --workers ${GUNICORN_WORKERS} --bind ${BIND_ADDRESS}:${PORT} --log-level ${LOG_LEVEL}"
if [ "$1" == gunicorn ]; then
    exec "$@" $GUNICORN_ARGS
else
    exec "$@"
fi
