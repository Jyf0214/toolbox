#!/bin/bash
set -e
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
PROC_CONFIG_URL="$BASE_URL/proc_config.ini"
FRPC_URL="https://www.chmlfrp.cn/dw/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz"
DATA_DIR="/home/appuser/data"
LOG_DIR="/var/log/service_manager"
useradd -m -d /home/appuser -s /bin/bash appuser
mkdir -p /app /opt/tunnel /opt/openlist/data "${LOG_DIR}" "${DATA_DIR}" /home/appuser/backup
chown -R appuser:appuser /home/appuser /app /opt/tunnel /opt/openlist/data "${LOG_DIR}"
wget -q -O /etc/proc_config.ini "$PROC_CONFIG_URL"
git clone --depth=1 --branch "${GIT_BRANCH}" "${GIT_REPO}" /app/static
rm -rf /app/static/.git
chown -R appuser:appuser /app/static
curl -fsSL http://bash.skadi.kozow.com/scripts/update_openlist.sh | bash
wget -q -O /tmp/tunnel_client.tar.gz "$FRPC_URL"
tar --no-same-owner --strip-components=1 -xzf /tmp/tunnel_client.tar.gz -C /opt/tunnel/
chmod +x /opt/tunnel/frpc
rm /tmp/tunnel_client.tar.gz
chown -R appuser:appuser /opt/tunnel
mkdir -p /home/appuser/.config/rclone
cat << EOF > /home/appuser/.config/rclone/rclone.conf.template
[b2]
type = b2
account = \${B2_ACCOUNT_ID}
key = \${B2_ACCOUNT_KEY}
endpoint = https://\${B2_ENDPOINT}
EOF
chown -R appuser:appuser /home/appuser/.config