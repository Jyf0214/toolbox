#!/bin/bash
set -e

echo "--- [BUILD SCRIPT - DEPS] Installing base dependencies ---"

# --- 关键改动：将 gettext-base 改为正确的包名 gettext ---
apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    tar \
    python3 \
    python3-pip \
    supervisor \
    ca-certificates \
    git \
    gettext \
&& rm -rf /var/lib/apt/lists/*

echo "--- [BUILD SCRIPT - DEPS] Camouflaging binaries ---"
# 安装后立刻重命名
mv /usr/bin/supervisord /usr/bin/service_manager
mv /usr/bin/supervisorctl /usr/bin/sm_ctl

echo "--- [BUILD SCRIPT - DEPS] Dependencies installed and camouflaged. ---"