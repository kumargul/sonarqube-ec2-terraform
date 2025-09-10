#!/bin/bash
# SonarQube Ubuntu EC2 Full Install Script
# Adjust values as needed for user/database/password/domain/etc.

set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

apt update
apt install -y awscli

# --- Variables (edit as needed) ---
SONAR_VERSION="25.9.0.112764"
SONAR_ZIP="sonarqube-${SONAR_VERSION}.zip"
SONAR_USER="ddsonar"
SONAR_GROUP="ddsonar"
SONAR_HOME="/opt/sonarqube"
SONAR_DB="ddsonarqube"
SONAR_DB_USER="ddsonar"
SONAR_DB_PASS="$(aws ssm get-parameter --name "/sonarqube/db_password" --with-decryption --region ap-southeast-2 --query 'Parameter.Value' --output text)"
DOMAIN="sonarqube.testgk$(echo $RANDOM).com" # For nginx step

# --- 1. System Update ---
apt update
apt upgrade -y

# --- 2. Java 17 Install ---
apt install -y openjdk-17-jdk

# --- 3. PostgreSQL Install ---
sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt update
apt install -y postgresql postgresql-contrib

systemctl enable postgresql
systemctl start postgresql

# --- 3a. Create SonarQube DB/User (psql commands) ---
sudo -u postgres psql <<EOF
CREATE USER $SONAR_DB_USER WITH ENCRYPTED PASSWORD '$SONAR_DB_PASS';
CREATE DATABASE $SONAR_DB OWNER $SONAR_DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $SONAR_DB TO $SONAR_DB_USER;
EOF

# --- 4. Download SonarQube and prepare dirs ---
apt install -y zip unzip wget
wget https://binaries.sonarsource.com/Distribution/sonarqube/${SONAR_ZIP}
unzip $SONAR_ZIP
mv sonarqube-${SONAR_VERSION} $SONAR_HOME
rm $SONAR_ZIP

# --- 5. Set up user and permissions ---
groupadd --force $SONAR_GROUP
useradd -d $SONAR_HOME -g $SONAR_GROUP $SONAR_USER || true
chown -R $SONAR_USER:$SONAR_GROUP $SONAR_HOME

# --- 6. Configure SonarQube DB connection ---
SONAR_PROP="$SONAR_HOME/conf/sonar.properties"
sed -i "s|#sonar.jdbc.username=.*|sonar.jdbc.username=${SONAR_DB_USER}|" $SONAR_PROP
sed -i "s|#sonar.jdbc.password=.*|sonar.jdbc.password=${SONAR_DB_PASS}|" $SONAR_PROP
sed -i "/sonar.jdbc.password/a sonar.jdbc.url=jdbc:postgresql://localhost:5432/${SONAR_DB}" $SONAR_PROP

# --- 7. Enforce SonarQube runs as its user ---
echo "RUN_AS_USER=$SONAR_USER" | tee -a "$SONAR_HOME/bin/linux-x86-64/sonar.sh"

# --- 8. Systemd Service ---
bash -c "cat > /etc/systemd/system/sonar.service" <<EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=$SONAR_HOME/bin/linux-x86-64/sonar.sh start
ExecStop=$SONAR_HOME/bin/linux-x86-64/sonar.sh stop
User=$SONAR_USER
Group=$SONAR_GROUP
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

systemctl enable sonar
systemctl start sonar

# --- 9. System Limits ---
bash -c "cat >> /etc/sysctl.conf" <<EOF
vm.max_map_count=262144
fs.file-max=65536
EOF

bash -c "cat >> /etc/security/limits.conf" <<EOF
$SONAR_USER   -   nofile   65536
$SONAR_USER   -   nproc    4096
EOF

sysctl -p

# --- 10. Nginx Reverse Proxy (optional) ---
# apt install -y nginx

# bash -c "cat > /etc/nginx/sites-enabled/sonarqube" <<EOF
# server {
#     listen 80;
#     server_name $DOMAIN;

#     location / {
#         proxy_pass http://127.0.0.1:9000;
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#     }
# }
# EOF

# nginx -t
# systemctl enable nginx
# systemctl restart nginx

# --- 11. Certbot SSL (optional) ---
# snap install --classic certbot
# certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m your@email.com

echo "Installation finished! Visit http://$DOMAIN or your server's IP:9000"

# --- Suggestions & Notes ---
# - Update variables at top for your environment (especially DB password and domain).
# - The script assumes new VM and default ports/users. For production, further hardening is recommended.
# - For PostgreSQL tuning, add CONFIG tuning as suited to your instance type/load.
# - Change certbot flags for interactive email/renewal management.
