#!/usr/bin/env bash
set -e

# --- 脚本配置与变量初始化 ---

# 默认安装标准版，可被命令行参数覆盖
INSTALL_LITE="false"
# 接收第一个命令行参数，如果为 "lite"，则设置安装精简版
if [[ "$1" == "lite" ]]; then
    INSTALL_LITE="true"
    echo "[OpenList Updater] INFO: 已指定安装精简版 (lite version)。"
fi

API_URL="https://api.github.com/repos/OpenListTeam/OpenList/releases/latest"

# --- 环境和架构检测 ---

echo "[OpenList Updater] 正在检测系统与架构..."
# 检测操作系统，并进行规范化 (darwin -> macos, linux -> linux)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "${OS}" in
    linux)
        OS_NAME="linux"
        ;;
    darwin)
        OS_NAME="darwin" # macOS 的内核名是 Darwin
        ;;
    *)
        echo "[OpenList Updater] ERROR: 不支持的操作系统: ${OS}" >&2
        exit 1
        ;;
esac

# 检测 CPU 架构
ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)    ARCH="amd64" ;;
    aarch64)   ARCH="arm64" ;; # 也适用于 Apple Silicon M-series
    armv7l)    ARCH="armv7" ;;
    i386|i686) ARCH="386" ;;
    *)
        echo "[OpenList Updater] ERROR: 不支持的 CPU 架构: ${ARCH}" >&2
        exit 1
        ;;
esac

echo "[OpenList Updater] 检测到系统: ${OS_NAME}, 架构: ${ARCH}"

# --- 环境适配与依赖安装 ---

INSTALL_DIR="/usr/local/bin" # 默认安装路径

if [[ "${OS_NAME}" == "darwin" ]]; then
    echo "[OpenList Updater] 检测到 macOS，使用 Homebrew 安装依赖..."
    # 检查 brew 是否安装
    if ! command -v brew &> /dev/null; then
        echo "[OpenList Updater] ERROR: Homebrew 未安装，请先安装 Homebrew。" >&2
        exit 1
    fi
    brew install jq wget file >/dev/null
elif [[ -n "$PREFIX" ]] && [[ -d "$PREFIX/bin" ]]; then
    echo "[OpenList Updater] 检测到 Termux (Android)，使用 pkg 安装依赖..."
    INSTALL_DIR="$PREFIX/bin"
    pkg install -y curl jq wget file >/dev/null
else # 标准 Linux
    if [[ $(id -u) -ne 0 ]]; then
        echo "[OpenList Updater] ERROR: 在标准 Linux 环境下，此脚本必须以 root 权限运行。" >&2
        exit 1
    fi
    echo "[OpenList Updater] 检测到标准 Linux，使用 apt-get 安装依赖..."
    cd /tmp
    apt-get update >/dev/null && apt-get install -y curl jq wget file >/dev/null
fi

# --- 从 API 获取下载链接 ---

echo "[OpenList Updater] 正在获取最新的发布信息..."
# -s 静默模式, -L 跟随重定向
RELEASE_INFO=$(curl -sL "${API_URL}")

LATEST_TAG=$(echo "${RELEASE_INFO}" | jq -r '.tag_name')
if [[ -z "$LATEST_TAG" || "$LATEST_TAG" == "null" ]]; then
    echo "[OpenList Updater] ERROR: 无法获取最新的版本标签。" >&2
    exit 1
fi

# 构建文件名模式 (e.g., "linux-amd64")
TARGET_PATTERN="${OS_NAME}-${ARCH}"
DOWNLOAD_URL=""
TARBALL=""

# 如果用户想安装精简版，优先尝试查找 lite 版本
if [[ "$INSTALL_LITE" == "true" ]]; then
    LITE_SUFFIX="${TARGET_PATTERN}-lite.tar.gz"
    DOWNLOAD_URL=$(echo "${RELEASE_INFO}" | jq -r --arg suffix "${LITE_SUFFIX}" '.assets[] | select(.name | endswith($suffix)) | .browser_download_url')
    if [[ -n "$DOWNLOAD_URL" && "$DOWNLOAD_URL" != "null" ]]; then
        TARBALL="openlist-${LITE_SUFFIX}"
        echo "[OpenList Updater] INFO: 已成功找到精简版下载链接。"
    else
        echo "[OpenList Updater] WARNING: 未找到适用于您平台的精简版，将尝试下载标准版。"
    fi
fi

# 如果没找到精简版或者用户不需要精简版，则下载标准版
if [[ -z "$DOWNLOAD_URL" ]]; then
    STANDARD_SUFFIX="${TARGET_PATTERN}.tar.gz"
    DOWNLOAD_URL=$(echo "${RELEASE_INFO}" | jq -r --arg suffix "${STANDARD_SUFFIX}" '.assets[] | select(.name | endswith($suffix)) | .browser_download_url')
    if [[ -n "$DOWNLOAD_URL" && "$DOWNLOAD_URL" != "null" ]]; then
        TARBALL="openlist-${STANDARD_SUFFIX}"
    else
        echo "[OpenList Updater] ERROR: 无法找到适用于您平台 (${TARGET_PATTERN}) 的任何下载链接。" >&2
        exit 1
    fi
fi

# --- 下载、验证与安装 ---

echo "[OpenList Updater] 正在下载版本 ${LATEST_TAG} (${TARBALL})..."
wget -qO "${TARBALL}" "${DOWNLOAD_URL}"

FILE_TYPE=$(file -b "${TARBALL}")
if [[ ! "${FILE_TYPE}" =~ "gzip compressed data" ]]; then
    echo "[OpenList Updater] ERROR: 下载的文件不是有效的 gzip 压缩包。" >&2
    rm -f "${TARBALL}"
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap "rm -rf ${TMP_DIR}" EXIT # 脚本退出时自动清理临时目录

echo "[OpenList Updater] 正在解压并安装..."
tar -zxf "${TARBALL}" -C "${TMP_DIR}"

BINARY_PATH=$(find "${TMP_DIR}" -type f -name "openlist")
if [[ -z "${BINARY_PATH}" ]]; then
    echo "[OpenList Updater] ERROR: 未能在压缩包中找到 'openlist' 可执行文件。" >&2
    exit 1
fi

INSTALL_PATH="${INSTALL_DIR}/openlist"
echo "[OpenList Updater] 正在将可执行文件移动到 ${INSTALL_PATH}"
mv -f "${BINARY_PATH}" "${INSTALL_PATH}"
chmod +x "${INSTALL_PATH}"

# 清理工作
rm -f "${TARBALL}"

echo "✅ OpenList 已成功更新至 ${LATEST_TAG} (${ARCH}) 并安装到 ${INSTALL_PATH}"
