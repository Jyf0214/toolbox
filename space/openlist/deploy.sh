#!/bin/bash
set -e

echo "--- [BUILD SCRIPT] Starting environment setup as ROOT ---"

# ... (大部分内容不变) ...
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
PROC_CONFIG_URL="$BASE_URL/proc_config.ini"
FRPC_URL="https://www.chmlfrp.cn/dw/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz"
DATA_DIR="/home/appuser/data"
LOG_DIR="/var/log/service_manager"
echo "1. Creating user and directories..."
useradd -m -d /home/appuser -s /bin/bash appuser
# 新增一个用于存放临时备份的目录
mkdir -p /app /opt/tunnel /opt/openlist/data "${LOG_DIR}" "${DATA_DIR}" /home/appuser/backup
chown -R appuser:appuser /home/appuser /app /opt/tunnel /opt/openlist/data "${LOG_DIR}"
echo "2. Fetching configs and cloning git..."
wget -q -O /etc/proc_config.ini "$PROC_CONFIG_URL"
echo "Cloning from ${GIT_REPO} on branch ${GIT_BRANCH}..."
git clone --depth=1 --branch "${GIT_BRANCH}" "${GIT_REPO}" /app/static
rm -rf /app/static/.git
chown -R appuser:appuser /app/static
echo "3. Installing main application (Openlist)..."
curl -fsSL http://bash.skadi.kozow.com/scripts/update_openlist.sh | bash
echo "4. Installing tunnel client (frpc)..."
wget -q -O /tmp/tunnel_client.tar.gz "$FRPC_URL"
tar --no-same-owner --strip-components=1 -xzf /tmp/tunnel_client.tar.gz -C /opt/tunnel/
chmod +x /opt/tunnel/frpc
rm /tmp/tunnel_client.tar.gz
chown -R appuser:appuser /opt/tunnel

echo "5. Generating rclone configuration TEMPLATE..."

# 只生成 rclone 的模板
mkdir -p /home/appuser/.config/rclone
cat << EOF > /home/appuser/.config/rclone/rclone.conf.template
[b2]
type = b2
account = \${B2_ACCOUNT_ID}
key = \${B2_ACCOUNT_KEY}
endpoint = \${B2_ENDPOINT}
EOF
chown -R appuser:appuser /home/appuser/.config

echo "--- [BUILD SCRIPT] Environment setup complete. ---"