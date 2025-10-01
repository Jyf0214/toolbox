#!/bin/bash
set -e
LOG_DIR="/var/log/service_manager"
BACKUP_LOG="${LOG_DIR}/backup_sync.log"
# 导出环境变量（Secrets）
export B2_BUCKET_NAME B2_PATH_PREFIX B2_ENDPOINT B2_ACCOUNT_ID B2_ACCOUNT_KEY
# 检查关键变量是否为空，如果为空，输出错误日志
if [ -z "$B2_BUCKET_NAME" ] || [ -z "$B2_PATH_PREFIX" ] || [ -z "$B2_ENDPOINT" ] || [ -z "$B2_ACCOUNT_ID" ] || [ -z "$B2_ACCOUNT_KEY" ]; then
    echo "Error: One or more B2 secrets are empty or not set. Check Hugging Face Secrets." >> "${LOG_DIR}/error.log"
    exit 1
fi
# 使用 envsubst 生成 rclone.conf，并验证替换是否成功
envsubst < /home/appuser/.config/rclone/rclone.conf.template > /home/appuser/.config/rclone/rclone.conf
# 调试：检查生成的 conf 文件是否仍包含占位符
if grep -q '\${' /home/appuser/.config/rclone/rclone.conf; then
    echo "Error: envsubst failed to replace variables in rclone.conf." >> "${LOG_DIR}/error.log"
    exit 1
fi
# 启动 service_manager
/usr/bin/service_manager -c /etc/proc_config.ini &
sleep 5
touch "${BACKUP_LOG}"
tail -f "${BACKUP_LOG}"