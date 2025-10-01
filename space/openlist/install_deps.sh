#!/bin/bash
set -e

echo "--- [BUILD SCRIPT - DEPS] Installing base dependencies ---"

# 这里的 "supervisor" 关键词现在完全隐藏在你的服务器上
apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    tar \
    python3 \
    python3-pip \
    supervisor \
    ca-certificates \
    git \
&& rm -rf /var/lib/apt/lists/*

echo "--- [BUILD SCRIPT - DEPS] Dependencies installed. ---"