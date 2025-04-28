#!/bin/bash
set -e

echo "🚀 正在开始安装 TCR 聊天室项目..."

# 获取当前目录
PROJECT_DIR=$(pwd)

# 强制设置 Git safe.directory 以避免所有权问题
echo "🔒 配置 Git safe.directory 以避免所有权问题..."
git config --global --add safe.directory "$PROJECT_DIR" || {
    echo "⚠️ 无法设置 Git safe.directory，尝试临时禁用所有权检查..."
    export GIT_CEILING_DIRECTORIES="$PROJECT_DIR/.."
}

# 动态检测远程仓库的默认分支
get_default_branch() {
    local repo_url=$1
    # 获取 HEAD 指向的分支
    default_branch=$(git ls-remote --symref "$repo_url" HEAD | grep '^ref:' | sed 's|.*refs/heads/\(.*\)\tHEAD|\1|')
    if [ -z "$default_branch" ]; then
        echo "❌ 无法检测默认分支，假设为 master"
        echo "master"
    else
        echo "$default_branch"
    fi
}

# 检查当前目录是否已是 Git 仓库
REPO_URL="https://github.com/Limkon/TCR.git"
DEFAULT_BRANCH=$(get_default_branch "$REPO_URL")

if [ -d "$PROJECT_DIR/.git" ]; then
    echo "📁 当前目录已经是 Git 仓库，强制拉取并覆盖本地文件..."
    cd "$PROJECT_DIR"
    git fetch origin || {
        echo "⚠️ 获取远程仓库失败，尝试继续..."
    }
    git reset --hard origin/"$DEFAULT_BRANCH" || {
        echo "⚠️ 强制覆盖本地文件失败，尝试继续..."
    }
    git clean -fd || {
        echo "⚠️ 清理未跟踪文件失败，尝试继续..."
    }
else
    # 检查是否存在 TCR 项目文件（如 package.json）
    if [ -f "$PROJECT_DIR/package.json" ]; then
        echo "📁 检测到 TCR 项目文件，强制拉取并覆盖..."
        cd "$PROJECT_DIR"
        git init 2>/dev/null || true
        git remote set-url origin "$REPO_URL" 2>/dev/null || git remote add origin "$REPO_URL"
        git fetch origin || {
            echo "⚠️ 获取远程仓库失败，尝试继续..."
        }
        git reset --hard origin/"$DEFAULT_BRANCH" || {
            echo "⚠️ 强制覆盖本地文件失败，尝试继续..."
        }
        git clean -fd || {
            echo "⚠️ 清理未跟踪文件失败，尝试继续..."
        }
    else
        # 克隆 TCR 项目到临时目录，然后复制文件到当前目录
        echo "📥 克隆 TCR 项目并覆盖当前目录..."
        TEMP_DIR=$(mktemp -d)
        git clone "$REPO_URL" "$TEMP_DIR" || {
            echo "⚠️ 克隆仓库失败，尝试继续..."
        }
        # 复制所有文件（包括隐藏文件）到当前目录，强制覆盖
        cp -rf "$TEMP_DIR"/. "$PROJECT_DIR" 2>/dev/null || {
            echo "⚠️ 覆盖本地文件失败，尝试继续..."
        }
        # 初始化 Git 仓库
        cd "$PROJECT_DIR"
        git init 2>/dev/null || true
        git remote add origin "$REPO_URL" 2>/dev/null || true
        git fetch origin 2>/dev/null || true
        git checkout "$DEFAULT_BRANCH" -- . 2>/dev/null || {
            echo "⚠️ 检出 $DEFAULT_BRANCH 分支失败，尝试继续..."
        }
        rm -rf "$TEMP_DIR"
    fi
fi

# 检查 node 是否安装
if command -v node &> /dev/null; then
    echo "✅ Node.js 已安装，版本：$(node -v)，跳过 npm install"
else
    echo "🔧 Node.js 未检测到，开始安装 nvm 和 Node.js..."
    # 安装 nvm 到当前目录
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$PROJECT_DIR/.nvm" bash || {
        echo "⚠️ 安装 nvm 失败，尝试继续..."
    }
    # 加载 nvm
    export NVM_DIR="$PROJECT_DIR/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    # 安装 Node.js 18
    nvm install 18 || {
        echo "⚠️ 安装 Node.js 18 失败，尝试继续..."
    }
    # 安装项目依赖
    echo "📦 安装 npm 依赖..."
    npm install || {
        echo "⚠️ 安装 npm 依赖失败，尝试继续..."
    }
fi

# 确保 Node 环境可用
export NVM_DIR="$PROJECT_DIR/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 创建 autostart 文件夹
mkdir -p "$HOME/.config/autostart" || {
    echo "⚠️ 创建 autostart 目录失败，尝试继续..."
}

# 写开机启动的 .desktop 文件
echo "🛠️ 配置开机启动..."
cat > "$HOME/.config/autostart/tcr-startup.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=bash -c "cd $PROJECT_DIR && source $PROJECT_DIR/.nvm/nvm.sh && node server.js"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=TCR Chatroom Server
Comment=Start TCR Server automatically
EOF

echo "🎉 安装完成！下次开机登录后会自动启动 TCR 聊天室服务器！"
echo "📍 项目目录: $PROJECT_DIR"
echo "⚠️ 注意：部分操作可能失败，请检查日志并手动修复（如 git 操作或 npm install）。"
