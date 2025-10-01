
#!/bin/bash
set -e

echo "--- [Launcher] Starting services ---"

# --- 配置URL ---
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
SUPERVISOR_CONF_URL="$BASE_URL/supervisord.conf"
STATUS_APP_URL="$BASE_URL/status_app.py"
FRPC_URL="https://www.chmlfrp.cn/dw/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz"

echo "1. Fetching runtime configurations..."
wget -q -O /etc/supervisor/conf.d/supervisord.conf "$SUPERVISOR_CONF_URL"
wget -q -O /app/status_app.py "$STATUS_APP_URL"
chown -R appuser:appuser /app

echo "2. Installing Openlist..."
# 使用 curl -sSL ... | sudo bash 的方式来确保脚本有权限执行
curl -fsSL http://bash.skadi.kozow.com/scripts/update_openlist.sh | bash

echo "3. Installing frpc client..."
wget -q -O /tmp/frpc.tar.gz "$FRPC_URL"
tar --no-same-owner --strip-components=1 -xzf /tmp/frpc.tar.gz -C /opt/frpc/
chmod +x /opt/frpc/frpc
rm /tmp/frpc.tar.gz

echo "4. Installing Python dependencies..."
pip install -q flask

echo "--- [Launcher] Setup complete. Handing over to Supervisor. ---"

# 启动 supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf