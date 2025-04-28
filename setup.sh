#!/bin/bash
set -e

echo "🚀 正在开始安装 TCR 聊天室项目..."

# 获取当前目录
PROJECT_DIR=$(pwd)

# 检查当前目录是否已是 Git 仓库
if [ -d "$PROJECT_DIR/.git" ]; then
    echo "📁 当前目录已经是 Git 仓库，尝试更新..."
    cd "$PROJECT_DIR"
    git pull origin master || {
        echo "❌ 无法更新仓库，请检查 Git 配置或手动处理。"
        exit 1
    }
else
    # 目录不为空或为空，自动清空
    echo "🗑️ 清空当前目录 ($PROJECT_DIR)..."
    rm -rf "$PROJECT_DIR"/*
    rm -rf "$PROJECT_DIR"/.[!.]*
    # 克隆仓库到当前目录
    echo "📥 克隆项目到当前目录..."
    git clone https://github.com/Limkon/TCR.git "$PROJECT_DIR"
    TEMP_DIR=$(mktemp -d)
    mv "$PROJECT_DIR/.git" "$TEMP_DIR/.git"
    rm -rf "$PROJECT_DIR"/*
    mv "$TEMP_DIR/.git" "$PROJECT_DIR/.git"
    git checkout .
    rmdir "$TEMP_DIR"
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
