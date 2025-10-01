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
chown -R appuser:appuser /home/appuser /app /opt/tunnel /opt/openlist/data /var/log/service_manager


echo "2. Fetching configurations and creating static content..."
# 下载重命名后的配置文件
wget -q -O /etc/proc_config.ini "$PROC_CONFIG_URL"
# 创建静态文件目录
mkdir -p /app/static
# 创建一个简单的 index.html 页面
cat <<EOF > /app/static/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Service Status</title>
    <style>
        body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f0f0f0; margin: 0; }
        .container { text-align: center; padding: 40px; background-color: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        p { color: #555; }
        .status { color: #28a745; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Service Status</h1>
        <p>All services are running.</p>
        <p>Status: <span class="status">OK</span></p>
    </div>
</body>
</html>
EOF
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