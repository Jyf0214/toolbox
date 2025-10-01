#!/bin/bash
set -e

echo "--- [BUILD SCRIPT] Starting environment setup as ROOT ---"

# --- 配置URL ---
BASE_URL="http://bash.skadi.kozow.com/space/openlist"
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

# --- 关键改动：从 Git 克隆静态文件 ---
echo "Cloning from ${GIT_REPO} on branch ${GIT_BRANCH}..."
# 使用 --depth=1 进行浅克隆，速度更快，占用空间更小
git clone --depth=1 --branch "${GIT_BRANCH}" "${GIT_REPO}" /app/static
# 删除 .git 目录以减小镜像体积
rm -rf /app/static/.git
# 确保 appuser 拥有静态文件目录
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