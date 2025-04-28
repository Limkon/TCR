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

# 检查当前目录是否已是 Git 仓库
if [ -d "$PROJECT_DIR/.git" ]; then
    echo "📁 当前目录已经是 Git 仓库，尝试更新..."
    cd "$PROJECT_DIR"
    git pull origin master || git pull origin main || {
        echo "❌ 无法更新仓库，请检查 Git 配置或手动运行以下命令："
        echo "cd $PROJECT_DIR && git config --global --add safe.directory $PROJECT_DIR && git pull origin master"
        exit 1
    }
else
    # 检查是否存在 TCR 项目文件（如 package.json）以避免重复克隆
    if [ -f "$PROJECT_DIR/package.json" ]; then
        echo "📁 检测到 TCR 项目文件，尝试更新现有项目..."
        cd "$PROJECT_DIR"
        git init 2>/dev/null || true
        git remote set-url origin https://github.com/Limkon/TCR.git 2>/dev/null || git remote add origin https://github.com/Limkon/TCR.git
        git fetch origin
        git checkout master -- . || git checkout main -- . || {
            echo "❌ 无法检出 master 或 main 分支，请检查仓库分支。"
            exit 1
        }
    else
        # 克隆 TCR 项目到临时目录，然后复制文件到当前目录
        echo "📥 追加 TCR 项目到当前目录（覆盖同名文件）..."
        TEMP_DIR=$(mktemp -d)
        git clone https://github.com/Limkon/TCR.git "$TEMP_DIR"
        # 复制所有文件（包括隐藏文件）到当前目录，强制覆盖同名文件
        cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"
        # 初始化 Git 仓库
        cd "$PROJECT_DIR"
        git init 2>/dev/null || true
        git remote add origin https://github.com/Limkon/TCR.git
        git fetch origin
        git checkout master -- . 2>/dev/null || git checkout main -- . 2>/dev/null || {
            echo "❌ 无法检出 master 或 main 分支，请检查仓库分支。"
            exit 1
        }
        rm -rf "$TEMP_DIR"
    fi
fi

# 检查 node 是否安装
if ! command -v node &> /dev/null
then
    echo "🔧 Node.js 未检测到，开始安装 nvm 和 Node.js..."
    
    # 安装 nvm 到当前目录
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$PROJECT_DIR/.nvm" bash

    # 加载 nvm
    export NVM_DIR="$PROJECT_DIR/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # 安装 Node.js 18
    nvm install 18
else
    echo "✅ Node.js 已安装，版本：$(node -v)"
fi

# 确保 Node 环境可用
export NVM_DIR="$PROJECT_DIR/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装项目依赖
echo "📦 安装 npm 依赖..."
npm install

# 创建 autostart 文件夹
mkdir -p "$HOME/.config/autostart"

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
