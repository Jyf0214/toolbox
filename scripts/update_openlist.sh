#!/usr/bin/env bash
set -e

# --- 脚本配置与变量初始化 ---

# 默认安装标准版，可被命令行参数覆盖喵
INSTALL_LITE="false"
# 接收第一个命令行参数，如果为 "lite"，就安装轻巧版喵
if [[ "$1" == "lite" ]]; then
    INSTALL_LITE="true"
    echo "ฅ'ω'ฅ OpenList 小助手报告喵：主人想要安装轻巧版的喵~ 安排上了喵！"
fi

API_URL="https://api.github.com/repos/OpenListTeam/OpenList/releases/latest"

# --- 环境和架构检测 ---

echo "킁킁... 让我闻闻主人的系统是什么味道的喵... 正在检测系统和架构喵~"
# 检测操作系统，然后告诉人家是苹果还是小企鹅喵
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "${OS}" in
    linux)
        OS_NAME="linux"
        ;;
    darwin)
        OS_NAME="darwin" # 是香香的苹果电脑喵
        ;;
    *)
        echo "Σ(っ °Д °;)っ 糟糕喵！这个系统人家不认识啦喵: ${OS}" >&2
        exit 1
        ;;
esac

# 检测 CPU 架构是什么样的喵
ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)    ARCH="amd64" ;;
    aarch64)   ARCH="arm64" ;; # Apple 的 M 芯片也算这个喵
    armv7l)    ARCH="armv7" ;;
    i386|i686) ARCH="386" ;;
    *)
        echo "Σ(っ °Д °;)っ 呜哇！主人的这个 CPU 架构太特别了喵: ${ARCH}" >&2
        exit 1
        ;;
esac

echo "喵呜~ 知道啦！主人的系统是 ${OS_NAME}, 架构是 ${ARCH} 的喵！(๑•̀ㅂ•́)و✧"

# --- 环境适配与依赖安装 ---

INSTALL_DIR="/usr/local/bin" # 默认给主人安装到这里喵

if [[ "${OS_NAME}" == "darwin" ]]; then
    echo "是香香的苹果电脑喵~ 正在用 Homebrew 帮主人准备需要的东西喵..."
    if ! command -v brew &> /dev/null; then
        echo "Σ(っ °Д °;)っ 糟糕喵！主人没有安装 Homebrew，人家没法继续了喵。" >&2
        exit 1
    fi
    brew install jq wget file >/dev/null
elif [[ -n "$PREFIX" ]] && [[ -d "$PREFIX/bin" ]]; then
    echo "(´,,•ω•,,｀)♡ 是 Termux 喵~ 正在用 pkg 帮主人准备东西喵..."
    INSTALL_DIR="$PREFIX/bin"
    pkg install -y curl jq wget file >/dev/null
else # 标准的小企鹅系统喵
    if [[ $(id -u) -ne 0 ]]; then
        echo "Σ(っ °Д °;)っ 糟糕喵！在小企鹅系统上，需要主人用 root 权限运行这个脚本才行喵！" >&2
        exit 1
    fi
    echo "是可爱的小企鹅系统喵~ 正在用 apt-get 帮主人准备东西喵..."
    cd /tmp
    apt-get update >/dev/null && apt-get install -y curl jq wget file >/dev/null
fi

# --- 从 API 获取下载链接 ---

echo "(=^-ω-^=) 正在努力寻找最新的版本信息喵..."
RELEASE_INFO=$(curl -sL "${API_URL}")

LATEST_TAG=$(echo "${RELEASE_INFO}" | jq -r '.tag_name')
if [[ -z "$LATEST_TAG" || "$LATEST_TAG" == "null" ]]; then
    echo "Σ(っ °Д °;)っ 糟糕喵！找不到最新的版本标签了喵..." >&2
    exit 1
fi

TARGET_PATTERN="${OS_NAME}-${ARCH}"
DOWNLOAD_URL=""
TARBALL=""

# 如果主人想要轻巧版，就先找轻巧版的喵
if [[ "$INSTALL_LITE" == "true" ]]; then
    LITE_PATTERN="${TARGET_PATTERN}-lite"
    # 更智能地寻找包含关键字的压缩包喵
    ASSET_INFO=$(echo "${RELEASE_INFO}" | jq -r --arg pattern "${LITE_PATTERN}" '.assets[] | select(.name | contains($pattern) and endswith(".tar.gz")) | "\(.browser_download_url);\(.name)"')
    if [[ -n "$ASSET_INFO" ]]; then
        DOWNLOAD_URL=$(echo "$ASSET_INFO" | cut -d';' -f1)
        TARBALL=$(echo "$ASSET_INFO" | cut -d';' -f2)
        echo "ฅ'ω'ฅ 找到主人的轻巧版了喵！就是这个 -> ${TARBALL}"
    else
        echo "(｡•́︿•̀｡) 嗯...没找到适合主人的轻巧版喵，人家试试看标准版好了喵..."
    fi
fi

# 如果没找到轻巧版或者主人不需要，就下载标准版喵
if [[ -z "$DOWNLOAD_URL" ]]; then
    # 这个命令会找包含 "linux-amd64" 但不包含 "lite" 的压缩包喵
    ASSET_INFO=$(echo "${RELEASE_INFO}" | jq -r --arg pattern "${TARGET_PATTERN}" '.assets[] | select(.name | contains($pattern) and endswith(".tar.gz") and (contains("lite") | not)) | "\(.browser_download_url);\(.name)"')
    if [[ -n "$ASSET_INFO" ]]; then
        DOWNLOAD_URL=$(echo "$ASSET_INFO" | cut -d';' -f1)
        TARBALL=$(echo "$ASSET_INFO" | cut -d';' -f2)
    else
        echo "Σ(っ °Д °;)っ 呜呜...找不到适合主人 (${TARGET_PATTERN}) 的任何下载链接喵..." >&2
        exit 1
    fi
fi

# --- 下载、验证与安装 ---

echo "找到啦喵！正在为主人下载版本 ${LATEST_TAG} (${TARBALL})... 请稍等一下喵~"
wget -qO "${TARBALL}" "${DOWNLOAD_URL}"

FILE_TYPE=$(file -b "${TARBALL}")
if [[ ! "${FILE_TYPE}" =~ "gzip compressed data" ]]; then
    echo "Σ(っ °Д °;)っ 糟糕喵！下载下来的文件好像坏掉了喵，不是一个压缩包喵..." >&2
    rm -f "${TARBALL}"
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap "rm -rf ${TMP_DIR}" EXIT # 主人放心，人家走的时候会把这里打扫干净的喵

echo "嘿咻嘿咻... 正在解压和安装喵..."
tar -zxf "${TARBALL}" -C "${TMP_DIR}"

BINARY_PATH=$(find "${TMP_DIR}" -type f -name "openlist")
if [[ -z "${BINARY_PATH}" ]]; then
    echo "Σ(っ °Д °;)っ 糟糕喵！压缩包里没有找到叫 'openlist' 的文件喵..." >&2
    exit 1
fi

INSTALL_PATH="${INSTALL_DIR}/openlist"
echo "马上就好喵！正在把文件放到 ${INSTALL_PATH} 这里喵~"
mv -f "${BINARY_PATH}" "${INSTALL_PATH}"
chmod +x "${INSTALL_PATH}"

# 打扫卫生喵
rm -f "${TARBALL}"

echo "✨ 搞定啦喵！OpenList 已经成功变成最新版 ${LATEST_TAG} (${ARCH}) 啦！现在它在 ${INSTALL_PATH} 安家了喵！主人快夸我喵~ (ɔˆ ³(ˆ⌣ˆc)"