# PowerDNS Admin Web UI
Dockerized version of https://github.com/ngoduykhanh/PowerDNS-Admin

## Prerequisites
**Important**: Ensure all environment vaiables of the services inside the `docker-compose.yml` file are set according to your needs. If you run an aleady existing PowerDNS instance, just remove the `pdns-server` and `pdns-server-mysql` service from the `docker-compose.yml` file and point the `powerdns-admin` service to your PowerDNS instance.

## Usage
**Note**: The default password of this image is `SuperSecretDefaultPassword`.

## Getting Started
```bash
docker-compose up -d
```
