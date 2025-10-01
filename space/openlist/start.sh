#!/bin/bash
set -e

LOG_DIR="/var/log/service_manager"
# --- 关键修正：指向 Litestream 的日志文件 ---
LITESTREAM_LOG="${LOG_DIR}/litestream.log"

echo "--- [Launcher] Starting background service manager... ---"

# 1. 在后台启动 service_manager
/usr/bin/service_manager -c /etc/proc_config.ini &

# 等待一小会儿，确保进程已启动并创建了日志文件
sleep 15

echo "--- [Launcher] Tailing Litestream log to standard output. ---"

# 2. 在前台持续监控 Litestream 的日志文件
touch "${LITESTREAM_LOG}"
tail -f "${LITESTREAM_LOG}"