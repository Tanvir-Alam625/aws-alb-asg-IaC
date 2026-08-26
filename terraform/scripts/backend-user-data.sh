#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

APP_DIR="/home/ubuntu/bmi-health-tracker-ec2-server"
DOMAIN="${domain_name}"
DB_NAME="${database_name}"
DB_USER="${database_user}"
DB_PASSWORD="${database_password}"
DB_HOST="127.0.0.1"
APP_PORT="${app_port}"
REPO_URL="${repo_url}"
REPO_BRANCH="${repo_branch}"
CLOUDFLARE_CERT="${cloudflare_cert_content}"
CLOUDFLARE_KEY="${cloudflare_key_content}"

mkdir -p /home/ubuntu
chmod 755 /home/ubuntu

apt-get update
apt-get install -y git curl ca-certificates build-essential jq nginx postgresql postgresql-contrib awscli

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" fetch --all --tags || true
  git -C "$APP_DIR" checkout "$REPO_BRANCH" || git -C "$APP_DIR" checkout -B "$REPO_BRANCH" "origin/$REPO_BRANCH" || true
  git -C "$APP_DIR" pull --ff-only origin "$REPO_BRANCH" || true
else
  rm -rf "$APP_DIR"
  git clone --branch "$REPO_BRANCH" --single-branch "$REPO_URL" "$APP_DIR"
fi

BACKEND_DIR=""
FRONTEND_DIR=""
for candidate in "$APP_DIR/backend" "$APP_DIR/server" "$APP_DIR/app/backend" "$APP_DIR/app/server"; do
  if [ -d "$candidate" ] && [ -f "$candidate/package.json" ]; then
    BACKEND_DIR="$candidate"
    break
  fi
done

for candidate in "$APP_DIR/frontend" "$APP_DIR/client" "$APP_DIR/app/frontend" "$APP_DIR/app/client"; do
  if [ -d "$candidate" ] && [ -f "$candidate/package.json" ]; then
    FRONTEND_DIR="$candidate"
    break
  fi
done

if [ -z "$BACKEND_DIR" ] && [ -f "$APP_DIR/package.json" ]; then
  BACKEND_DIR="$APP_DIR"
fi

if [ -z "$FRONTEND_DIR" ] && [ -f "$APP_DIR/package.json" ] && [ -n "$BACKEND_DIR" ] && [ "$BACKEND_DIR" != "$APP_DIR" ]; then
  FRONTEND_DIR="$APP_DIR"
fi

if [ -z "$BACKEND_DIR" ] || [ ! -f "$BACKEND_DIR/package.json" ]; then
  echo "Backend project not found. Checked possible paths under $APP_DIR" >&2
  find "$APP_DIR" -maxdepth 3 -type f -name package.json 2>/dev/null || true
  exit 1
fi

if [ -z "$FRONTEND_DIR" ] || [ ! -f "$FRONTEND_DIR/package.json" ]; then
  echo "Frontend project not found. Checked possible paths under $APP_DIR" >&2
  find "$APP_DIR" -maxdepth 3 -type f -name package.json 2>/dev/null || true
  exit 1
fi

cat > "$BACKEND_DIR/.env" <<EOF
NODE_ENV=production
PORT=$APP_PORT
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME
FRONTEND_URL=https://$DOMAIN
DB_POOL_SIZE=20
EOF
chmod 600 "$BACKEND_DIR/.env"

cd "$BACKEND_DIR"
npm install --no-audit --no-fund

cd "$FRONTEND_DIR"
npm install --no-audit --no-fund
npm run build

sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || \
  sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || \
  sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

sudo -u postgres psql -v ON_ERROR_STOP=1 -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

if [ -f "$APP_DIR/database/migrations/001_create_measurements.sql" ]; then
  PGPASSWORD="$DB_PASSWORD" psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -f "$APP_DIR/database/migrations/001_create_measurements.sql"
fi

cat > /etc/systemd/system/bmi-backend.service <<EOF
[Unit]
Description=BMI Health Tracker Backend
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$BACKEND_DIR
EnvironmentFile=$BACKEND_DIR/.env
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=5
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable bmi-backend
systemctl start bmi-backend

HEALTH_OK=0
for i in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:$APP_PORT/health" | grep -q '"status":"ok"'; then
    echo "Backend health check passed"
    HEALTH_OK=1
    break
  fi
  echo "Waiting for backend health on port $APP_PORT... $i/60"
  sleep 5
done

if [ "$HEALTH_OK" -ne 1 ]; then
  echo "Backend did not become healthy in time" >&2
  systemctl status bmi-backend --no-pager || true
  journalctl -u bmi-backend --no-pager -n 80 || true
  exit 1
fi

cat > /etc/nginx/sites-available/bmi-health.conf <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    client_max_body_size 20M;

    location /api/ {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
    }

    location /health {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
    }

    location / {
        root $FRONTEND_DIR/dist;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/bmi-health.conf /etc/nginx/sites-enabled/bmi-health.conf
nginx -t
systemctl enable nginx
systemctl restart nginx

curl -fsS "http://127.0.0.1/health" || true
curl -fsS "http://127.0.0.1/api/measurements?limit=1" || true

echo "Deployment script completed successfully"
