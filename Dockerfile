FROM ubuntu:18.04 as builder

# Install some required packages
RUN apt-get update -y && \
    apt-get install -y git

# Get the latest source from the master branch
RUN git clone https://github.com/ngoduykhanh/PowerDNS-Admin.git /powerdns-admin/

# Use a clean base image for the final delivery of the application
FROM ubuntu:18.04

LABEL maintainer="Philip Schmid <docker@ins.hsr.ch>"

# Switch the working directory to /powerdns-admin
WORKDIR /powerdns-admin

# Only copy the required files to the final image
COPY --from=builder /powerdns-admin/config_template.py ./config.py
COPY --from=builder /powerdns-admin/app/ ./app/
COPY --from=builder /powerdns-admin/migrations/ ./migrations/
COPY --from=builder /powerdns-admin/LICENSE .
COPY --from=builder /powerdns-admin/package.json .
COPY --from=builder /powerdns-admin/requirements.txt .
COPY --from=builder /powerdns-admin/run.py .
COPY --from=builder /powerdns-admin/.yarnrc .
COPY --from=builder /powerdns-admin/init_data.py .

# Install curl which is used to download node/yarn related APT repository stuff
RUN apt-get update -y && \
    apt-get install -y \
      curl \
      apt-transport-https \
      gnupg2 \
    && apt-get clean -y \
  	&& rm -rf /var/lib/apt/lists/*

# Add node repository and install nodejs, yarn
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# Install the required packages. Netcat is only required for DB healthchecks.
RUN apt-get update -y && \
    apt-get install -y \
      locales \
      locales-all \
      python3-pip \
      python3-dev \
      mysql-client \
      netcat \
      yarn \
      nodejs \
      libmysqlclient-dev \
      libsasl2-dev \
      libldap2-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      libxmlsec1-dev \
      libffi-dev \
      pkg-config \
    && apt-get clean -y \
  	&& rm -rf /var/lib/apt/lists/*

ENV LC_ALL=en_US.UTF-8 \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US.UTF-8

# Ensure the node_modules, logs and upload directory are present
RUN mkdir -p /powerdns-admin/node_modules \
  /powerdns-admin/logs \
  /powerdns-admin/upload/avatar

# Install all dependencies
RUN pip3 install -r requirements.txt
RUN yarn install --pure-lockfile
RUN flask assets build

# Fix the permissions
RUN chown -R www-data:www-data /powerdns-admin/

# Set some default values into the default config.py file.
# The SALT is only added because it is used by PowerDNS-Admin
# (see https://github.com/ngoduykhanh/PowerDNS-Admin/blob/dfce7eb5379552bf35da1c936857bd1ff2dd664d/app/models.py#L2310).
# Fortunately this image does not use a static salt for the first admin user when its created via ADMIN_USER and ADMIN_PASSWORD.
RUN sed -i "s|SECRET_KEY =.*|SECRET_KEY = os.environ.get('SECRET_KEY', 'MyAwesomeSecretKey')|g" /powerdns-admin/config.py && \
  sed -i "s|BIND_ADDRESS =.*|BIND_ADDRESS = os.environ.get('BIND_ADDRESS', '0.0.0.0')|g" /powerdns-admin/config.py && \
  sed -i "s|PORT =.*|PORT = os.environ.get('PORT', '9191')|g" /powerdns-admin/config.py && \
  sed -i "s|LOG_LEVEL =.*|LOG_LEVEL = os.environ.get('LOG_LEVEL', 'info')|g" /powerdns-admin/config.py && \
  sed -i "s|SQLA_DB_USER =.*|SQLA_DB_USER = os.environ.get('SQLA_DB_USER', 'powerdns-svc-user')|g" /powerdns-admin/config.py && \
  sed -i "s|SQLA_DB_PASSWORD =.*|SQLA_DB_PASSWORD = os.environ.get('SQLA_DB_PASSWORD', 'powerdns-svc-user-pw')|g" /powerdns-admin/config.py && \
  sed -i "s|SQLA_DB_HOST =.*|SQLA_DB_HOST = os.environ.get('SQLA_DB_HOST', 'powerdns-admin-mysql')|g" /powerdns-admin/config.py && \
  sed -i "s|SQLA_DB_PORT =.*|SQLA_DB_PORT = os.environ.get('SQLA_DB_PORT', '3306')|g" /powerdns-admin/config.py && \
  sed -i "s|SQLA_DB_NAME =.*|SQLA_DB_NAME = os.environ.get('SQLA_DB_NAME', 'powerdns-admin')|g" /powerdns-admin/config.py && \
  sed -i "s|LOG_FILE =.*|LOG_FILE = ''|g" /powerdns-admin/config.py && \
  sed -i "s|SALT =.*|SALT = '$2b$12$yLUMTIfl21FKJQpTkRQXCu'|g" /powerdns-admin/config.py

# Copy the entrypoint script to the image and make is executable
COPY entrypoint.sh /powerdns-admin/entrypoint.sh
RUN chmod 755 /powerdns-admin/entrypoint.sh

# Drop permissions
USER www-data

# Configure the app startup
ENV FLASK_APP=app/__init__.py
EXPOSE 9191/tcp
ENTRYPOINT ["/powerdns-admin/entrypoint.sh"]
CMD ["gunicorn","app:app"]
