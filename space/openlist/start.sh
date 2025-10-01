#!/bin/bash
set -e

LOG_DIR="/var/log/service_manager"
OPENLIST_LOG="${LOG_DIR}/main_app.log"

echo "--- [Launcher] Starting background service manager... ---"

# 1. 启动 service_manager (Supervisord) 在后台运行
#    它会根据配置启动所有应用，并将它们的日志写入 /var/log/service_manager/
/usr/bin/service_manager -c /etc/proc_config.ini &

# 等待一小会儿，确保 Openlist 进程已启动并创建了日志文件
sleep 5

echo "--- [Launcher] Tailing Openlist log to standard output. ---"

# 2. 在前台运行 tail 命令，持续监控 Openlist 的日志文件
#    这个命令会成为容器的主进程。如果日志文件不存在，touch 会创建它以防 tail 报错退出。
touch "${OPENLIST_LOG}"
tail -f "${OPENLIST_LOG}"