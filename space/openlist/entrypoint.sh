#!/bin/bash

echo "--- [ENTRYPOINT] Starting service manager in background... ---"
# 在后台启动 service_manager (Supervisord)
# 它会开始管理所有在 proc_config.ini 中定义的应用
/usr/bin/service_manager -c /etc/proc_config.ini &

echo "--- [ENTRYPOINT] Waiting for log files to be created... ---"
# 等待3秒钟，给其他应用足够的时间启动并创建它们的日志文件
sleep 15

echo "--- [ENTRYPOINT] Starting log tailing in foreground... ---"
# 在前台启动 tail，监控所有日志文件
# exec 会让 tail 进程替换当前的 shell 进程，成为主进程，这是最佳实践
exec tail -f /var/log/service_manager/*.log