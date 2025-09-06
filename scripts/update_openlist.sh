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
# 检测操作系统，然后告诉人家是苹果、小企鹅还是小窗户喵
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "${OS}" in
    linux)
        OS_NAME="linux"
        ;;
    darwin)
        OS_NAME="darwin" # 是香香的苹果电脑喵~
        ;;
    *mingw*|*msys*|*cygwin*) # 在窗户系统上运行，要特别一点喵~
        OS_NAME="windows"
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

# --- 帮主人准备好需要的小工具和安家的地方喵 ---

INSTALL_DIR="/usr/local/bin" # 默认安装到这里喵~

if [[ "${OS_NAME}" == "windows" ]]; then
    echo "(^・ω・^ ) 是可爱的窗户系统喵~ 人家就不移动文件啦，让它留在主人身边喵~"
    INSTALL_DIR="." # 在窗户系统上，就把家安在当前目录喵~
else # 在小企鹅和苹果系统上才需要安装工具和放到 bin 目录喵
    if [[ -n "$PREFIX" ]] && [[ -d "$PREFIX/bin" ]]; then
        echo "(´,,•ω•,,｀)♡ 是 Termux 喵~ 正在用 pkg 帮主人安装小工具喵..."
        INSTALL_DIR="$PREFIX/bin"
        pkg install -y curl jq wget file >/dev/null
    else # 标准的小企鹅或苹果系统喵
        if [[ $(id -u) -ne 0 ]]; then
            echo "Σ(っ °Д °;)っ 喵！在这个系统上，需要主人用 root 的魔法力量才能继续哦喵！" >&2
            exit 1
        fi
        echo "是可爱的小企鹅或苹果系统喵~ 正在用 apt-get (或者系统自带的工具) 帮主人安装小工具喵..."
        cd /tmp
        # 对于不同的 Linux 发行版，这里可能需要调整喵~
        if command -v apt-get &> /dev/null; then
            apt-get update >/dev/null && apt-get install -y apt-utils curl jq wget file >/dev/null
        fi
    fi
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

# 为窗户系统准备好 .zip 的小尾巴喵~
COMPRESS_EXT="tar.gz"
if [[ "${OS_NAME}" == "windows" ]]; then
    COMPRESS_EXT="zip"
fi

# 像这样拼一个文件名出来喵 "linux-amd64.tar.gz" 或 "windows-amd64.zip"
TARGET_PATTERN="${OS_NAME}-${ARCH}"
DOWNLOAD_URL=""
ARCHIVE_NAME=""

# 如果主人想安装轻巧版，就先找找看喵...
if [[ "$INSTALL_LITE" == "true" ]]; then
    LITE_SUFFIX="${TARGET_PATTERN}-lite.${COMPRESS_EXT}"
    DOWNLOAD_URL=$(echo "${RELEASE_INFO}" | jq -r --arg suffix "${LITE_SUFFIX}" '.assets[] | select(.name | endswith($suffix)) | .browser_download_url')
    if [[ -n "$DOWNLOAD_URL" && "$DOWNLOAD_URL" != "null" ]]; then
        ARCHIVE_NAME="openlist-${LITE_SUFFIX}"
        echo "ฅ'ω'ฅ 找到轻巧版的下载链接啦喵！"
    else
        echo "(｡•́︿•̀｡) 呜...没找到适合主人的轻巧版喵，人家会试试看标准版的喵！"
    fi
fi

# 如果没找到轻巧版或者主人不需要，就下载标准版喵~
if [[ -z "$DOWNLOAD_URL" ]]; then
    STANDARD_SUFFIX="${TARGET_PATTERN}.${COMPRESS_EXT}"
    DOWNLOAD_URL=$(echo "${RELEASE_INFO}" | jq -r --arg suffix "${STANDARD_SUFFIX}" '.assets[] | select(.name | endswith($suffix)) | .browser_download_url')
    if [[ -n "$DOWNLOAD_URL" && "$DOWNLOAD_URL" != "null" ]]; then
        ARCHIVE_NAME="openlist-${STANDARD_SUFFIX}"
    else
        # 尝试 musl 版本，如果是 linux 系统
        if [[ "${OS_NAME}" == "linux" ]]; then
            echo "(^・ω・^ ) 没找到标准版喵，试试 musl 版好不好喵？它功能一样哦，只是更兼容一些系统喵~"
            MUSL_PATTERN="linux-musl-${ARCH}"
            STANDARD_SUFFIX="${MUSL_PATTERN}.tar.gz"
            DOWNLOAD_URL=$(echo "${RELEASE_INFO}" | jq -r --arg suffix "${STANDARD_SUFFIX}" '.assets[] | select(.name | endswith($suffix)) | .browser_download_url')
            if [[ -n "$DOWNLOAD_URL" && "$DOWNLOAD_URL" != "null" ]]; then
                ARCHIVE_NAME="openlist-${STANDARD_SUFFIX}"
                TARGET_PATTERN="${MUSL_PATTERN}"
            fi
        fi
        if [[ -z "$DOWNLOAD_URL" ]]; then
            echo "Σ(っ °Д °;)っ 呜呜...人家尽力了，但还是找不到适合 (${TARGET_PATTERN}) 的下载链接喵... 对不起主人喵..." >&2
            exit 1
        fi
    fi
fi

# --- 下载和安装时间到喵！---

echo "找到啦喵！最新版本是 ${LATEST_TAG} (对应文件：${ARCHIVE_NAME})"

# Windows 系统：打印下载链接，让主人手动下载
if [[ "${OS_NAME}" == "windows" ]]; then
    echo -e "\n(^・ω・^ ) 检测到 Windows 系统，为您提供手动下载链接："
    echo "📥 下载地址：${DOWNLOAD_URL}"
    echo -e "\n请主人复制链接到浏览器下载，下载后解压到当前目录即可使用哦喵！"
    # 跳过自动下载/安装，直接结束（保持与原逻辑中“留在当前目录”的一致）
    exit 0
fi

# 非 Windows 系统（Linux/Darwin）：继续自动下载（用 curl 替代原 wget，避免依赖问题）
echo "正在为主人自动下载，请稍等一下喵~"
curl -sL -o "${ARCHIVE_NAME}" "${DOWNLOAD_URL}"

# 检查文件下载好了没有喵
if [[ ! -f "${ARCHIVE_NAME}" ]]; then
    echo "Σ(っ °Д °;)っ 糟糕喵！文件没有下载下来喵...呜呜..." >&2
    exit 1
fi

TMP_DIR=$(mktemp -d)
# 人家会把垃圾打扫干净的，主人放心喵~
trap "rm -rf ${TMP_DIR}" EXIT 

echo "嘿咻嘿咻... 正在解压和安装喵..."
# 非 Windows 系统仅需处理 tar.gz 解压（Windows 已提前退出）
tar -zxf "${ARCHIVE_NAME}" -C "${TMP_DIR}"
BINARY_NAME="openlist"

BINARY_PATH=$(find "${TMP_DIR}" -type f -name "${BINARY_NAME}")
if [[ -z "${BINARY_PATH}" ]]; then
    echo "Σ(っ °Д °;)っ 糟糕喵！压缩包里没有找到叫 '${BINARY_NAME}' 的文件喵！下载的文件是不是有问题喵？" >&2
    exit 1
fi

# 非 Windows 系统：放到指定安装目录
INSTALL_PATH="${INSTALL_DIR}/openlist"
echo "马上就好喵！正在把文件放到 ${INSTALL_PATH} 这里喵~"
mv -f "${BINARY_PATH}" "${INSTALL_PATH}"
chmod +x "${INSTALL_PATH}"

# 打扫卫生喵~
rm -f "${ARCHIVE_NAME}"

echo "✨ 搞定啦喵！OpenList 已经成功变成最新版 ${LATEST_TAG} (${ARCH}) 啦！现在它在 ${INSTALL_PATH} 安家了喵！主人快夸我喵~ (ɔˆ ³(ˆ⌣ˆc)"
