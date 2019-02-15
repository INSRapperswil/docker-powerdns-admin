FROM ubuntu:18.04

LABEL maintainer="Philip Schmid <docker@ins.hsr.ch>"

# Chose the development example config.py file if no other is specified
ARG ENVIRONMENT=development
ENV ENVIRONMENT=${ENVIRONMENT}

# Install some required packages
RUN apt-get update -y && \
    apt-get install -y \
      apt-transport-https \
      curl \
      gnupg2 \
      git

# Add node and yarn repositories
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# Install the required packages
RUN apt-get update -y && \
    apt-get install -y \
      locales \
      locales-all \
      python3-pip \
      python3-dev \
      supervisor \
      mysql-client \
      yarn \
      netcat \
      libmysqlclient-dev \
      libsasl2-dev \
      libldap2-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      libxmlsec1-dev \
      libffi-dev \
      pkg-config \
      nodejs

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN git clone https://github.com/ngoduykhanh/PowerDNS-Admin.git /powerdns-admin/

WORKDIR /powerdns-admin

# Install all dependencies
RUN pip3 install -r requirements.txt

# Copy the supervisord.conf to the default location
RUN cp ./supervisord.conf /etc/supervisord.conf

# Set some default values into the default config.py file
RUN cp ./configs/${ENVIRONMENT}.py /powerdns-admin/config.py && \
  sed -i "s|SECRET_KEY =.*|SECRET_KEY = 'SuperSecretDefaultPassword'|g" /powerdns-admin/config.py; \
  sed -i "s|LOG_LEVEL = 'DEBUG'|LOG_LEVEL = 'INFO'|g" /powerdns-admin/config.py; \
  sed -i "s|LOG_FILE = 'logfile.log'|LOG_FILE = ''|g" /powerdns-admin/config.py; \
  sed -i "s|SIGNUP_ENABLED = True|SIGNUP_ENABLED = False|g" /powerdns-admin/config.py

# Announce which ports are exposed
EXPOSE 9191

# Ensure the Docker entrypoint script is executable
RUN chmod +x /powerdns-admin/docker/PowerDNS-Admin/entrypoint.sh

# Configure the default entrypoint
ENTRYPOINT ["/powerdns-admin/docker/PowerDNS-Admin/entrypoint.sh"]
