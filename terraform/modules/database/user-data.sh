#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y wget curl ca-certificates gnupg lsb-release software-properties-common

# Install PostgreSQL 14 from the official PostgreSQL repo
mkdir -p /etc/apt/keyrings
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg
cat >/etc/apt/sources.list.d/pgdg.list <<EOF
# PostgreSQL repository

deb [signed-by=/etc/apt/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main
EOF

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-14 postgresql-contrib-14 postgresql-client-14

systemctl enable postgresql
systemctl start postgresql

DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"

runuser -u postgres -- psql -v ON_ERROR_STOP=1 -v dbname="$DB_NAME" -v dbuser="$DB_USER" -v dbpass="$DB_PASSWORD" <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'dbuser') THEN
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', :'dbuser', :'dbpass');
  ELSE
    EXECUTE format('ALTER USER %I WITH PASSWORD %L', :'dbuser', :'dbpass');
  END IF;
END $$;
SQL

if ! runuser -u postgres -- psql -v ON_ERROR_STOP=1 -v dbname="$DB_NAME" -Atqc "SELECT 1 FROM pg_database WHERE datname = :'dbname';" | grep -q 1; then
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 -v dbname="$DB_NAME" -v dbuser="$DB_USER" <<'SQL'
SELECT format('CREATE DATABASE %I OWNER %I', :'dbname', :'dbuser') \gexec
SQL
fi

runuser -u postgres -- psql -d "$DB_NAME" -c "ALTER USER $DB_USER WITH SUPERUSER;"
runuser -u postgres -- psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

PG_HBA=$(runuser -u postgres -- psql -tAc "SHOW hba_file")
PG_CONF=$(runuser -u postgres -- psql -tAc "SHOW config_file")

if ! grep -q "$DB_NAME.*$DB_USER" "$PG_HBA"; then
  echo "host    $DB_NAME    $DB_USER    10.0.0.0/8    md5" >> "$PG_HBA"
  echo "host    $DB_NAME    $DB_USER    127.0.0.1/32    md5" >> "$PG_HBA"
  echo "host    all         all         10.0.0.0/8    md5" >> "$PG_HBA"
  echo "local   $DB_NAME    $DB_USER    md5" >> "$PG_HBA"
fi

if ! grep -q "listen_addresses" "$PG_CONF"; then
  echo "listen_addresses = '*'" >> "$PG_CONF"
else
  sed -i "s/^#listen_addresses.*/listen_addresses = '*' /" "$PG_CONF" || true
  sed -i "s/^listen_addresses.*/listen_addresses = '*' /" "$PG_CONF" || true
fi

if ! runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_roles WHERE rolname = 'ubuntu'" | grep -q 1; then
  runuser -u postgres -- psql -v ON_ERROR_STOP=1 <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ubuntu') THEN
    CREATE ROLE ubuntu LOGIN;
  END IF;
END $$;
SQL
fi

systemctl restart postgresql

export PGPASSWORD="$DB_PASSWORD"
psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;"
