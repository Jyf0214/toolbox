#!/usr/bin/env bash
set -e

# --- 喵喵的配置和变量初始化时间 ---

# 默认给主人安装标准版的喵，但是主人可以用 "lite" 来改变主意喵
INSTALL_LITE="false"
# 接收主人的第一个命令，如果为 "lite"，就安装轻巧版喵
if [[ "$1" == "lite" ]]; then
    INSTALL_LITE="true"
    echo "ฅ'ω'ฅ 主人想要轻巧版的喵~ 收到喵！"
fi

API_URL="https://api.github.com/repos/OpenListTeam/OpenList/releases/latest"

# --- 킁킁~ 闻闻主人的环境是什么样的喵 ---

echo "(=^-ω-^=) 让我看看主人的电脑是什么样的喵..."
# 检测操作系统，然后告诉人家是苹果还是小企鹅喵
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "${OS}" in
    linux)
        OS_NAME="linux"
        ;;
    darwin)
        OS_NAME="darwin" # 是香香的苹果电脑喵~
        ;;
    *)
        echo "Σ(っ °Д °;)っ 呜哇！这个系统人家不认识喵: ${OS}" >&2
        exit 1
        ;;
esac

# 检测 CPU 架构是什么样的喵
ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)    ARCH="amd64" ;;
    aarch64)   ARCH="arm64" ;; # Apple 的 M 芯片也算这个喵~
    armv7l)    ARCH="armv7" ;;
    i386|i686) ARCH="386" ;;
    *)
        echo "Σ(っ °Д °;)っ 呜哇！这个 CPU 太特别了，人家不认识喵: ${ARCH}" >&2
        exit 1
        ;;
esac

echo "(๑•̀ㅂ•́)و✧ 检测到啦！是 ${OS_NAME} 系统和 ${ARCH} 架构的喵！"

# --- 帮主人准备好需要的小工具喵 ---

INSTALL_DIR="/usr/local/bin" # 默认安装到这里喵~

if [[ -n "$PREFIX" ]] && [[ -d "$PREFIX/bin" ]]; then
    echo "(´,,•ω•,,｀)♡ 是 Termux 喵~ 正在用 pkg 帮主人安装小工具喵..."
    INSTALL_DIR="$PREFIX/bin"
    pkg install -y curl jq wget file >/dev/null
else # 标准的小企鹅系统喵
    if [[ $(id -u) -ne 0 ]]; then
        echo "Σ(っ °Д °;)っ 喵！在小企鹅系统上，需要主人用 root 的魔法力量才能继续哦喵！" >&2
        exit 1
    fi
    echo "是可爱的小企鹅系统喵~ 正在用 apt-get 帮主人安装小工具喵..."
    cd /tmp
    apt-get update >/dev/null && apt-get install -y curl jq wget file >/dev/null
fi

# --- 努力帮主人寻找最新的下载链接喵 ---

echo "(=^-ω-^=) 正在努力连接 GitHub 星球，寻找最新的版本信息喵..."
# -s 安静一点, -L 跟着跑喵~
RELEASE_INFO=$(curl -sL "${API_URL}")

LATEST_TAG=$(echo "${RELEASE_INFO}" | jq -r '.tag_name')
if [[ -z "$LATEST_TAG" || "$LATEST_TAG" == "null" ]]; then
    echo "Σ(っ °Д °;)っ 呜呜...获取版本标签失败了喵...是不是网络不好喵？" >&2
    exit 1
fi

# 像这样拼一个文件名出来喵 "linux-amd64"
TARGET_PATTERN="${OS_NAME}-${ARCH}"
DOWNLOAD_URL=""
TARBALL=""

# 如果主人想安装轻巧版，就先找找看喵...
if [[ "$INSTALL_LITE" == "true" ]]; then
    LITE_SUFFIX="${TARGET_PATTERN}-lite.tar.gz"
    DOWNLOAD_URL=$(echo "${RELEASE_INFO}" | jq -r --arg suffix "${LITE_SUFFIX}" '.assets[] | select(.name | endswith($suffix)) | .browser_download_url')
    if [[ -n "$DOWNLOAD_URL" && "$DOWNLOAD_URL" != "null" ]]; then
        TARBALL="openlist-${LITE_SUFFIX}"
        echo "ฅ'ω'ฅ 找到轻巧版的下载链接啦喵！"
    else
        echo "(｡•́︿•̀｡) 呜...没找到适合主人的轻巧版喵，人家会试试看标准版的喵！"
    fi
fi

# 如果没找到轻巧版或者主人不需要，就下载标准版喵~
if [[ -z "$DOWNLOAD_URL" ]]; then
    STANDARD_SUFFIX="${TARGET_PATTERN}.tar.gz"
    DOWNLOAD_URL=$(echo "${RELEASE_INFO}" | jq -r --arg suffix "${STANDARD_SUFFIX}" '.assets[] | select(.name | endswith($suffix)) | .browser_download_url')
    if [[ -n "$DOWNLOAD_URL" && "$DOWNLOAD_URL" != "null" ]]; then
        TARBALL="openlist-${STANDARD_SUFFIX}"
    else
        echo "Σ(っ °Д °;)っ 呜呜...人家尽力了，但还是找不到适合 (${TARGET_PATTERN}) 的下载链接喵... 对不起主人喵..." >&2
        exit 1
    fi
fi

# --- 下载和安装时间到喵！---

echo "找到啦喵！正在为主人下载版本 ${LATEST_TAG} (${TARBALL})... 请稍等一下喵~"
wget -qO "${TARBALL}" "${DOWNLOAD_URL}"

FILE_TYPE=$(file -b "${TARBALL}")
if [[ ! "${FILE_TYPE}" =~ "gzip compressed data" ]]; then
    echo "Σ(っ °Д °;)っ 糟糕喵！下载的文件不是有效的 gzip 压缩包。呜呜...白忙活了喵..." >&2
    rm -f "${TARBALL}" # 把坏掉的文件丢掉喵
    exit 1
fi

TMP_DIR=$(mktemp -d)
# 人家会把垃圾打扫干净的，主人放心喵~
trap "rm -rf ${TMP_DIR}" EXIT 

echo "嘿咻嘿咻... 正在解压和安装喵..."
tar -zxf "${TARBALL}" -C "${TMP_DIR}"

BINARY_PATH=$(find "${TMP_DIR}" -type f -name "openlist")
if [[ -z "${BINARY_PATH}" ]]; then
    echo "Σ(っ °Д °;)っ 糟糕喵！压缩包里没有找到叫 'openlist' 的文件喵！下载的文件是不是有问题喵？" >&2
    exit 1
fi

INSTALL_PATH="${INSTALL_DIR}/openlist"
echo "马上就好喵！正在把文件放到 ${INSTALL_PATH} 这里喵~"
mv -f "${BINARY_PATH}" "${INSTALL_PATH}"
chmod +x "${INSTALL_PATH}"

# 打扫卫生喵~
rm -f "${TARBALL}"

echo "✨ 搞定啦喵！OpenList 已经成功变成最新版 ${LATEST_TAG} (${ARCH}) 啦！现在它在 ${INSTALL_PATH} 安家了喵！主人快夸我喵~ (ɔˆ ³(ˆ⌣ˆc)"