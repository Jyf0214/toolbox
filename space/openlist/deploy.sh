#!/bin/bash
set -e

echo "--- [BUILD SCRIPT] Starting environment setup as ROOT ---"

# --- 配置URL ---
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
SUPERVISOR_CONF_URL="$BASE_URL/supervisord.conf"
STATUS_APP_URL="$BASE_URL/status_app.py"
FRPC_URL="https://www.chmlfrp.cn/dw/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz"


echo "1. Creating user and directories..."
useradd -m -d /home/appuser -s /bin/bash appuser
mkdir -p /app /opt/frpc /opt/openlist/data /var/log/supervisor
chown -R appuser:appuser /home/appuser /app /opt/frpc /opt/openlist/data /var/log/supervisor


echo "2. Fetching configurations..."
# 下载 Supervisor 配置，这是给运行时使用的
wget -q -O /etc/supervisor/conf.d/supervisord.conf "$SUPERVISOR_CONF_URL"
# 下载状态页应用
wget -q -O /app/status_app.py "$STATUS_APP_URL"
chown appuser:appuser /app/status_app.py


echo "3. Installing Openlist..."
# 安装 Openlist
curl -fsSL http://bash.skadi.kozow.com/scripts/update_openlist.sh | bash


echo "4. Installing frpc client..."
wget -q -O /tmp/frpc.tar.gz "$FRPC_URL"
tar --no-same-owner --strip-components=1 -xzf /tmp/frpc.tar.gz -C /opt/frpc/
chmod +x /opt/frpc/frpc
rm /tmp/frpc.tar.gz
# 确保 appuser 拥有 frpc 目录
chown -R appuser:appuser /opt/frpc


echo "5. Installing Python dependencies..."
pip install -q flask

echo "--- [BUILD SCRIPT] Environment setup complete. ---"