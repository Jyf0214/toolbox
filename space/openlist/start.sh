#!/bin/bash
set -e

LOG_DIR="/var/log/service_manager"
# --- 关键修正：指向 rclone 备份的日志文件 ---
BACKUP_LOG="${LOG_DIR}/backup_sync.log"

echo "--- [Launcher] Injecting secrets into configuration files... ---"
export B2_BUCKET_NAME B2_PATH_PREFIX B2_ENDPOINT B2_REGION B2_ACCOUNT_ID B2_ACCOUNT_KEY
envsubst < /home/appuser/.config/rclone/rclone.conf.template > /home/appuser/.config/rclone/rclone.conf

echo "--- [Launcher] Starting background service manager... ---"
/usr/bin/service_manager -c /etc/proc_config.ini &
sleep 5

echo "--- [Launcher] Tailing Backup Sync log to standard output. ---"
touch "${BACKUP_LOG}"
tail -f "${BACKUP_LOG}"