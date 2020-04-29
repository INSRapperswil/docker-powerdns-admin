import os
basedir = os.path.abspath(os.path.abspath(os.path.dirname(__file__)))

### BASIC APP CONFIG
SALT = os.environ.get('SALT', '$2b$12$yLUMTIfl21FKJQpTkRQXCu')
SECRET_KEY = os.environ.get('SECRET_KEY', 'MyAwesomeSecretKey')
BIND_ADDRESS = os.environ.get('BIND_ADDRESS', '0.0.0.0')
PORT = os.environ.get('PORT', '9191')
HSTS_ENABLED = False

LOG_LEVEL = os.environ.get('LOG_LEVEL', 'info')
LOG_FILE = ''

### DATABASE CONFIG
SQLA_DB_USER = os.environ.get('SQLA_DB_USER', 'powerdns-svc-user')
SQLA_DB_PASSWORD = os.environ.get('SQLA_DB_PASSWORD', 'powerdns-svc-user-pw')
SQLA_DB_HOST = os.environ.get('SQLA_DB_HOST', 'powerdns-admin-mysql')
SQLA_DB_PORT = os.environ.get('SQLA_DB_PORT', '3306')
SQLA_DB_NAME = os.environ.get('SQLA_DB_NAME', 'powerdns-admin')
SQLALCHEMY_TRACK_MODIFICATIONS = True

### DATBASE - MySQL
SQLALCHEMY_DATABASE_URI = 'mysql://'+SQLA_DB_USER+':'+SQLA_DB_PASSWORD+'@'+SQLA_DB_HOST+':'+SQLA_DB_PORT+'/'+SQLA_DB_NAME

### DATABSE - SQLite
# SQLALCHEMY_DATABASE_URI = 'sqlite:///' + os.path.join(basedir, 'pdns.db')

# SAML Authnetication
SAML_ENABLED = False
SAML_ASSERTION_ENCRYPTED = True