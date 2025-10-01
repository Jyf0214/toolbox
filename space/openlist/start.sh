#!/bin/bash
# 确保任何命令失败时，脚本都会立即退出
set -e

echo "--- [Launcher] Starting dynamic container setup from remote script ---"

# --- 配置URL ---
# 指向你自己的服务器上的配置文件
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
SUPERVISOR_CONF_URL="$BASE_URL/supervisord.conf"
STATUS_APP_URL="$BASE_URL/status_app.py"
FRPC_URL="https://www.chmlfrp.cn/dw/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz"


echo "1. Creating directories and user..."
# 如果用户已存在则忽略错误
useradd -m -d /home/appuser -s /bin/bash appuser || echo "User appuser already exists."
mkdir -p /app /opt/frpc /opt/openlist/data
chmod -R 777 /opt/openlist/data

echo "2. Fetching remote configurations..."
wget -q -O /etc/supervisor/conf.d/supervisord.conf "$SUPERVISOR_CONF_URL"
wget -q -O /app/status_app.py "$STATUS_APP_URL"
chown -R appuser:appuser /app

echo "3. Installing Openlist..."
# 使用你提供的脚本安装 Openlist
curl -fsSL http://bash.skadi.kozow.com/scripts/update_openlist.sh | bash

echo "4. Installing frpc client..."
wget -q -O /tmp/frpc.tar.gz "$FRPC_URL"
tar --no-same-owner --strip-components=1 -xzf /tmp/frpc.tar.gz -C /opt/frpc/
chmod +x /opt/frpc/frpc
rm /tmp/frpc.tar.gz

echo "5. Installing Python dependencies..."
pip install -q flask

echo "--- [Launcher] Dynamic setup complete. Handing over to Supervisor. ---"

# 使用 exec 启动 supervisord
# 这会将当前的 shell 进程替换为 supervisord 进程，使其成为容器的主进程
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
