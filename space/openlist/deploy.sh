#!/bin/bash
set -e

echo "--- [BUILD SCRIPT] Starting environment setup as ROOT ---"

# --- 配置 ---
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
PROC_CONFIG_URL="$BASE_URL/proc_config.ini"
FRPC_URL="https://www.chmlfrp.cn/dw/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz"
DATA_DIR="/home/appuser/data"

echo "1. Creating user and directories..."
useradd -m -d /home/appuser -s /bin/bash appuser
mkdir -p /app /opt/tunnel /opt/openlist/data /var/log/service_manager "${DATA_DIR}"
chown -R appuser:appuser /home/appuser /app /opt/tunnel /opt/openlist/data /var/log/service_manager

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

# --- 新增：生成同步工具的配置文件 ---
echo "5. Generating sync tool configurations..."

# 为 rclone 生成配置
mkdir -p /home/appuser/.config/rclone
cat << EOF > /home/appuser/.config/rclone/rclone.conf
[b2]
type = b2
account = \${B2_ACCOUNT_ID}
key = \${B2_ACCOUNT_KEY}
EOF
chown -R appuser:appuser /home/appuser/.config

# 为 litestream 生成配置
cat << EOF > /etc/litestream.yml
dbs:
  - path: ${DATA_DIR}/data.db
    replicas:
      - type: b2
        bucket: \${B2_BUCKET_PATH}
        path: db
        account-id: \${B2_ACCOUNT_ID}
        account-key: \${B2_ACCOUNT_KEY}
EOF

echo "--- [BUILD SCRIPT] Environment setup complete. ---"