#!/bin/bash
set -e

echo "🚀 正在开始安装 TCR 聊天室项目..."

# 获取当前目录
PROJECT_DIR=$(pwd)

# 动态检测远程仓库的默认分支
get_default_branch() {
    local repo_url=$1
    # 获取 HEAD 指向的分支
    default_branch=$(git ls-remote --symref "$repo_url" HEAD | grep '^ref:' | sed 's|.*refs/heads/\(.*\)\tHEAD|\1|')
    if [ -z "$default_branch" ]; then
        echo "master"
    else
        echo "$default_branch"
    fi
}

# 克隆 TCR 项目并覆盖当前目录
REPO_URL="https://github.com/Limkon/TCR.git"
DEFAULT_BRANCH=$(get_default_branch "$REPO_URL")

echo "📥 克隆 TCR 项目并覆盖当前目录..."
TEMP_DIR=$(mktemp -d)
git clone "$REPO_URL" "$TEMP_DIR" || {
    echo "⚠️ 克隆仓库失败，继续执行后续操作..."
}
# 复制所有文件（包括隐藏文件）到当前目录，强制覆盖，失败则直接跳过
cp -rf "$TEMP_DIR"/. "$PROJECT_DIR" 2>/dev/null || true
rm -rf "$TEMP_DIR"

# 检查 node 是否安装
if command -v node &> /dev/null; then
    echo "✅ Node.js 已安装，版本：$(node -v)，跳过 npm install"
else
    echo "🔧 Node.js 未检测到，开始安装 nvm 和 Node.js..."
    # 安装 nvm 到当前目录
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$PROJECT_DIR/.nvm" bash || {
        echo "⚠️ 安装 nvm 失败，继续执行后续操作..."
    }
    # 加载 nvm
    export NVM_DIR="$PROJECT_DIR/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    # 安装 Node.js 18
    nvm install 18 || {
        echo "⚠️ 安装 Node.js 18 失败，继续执行后续操作..."
    }
    # 安装项目依赖
    echo "📦 安装 npm 依赖..."
    npm install || {
        echo "⚠️ 安装 npm 依赖失败，继续执行后续操作..."
    }
fi

# 确保 Node 环境可用
export NVM_DIR="$PROJECT_DIR/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 创建 autostart 文件夹
mkdir -p "$HOME/.config/autostart" || {
    echo "⚠️ 创建 autostart 目录失败，继续执行后续操作..."
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
echo "⚠️ 注意：部分操作可能失败，请检查项目目录内容并手动修复（如 git 克隆或 npm install）。"
