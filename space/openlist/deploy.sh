#!/bin/bash
set -e

echo "--- [BUILD SCRIPT] Starting environment setup as ROOT ---"

# --- 配置URL ---
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
# 使用新的配置文件名
PROC_CONFIG_URL="$BASE_URL/proc_config.ini"
STATUS_APP_URL="$BASE_URL/status_app.py"
FRPC_URL="https://www.chmlfrp.cn/dw/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz"


echo "1. Creating user and directories..."
useradd -m -d /home/appuser -s /bin/bash appuser
mkdir -p /app /opt/tunnel /opt/openlist/data /var/log/service_manager
chown -R appuser:appuser /home/appuser /app /opt/tunnel /opt/openlist/data /var/log/service_manager


echo "2. Fetching configurations..."
# 下载重命名后的配置文件到通用路径
wget -q -O /etc/proc_config.ini "$PROC_CONFIG_URL"
# 下载状态页应用
wget -q -O /app/status_app.py "$STATUS_APP_URL"
chown appuser:appuser /app/status_app.py


echo "3. Installing main application (Openlist)..."
curl -fsSL http://bash.skadi.kozow.com/scripts/update_openlist.sh | bash


echo "4. Installing tunnel client (frpc)..."
wget -q -O /tmp/tunnel_client.tar.gz "$FRPC_URL"
tar --no-same-owner --strip-components=1 -xzf /tmp/tunnel_client.tar.gz -C /opt/tunnel/
chmod +x /opt/tunnel/frpc
rm /tmp/tunnel_client.tar.gz
chown -R appuser:appuser /opt/tunnel


echo "5. Installing Python dependencies..."
pip install -q flask

echo "--- [BUILD SCRIPT] Environment setup complete. ---"