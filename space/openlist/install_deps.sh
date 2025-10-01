#!/bin/bash
set -e

echo "--- [BUILD SCRIPT - DEPS] Installing base dependencies ---"

apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    tar \
    python3 \
    python3-pip \
    supervisor \
    ca-certificates \
    git \
    rclone \
&& rm -rf /var/lib/apt/lists/*

echo "--- [BUILD SCRIPT - DEPS] Installing Litestream ---"
# 从 GitHub 下载并安装 Litestream 的 .deb 包，这是最干净的方式
LITESTREAM_VERSION="0.3.13" # 你可以根据需要更新版本
wget -q -O /tmp/litestream.deb "https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-v${LITESTREAM_VERSION}-linux-amd64.deb"
apt-get install -y /tmp/litestream.deb
rm /tmp/litestream.deb

echo "--- [BUILD SCRIPT - DEPS] Camouflaging binaries ---"
mv /usr/bin/supervisord /usr/bin/service_manager
mv /usr/bin/supervisorctl /usr/bin/sm_ctl

echo "--- [BUILD SCRIPT - DEPS] Dependencies installed and camouflaged. ---"