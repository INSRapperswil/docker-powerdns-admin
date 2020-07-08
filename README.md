# PowerDNS Admin Web UI
Dockerized version of https://github.com/ngoduykhanh/PowerDNS-Admin.

The prebuilt Docker image can be found here: https://hub.docker.com/r/hsrnetwork/powerdns-admin

## Why this Docker
Unfortunately PowerDNS-Admin does not offer a clean and especially easy way to configure a dockerized version of it's awsome software. There are some attempts (e.g. https://github.com/ngoduykhanh/PowerDNS-Admin/pull/535) to achieve this but to be honest it's still not what we would call an "easy to configure" Docker image. That's mainly because of the software itself which does not allow an easy configuration of some settings like PDNS API and local authentication. We chose to inject these settings via Docker environment variables directly into the PowerDNS-Admin database and therefore allow a staight forward configuration (even though it's kind of hacky) - PowerDNS-Admin forces us to do so.

## Prerequisites
**Important**: Ensure all environment vaiables of the services inside the `docker-compose.yml` file are set according to your needs. If you run an aleady existing PowerDNS instance, just remove the `pdns-server` and `pdns-server-mysql` service from the `docker-compose.yml` file and point the `powerdns-admin` service to your PowerDNS instance. See in the chapters below to get an overview of all possible configuraiton environment variables.

### DB Configuartion
See inside the official `mysql/mysql-server` `docker-entrypoint.sh` file to check which environment variables are available to configure the mysql containers (https://github.com/mysql/mysql-docker/blob/mysql-server/8.0/docker-entrypoint.sh).

To configure the DB connection for PowerDNS-Admin use the following environment variables:
```bash
SQLA_DB_HOST: powerdns-admin-mysql
SQLA_DB_NAME: powerdns-admin
SQLA_DB_USER: powerdns-admin-svc-user
SQLA_DB_PASSWORD: powerdns-admin-svc-user-pw
SQLA_DB_PORT: 3306
```
**Important:** The values shown here are the defaults of this Docker image.

### PDNS
Set the following environment variables to configure the connection to the PowerDNS:
```bash
PDNS_HOST: pdns-server
PDNS_API_KEY: changeme
PDNS_PORT: 8081
PDNS_VERSION: 4.1.10
PDNS_PROTO: http
```
**Important:** The values shown here are the defaults of this Docker image.

### User Management
You must set `SIGNUP_ENABLED` to `True` if you do **not** like to automatically create a service user. Otherwise the default behaviour of this Docker image is to set `SIGNUP_ENABLED` to `False` which means if you do not override the environment variables, the default credentials will be the following ones:

```bash
ADMIN_USER: admin
ADMIN_USER_PASSWORD: 12345
```

**Important:** Do not use `SIGNUP_ENABLED: True` and `ADMIN_USER: XXX`/`ADMIN_USER_PASSWORD: XXX` at the same time. The admin user will not be created and instead the first user you are going to create via WebUI will be assigned to the `Administrator` role.

### Log Level
Change the `LOG_LEVEL` if you would like to change the log servity. The default is `info`.

### Gunicorn Settings
It's possible to change the `gunicorn` worker number and timeout by setting:
```bash
GUNICORN_WORKERS: 4
GUINCORN_TIMEOUT: 120
```
**Important:** The values shown here are the defaults of this Docker image.

## Configuration Example
The following examples should provide you an overview which environment variables are available to configure the service with Docker environment variables.

### Recommended Minimum Configuration
```yaml
environment:
  ADMIN_USER: admin
  ADMIN_USER_PASSWORD: 12345
  SECRET_KEY: <generate-and-insert-a-random-key-string-here>
  SALT: <generate-bcrypt-salt-and-insert-here>
  LOG_LEVEL: INFO
  SQLA_DB_HOST: powerdns-admin-mysql
  SQLA_DB_NAME: powerdns-admin
  SQLA_DB_USER: powerdns-admin-svc-user
  SQLA_DB_PASSWORD: powerdns-admin-svc-user-pw
  PDNS_HOST: pdns-server
  PDNS_API_KEY: changeme
  PDNS_VERSION: 4.1.10
```

### All Possible Configurations
```yaml
environment:
  # Use the capital letter "F"/"T" for "False"/"True" (limitation of PowerDNS-Admin)
  SIGNUP_ENABLED: 'False'
  ADMIN_USER: admin
  ADMIN_USER_PASSWORD: 12345
  SECRET_KEY: <generate-and-insert-a-random-key-string-here>
  # Escape the "$" with an additional "$": SALT: '$$2b$$12$$m3g0pU8pdc4pGcgqKeFZOO'
  SALT: <generate-bcrypt-salt-and-insert-here>
  BIND_ADDRESS: 0.0.0.0
  PORT: 80
  GUINCORN_TIMEOUT: 120
  GUNICORN_WORKERS: 4
  LOG_LEVEL: INFO
  SQLA_DB_HOST: powerdns-admin-mysql
  SQLA_DB_NAME: powerdns-admin
  SQLA_DB_USER: powerdns-admin-svc-user
  SQLA_DB_PASSWORD: powerdns-admin-svc-user-pw
  SQLA_DB_PORT: 3306
  PDNS_HOST: pdns-server
  PDNS_API_KEY: changeme
  PDNS_PORT: 8081
  PDNS_VERSION: 4.1.10
  PDNS_PROTO: http
```

## Getting Started
```bash
docker-compose up -d
```
