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
tail -f "${OPENLIST_LOG}"```

---

### 第二步：更新你服务器上的 `proc_config.ini`

这个配置文件现在变得非常简单。**所有服务都将日志写入文件**，或者彻底隐藏。没有任何进程会尝试写入 `/dev/stdout`，从而完美规避 Supervisord 的 bug。

#### `proc_config.ini` (最终稳定版 - 托管在你的服务器)

```ini
[supervisord]
nodaemon=true
logfile=/var/log/service_manager/manager.log
pidfile=/var/log/service_manager/manager.pid
user=appuser
loglevel=critical

[program:initial_restore]
command=bash -c "litestream restore -if-replica-exists -config /etc/litestream.yml ${DATA_DIR}/data.db && rclone copyto 'b2:${B2_BUCKET_NAME}/${B2_PATH_PREFIX}/config.json' '${DATA_DIR}/config.json' --ignore-errors"
user=appuser
autostart=true
autorestart=false
startsecs=0
priority=100
stdout_logfile=/dev/null ; <-- 隐藏日志
redirect_stderr=true

[program:main_app] ; (Openlist)
command=openlist server
directory=/home/appuser
user=appuser
autostart=true
autorestart=true
startsecs=5
priority=200
stdout_logfile=/var/log/service_manager/main_app.log ; <-- 写入专用日志文件
redirect_stderr=true

[program:db_replication]
command=litestream replicate -config /etc/litestream.yml
user=appuser
autostart=true
autorestart=true
startsecs=10
priority=300
stdout_logfile=/dev/null ; <-- 隐藏日志
redirect_stderr=true

[program:config_sync_up]
command=bash -c 'while true; do sleep 300; rclone copyto "${DATA_DIR}/config.json" "b2:${B2_BUCKET_NAME}/${B2_PATH_PREFIX}/config.json"; done'
user=appuser
autostart=true
autorestart=true
startsecs=10
priority=300
stdout_logfile=/dev/null ; <-- 隐藏日志
redirect_stderr=true

[program:static_server]
command=python3 -m http.server 7860 --directory /app/static
directory=/app/static
user=appuser
autostart=true
autorestart=true
priority=300
stdout_logfile=/dev/null
redirect_stderr=true

[program:tunnel_client]
command=/opt/tunnel/frpc -u %(ENV_FRPC_SECRET_KEY)s -p 201696
directory=/opt/tunnel
user=appuser
autostart=true
autorestart=true
priority=300
stdout_logfile=/dev/null
redirect_stderr=true