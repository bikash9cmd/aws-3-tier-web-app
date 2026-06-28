#!/bin/bash
set -euo pipefail

# ─── System Updates ───────────────────────────
yum update -y
yum install -y nodejs npm git aws-cli

# ─── App Directory ────────────────────────────
mkdir -p /opt/app
cd /opt/app

# ─── Pull app from S3 ─────────────────────────
aws s3 cp s3://${s3_bucket_name}/app.tar.gz /opt/app.tar.gz || true

if [ -f /opt/app.tar.gz ]; then
  tar -xzf /opt/app.tar.gz -C /opt/app
else
  # Fallback: create a minimal health check app
  cat > /opt/app/server.js << 'EOF'
const http = require('http');
const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', tier: 'application' }));
  } else {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end('<h1>3-Tier App – Application Tier Running</h1>');
  }
});
server.listen(3000, () => console.log('App listening on port 3000'));
EOF
fi

# ─── Environment Variables ────────────────────
cat > /opt/app/.env << EOF
DB_HOST=${db_endpoint}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=$(aws ssm get-parameter --name "/${db_name}/db_password" --with-decryption --query Parameter.Value --output text 2>/dev/null || echo "")
PORT=3000
NODE_ENV=production
S3_BUCKET=${s3_bucket_name}
EOF

# ─── Install Dependencies ─────────────────────
cd /opt/app
if [ -f package.json ]; then
  npm install --production
fi

# ─── Systemd Service ──────────────────────────
cat > /etc/systemd/system/app.service << 'UNIT'
[Unit]
Description=3-Tier Node.js Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/.env
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=3tier-app

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable app
systemctl start app

echo "✅ App deployed and running on port 3000"
