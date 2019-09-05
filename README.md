# PowerDNS Admin Web UI
Dockerized version of https://github.com/ngoduykhanh/PowerDNS-Admin.

## Why this Docker
Unfortunately PowerDNS-Admin does not offer a clean and especially easy way to configure a dockerized version of its awsome software. There are some attempts (e.g. https://github.com/ngoduykhanh/PowerDNS-Admin/pull/535) to achieve this but to be honest its still not what we would call "easy to configure" Docker image. That's mainly because of the software itself does not allow an easy configuration of some settings like PDNS API and local authentication. We chose to inject these settings via Docker environment variables directly into the PowerDNS-Admin database and therefore allow a staight forward configuration.

## Prerequisites
**Important**: Ensure all environment vaiables of the services inside the `docker-compose.yml` file are set according to your needs. If you run an aleady existing PowerDNS instance, just remove the `pdns-server` and `pdns-server-mysql` service from the `docker-compose.yml` file and point the `powerdns-admin` service to your PowerDNS instance.

### DB Configuartion
See inside the official `mysql/mysql-server` `docker-entrypoint.sh` file to check which environment variables are available to configure the mysql containers (https://github.com/mysql/mysql-docker/blob/mysql-server/8.0/docker-entrypoint.sh).

To configure the DB connection for PowerDNS use the following environment variables:
```bash
SQLA_DB_HOST: powerdns-admin-mysql
SQLA_DB_NAME: powerdns-admin
SQLA_DB_USER: powerdns-admin-svc-user
SQLA_DB_PASSWORD: powerdns-admin-svc-user-pw
SQLA_DB_PORT: 3306
```
**Impotant:** The values shown here are the defaults of this Docker image.

### PDNS
Set the following environment variables to configure the connection to the PowerDNS:
```bash
PDNS_HOST: pdns-server
PDNS_API_KEY: changeme
PDNS_PORT: 8081
PDNS_VERSION: 4.1.1
PDNS_PROTO: http
```
**Impotant:** The values shown here are the defaults of this Docker image.

### User Management
You must set `SIGNUP_ENABLED` to `true` if you do **not** like to automatically create a service user. Otherwise the default behaviour of this Docker image is to set `SIGNUP_ENABLED` to `false` which means if you do not override the environment variables, the default credentials will be th following ones:

```bash
ADMIN_USER:  admin
ADMIN_USER_PASSWORD: 12345
```

### Debug
Change the `LOG_LEVEL` if you would like to change the log servity. The default is `info`.

### `gunicorn` Settings
Its possible to change the `gunicorn` worker number and timeout by setting:
```bash
GUNICORN_WORKERS: 4
GUINCORN_TIMEOUT: 120
```
**Impotant:** The values shown here are the defaults of this Docker image.

## Getting Started
```bash
docker-compose up -d
```
