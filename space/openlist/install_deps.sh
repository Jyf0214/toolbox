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
    sqlite3 \
    gettext-base \
&& rm -rf /var/lib/apt/lists/*

echo "--- [BUILD SCRIPT - DEPS] Camouflaging binaries ---"
mv /usr/bin/supervisord /usr/bin/service_manager
mv /usr/bin/supervisorctl /usr/bin/sm_ctl

echo "--- [BUILD SCRIPT - DEPS] Dependencies installed and camouflaged. ---"