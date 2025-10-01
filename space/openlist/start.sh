#!/bin/bash
set -e
LOG_DIR="/var/log/service_manager"
BACKUP_LOG="${LOG_DIR}/backup_sync.log"
ERROR_LOG="${LOG_DIR}/error.log"
# 导出环境变量（Secrets）
export WEBDAV_URL WEBDAV_USER WEBDAV_PASS WEBDAV_PATH WEBDAV_VENDOR
# 检查关键变量是否为空
if [ -z "$WEBDAV_URL" ] || [ -z "$WEBDAV_USER" ] || [ -z "$WEBDAV_PASS" ] || [ -z "$WEBDAV_PATH" ]; then
    echo "Error: One or more WebDAV secrets are empty or not set. Check Hugging Face Secrets." >> "${ERROR_LOG}"
    exit 1
fi
# 生成 rclone.conf，并验证替换
envsubst < /home/appuser/.config/rclone/rclone.conf.template > /home/appuser/.config/rclone/rclone.conf
if grep -q '\${' /home/appuser/.config/rclone/rclone.conf; then
    echo "Error: envsubst failed to replace variables in rclone.conf." >> "${ERROR_LOG}"
    exit 1
fi
# 调试：测试 rclone 认证，并输出详细错误到日志
rclone --config /home/appuser/.config/rclone/rclone.conf about webdav: >> "${ERROR_LOG}" 2>&1 || echo "Rclone authentication test failed. See error.log for details." >> "${BACKUP_LOG}"
# 启动 service_manager
/usr/bin/service_manager -c /etc/proc_config.ini &
sleep 5
touch "${BACKUP_LOG}"
tail -f "${BACKUP_LOG}"