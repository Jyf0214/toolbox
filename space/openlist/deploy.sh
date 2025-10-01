#!/bin/bash
set -e

echo "--- [BUILD SCRIPT] Starting environment setup as ROOT ---"

# --- 配置URL ---
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
# 使用新的配置文件名
PROC_CONFIG_URL="$BASE_URL/proc_config.ini"
FRPC_URL="https://www.chmlfrp.cn/dw/ChmlFrp-0.51.2_240715_linux_amd64.tar.gz"


echo "1. Creating user and directories..."
useradd -m -d /home/appuser -s /bin/bash appuser
mkdir -p /app /opt/tunnel /opt/openlist/data /var/log/service_manager
# 创建静态内容的目标目录
mkdir -p /app/static
chown -R appuser:appuser /home/appuser /app /opt/tunnel /opt/openlist/data /var/log/service_manager


echo "2. Fetching configurations and cloning git repo..."
# 下载重命名后的配置文件
wget -q -O /etc/proc_config.ini "$PROC_CONFIG_URL"

# 从 Git 克隆静态文件
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


echo "5. Installing Python dependencies..."
# 这个方案中，我们直接在 proc_config.ini 中调用 python，所以不需要安装 flask
# 如果有其他 python 依赖可以在此安装

echo "--- [BUILD SCRIPT] Environment setup complete. ---"