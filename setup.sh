#!/bin/bash
set -e

echo "🚀 正在开始安装 TCR 聊天室项目..."

# 设置项目目录
PROJECT_DIR="$HOME/TCR"

# 克隆仓库
if [ ! -d "$PROJECT_DIR" ]; then
    echo "📥 克隆项目到 $PROJECT_DIR..."
    git clone https://github.com/Limkon/TCR.git "$PROJECT_DIR"
else
    echo "📁 项目目录已经存在，跳过克隆步骤。"
fi

# 进入项目目录
cd "$PROJECT_DIR"

# 检查 node 是否安装
if ! command -v node &> /dev/null
then
    echo "🔧 Node.js 未检测到，开始安装 nvm 和 Node.js..."
    
    # 安装 nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # 加载 nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # 安装 Node.js 18
    nvm install 18
else
    echo "✅ Node.js 已安装，版本：$(node -v)"
fi

# 确保 Node 环境可用
export NVM_DIR="$HOME/.nvm"
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
Exec=bash -c "cd $PROJECT_DIR && source \$HOME/.nvm/nvm.sh && node server.js"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=TCR Chatroom Server
Comment=Start TCR Server automatically
EOF

echo "🎉 安装完成！下次开机登录后会自动启动 TCR 聊天室服务器！"
echo "📍 项目目录: $PROJECT_DIR"
