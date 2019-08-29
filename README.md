# PowerDNS Admin Web UI
Dockerized version of https://github.com/ngoduykhanh/PowerDNS-Admin

## Prerequisites
**Important**: Ensure all environment vaiables of the services inside the `docker-compose.yml` file are set according to your needs. If you run an aleady existing PowerDNS instance, just remove the `pdns-server` and `pdns-server-mysql` service from the `docker-compose.yml` file and point the `powerdns-admin` service to your PowerDNS instance.

## Usage
**Note**: The default password of this image is `SuperSecretDefaultPassword`.

## DB Configuartion
See inside the official `mysql/mysql-server` `docker-entrypoint.sh` file to check which environment variables are available to configure the mysql containers (https://github.com/mysql/mysql-docker/blob/mysql-server/8.0/docker-entrypoint.sh).

## Getting Started
```bash
docker-compose up -d
```
