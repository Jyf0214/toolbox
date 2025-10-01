#!/bin/bash
set -e

echo "--- [BUILD SCRIPT - DEPS] Installing dependencies ---"

apt-get update && apt-get install -y --no-install-recommends \
    curl \
    tar \
    python3 \
    python3-pip \
    supervisor \
    git \
    rclone \
    gettext-base \
&& rm -rf /var/lib/apt/lists/*
# ... (litestream 和重命名部分保持不变) ...
LITESTREAM_VERSION="0.3.13"
wget -q -O /tmp/litestream.deb "https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-v${LITESTREAM_VERSION}-linux-amd64.deb"
apt-get install -y /tmp/litestream.deb
rm /tmp/litestream.deb
mv /usr/bin/supervisord /usr/bin/service_manager
mv /usr/bin/supervisorctl /usr/bin/sm_ctl

echo "--- [BUILD SCRIPT - DEPS] Dependencies installed and camouflaged. ---"