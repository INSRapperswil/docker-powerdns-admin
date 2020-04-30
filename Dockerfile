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
COPY --from=builder /powerdns-admin/powerdnsadmin/ ./powerdnsadmin/
COPY --from=builder /powerdns-admin/migrations/ ./migrations/
COPY --from=builder /powerdns-admin/LICENSE .
COPY --from=builder /powerdns-admin/package.json .
COPY --from=builder /powerdns-admin/requirements.txt .
COPY --from=builder /powerdns-admin/run.py .
COPY --from=builder /powerdns-admin/.yarnrc .
COPY --from=builder /powerdns-admin/update_zones.py .

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
  LANGUAGE=en_US.UTF-8 \
  FLASK_APP=/powerdns-admin/powerdnsadmin/__init__.py

# Ensure the node_modules, logs and upload directory are present
RUN mkdir -p /powerdns-admin/node_modules \
  /powerdns-admin/logs \
  /powerdns-admin/upload/avatar

# Install all dependencies
RUN pip3 install -r requirements.txt
RUN yarn install --pure-lockfile
RUN flask assets build

COPY docker_config.py /powerdns-admin/powerdnsadmin/docker_config.py

# Fix the permissions
RUN chown -R www-data:www-data /powerdns-admin/

# Copy the entrypoint script to the image and make is executable
COPY entrypoint.sh /powerdns-admin/entrypoint.sh
RUN chmod 755 /powerdns-admin/entrypoint.sh

# Drop permissions
USER www-data

# Configure the app startup
EXPOSE 9191/tcp

ENTRYPOINT ["/powerdns-admin/entrypoint.sh"]
CMD ["gunicorn","powerdnsadmin:create_app()","--user","www-data","--group","www-data"]
