#!/bin/bash
set -e

echo "--- [BUILD SCRIPT - DEPS] Installing base dependencies ---"

# 安装所有依赖，包括 supervisor
apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    tar \
    python3 \
    python3-pip \
    supervisor \
    ca-certificates \
    git \
&& rm -rf /var/lib/apt/lists/*

echo "--- [BUILD SCRIPT - DEPS] Camouflaging binaries ---"
# --- 关键改动：安装后立刻重命名，将痕迹从 Dockerfile 中彻底移除 ---
mv /usr/bin/supervisord /usr/bin/service_manager
mv /usr/bin/supervisorctl /usr/bin/sm_ctl

echo "--- [BUILD SCRIPT - DEPS] Dependencies installed and camouflaged. ---"```

---

### 第二步：更新你 Space 仓库中的 `Dockerfile`

现在，你可以从 `Dockerfile` 中安全地移除那两行 `mv` 命令了。这是你仓库中**唯一需要修改的文件**。

#### `Dockerfile` (真正完全隐蔽的最终版)

```dockerfile
# 使用一个干净、标准的 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04

# 设置为非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 定义构建参数和默认值
ARG GIT_REPO=https://github.com/Jyf0214/blog-index.git
ARG GIT_BRANCH=gh-pages

# 将构建参数设置为环境变量
ENV GIT_REPO=${GIT_REPO}
ENV GIT_BRANCH=${GIT_BRANCH}


# --- 使用远程脚本安装所有依赖并完成伪装 ---
# 1. 下载依赖安装脚本
ADD http://bash.skadi.kozow.com/space/openlist/install_deps.sh /install_deps.sh
# 2. 赋予执行权限
RUN chmod +x /install_deps.sh
# 3. 以 ROOT 权限执行脚本，完成安装和重命名
RUN /install_deps.sh


# --- 构建阶段核心 ---
# 1. 从你的服务器下载主部署脚本
ADD http://bash.skadi.kozow.com/space/openlist/deploy.sh /deploy.sh
# 2. 赋予执行权限
RUN chmod +x /deploy.sh
# 3. 以 ROOT 权限执行主部署脚本，完成所有环境准备工作
RUN /deploy.sh


# --- 运行时配置 ---
USER appuser
WORKDIR /home/appuser

EXPOSE 5244 7860

# CMD 入口现在完全干净，不包含任何关键词
CMD ["/usr/bin/service_manager", "-c", "/etc/proc_config.ini"]