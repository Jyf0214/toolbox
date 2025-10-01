#!/bin/bash
set -e

echo "--- [Launcher] Starting services with sudo ---"

# --- 配置URL ---
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
SUPERVISOR_CONF_URL="$BASE_URL/supervisord.conf"
STATUS_APP_URL="$BASE_URL/status_app.py"
FRPC_URL="https://www.chmlfrp.cn/dw/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz"


echo "1. Fetching runtime configurations..."
# 使用 sudo 写入系统目录
sudo wget -q -O /etc/supervisor/conf.d/supervisord.conf "$SUPERVISOR_CONF_URL"
# /app 目录已属于 appuser，无需 sudo
wget -q -O /app/status_app.py "$STATUS_APP_URL"


echo "2. Installing Openlist..."
# 使用 sudo 来执行安装脚本
curl -fsSL http://bash.skadi.kozow.com/scripts/update_openlist.sh | sudo bash


echo "3. Installing frpc client..."
wget -q -O /tmp/frpc.tar.gz "$FRPC_URL"
# 使用 sudo 解压到 /opt 目录并修改权限
sudo tar --no-same-owner --strip-components=1 -xzf /tmp/frpc.tar.gz -C /opt/frpc/
sudo chmod +x /opt/frpc/frpc
rm /tmp/frpc.tar.gz


echo "4. Installing Python dependencies..."
# 使用 sudo 将 flask 安装到系统 python 环境
sudo pip install -q flask


echo "--- [Launcher] Setup complete. Handing over to Supervisor. ---"
# 使用 sudo 启动 supervisord，因为 supervisord 需要 root 权限来管理不同用户的进程
exec sudo /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf