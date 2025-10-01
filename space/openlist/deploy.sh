#!/bin/bash
set -e
echo "--- [BUILD SCRIPT] Starting environment setup as ROOT ---"
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
PROC_CONFIG_URL="$BASE_URL/proc_config.ini"
CONFIG_TEMPLATE_URL="$BASE_URL/config.template.json" # 新增
FRPC_URL="https://www.chmlfrp.cn/dw/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz"

echo "1. Creating user and directories..."
useradd -m -d /home/appuser -s /bin/bash appuser
mkdir -p /app /opt/tunnel /home/appuser/data
mkdir -p /app/static
chown -R appuser:appuser /home/appuser /app /opt/tunnel

echo "2. Fetching configurations and cloning git repo..."
wget -q -O /etc/proc_config.ini "$PROC_CONFIG_URL"
wget -q -O /app/config.template.json "$CONFIG_TEMPLATE_URL" # 下载模板文件
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

echo "--- [BUILD SCRIPT] Environment setup complete. ---"