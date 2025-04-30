#!/bin/bash
set -e
set -x

echo -e "\e[1;34m🚀 开始安装项目...\e[0m"

# 获取当前目录
PROJECT_DIR=$(pwd)
echo "📁 项目目录: $PROJECT_DIR"

# 固定远程 tar.gz 地址（可替换为你自己的）
TAR_URL="https://github.com/Limkon/liuyanshi/archive/refs/heads/master.tar.gz"
echo "🌐 下载链接: $TAR_URL"

# 拉取并解压项目文件
TEMP_DIR=$(mktemp -d)
curl -L "$TAR_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1
rm -rf "$TEMP_DIR/.github"
cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"
rm -rf "$TEMP_DIR"

# 检查并安装 Node.js（使用 nvm）
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "🔧 未检测到 Node.js，正在安装 nvm 和 Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$PROJECT_DIR/.nvm" bash
    export NVM_DIR="$PROJECT_DIR/.nvm"
    mkdir -p "$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
fi

# 启用 nvm 环境
export NVM_DIR="$PROJECT_DIR/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装依赖
npm install
npm install axios --save

# 配置自动启动
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/tcr-startup.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=bash -c "cd \"$PROJECT_DIR\" && source \"$PROJECT_DIR/.nvm/nvm.sh\" && node server.js >> server.log 2>&1"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Chatroom Server
Comment=Start Server automatically
EOF

# 启动一次服务器
nohup bash -c "cd \"$PROJECT_DIR\" && source \"$PROJECT_DIR/.nvm/nvm.sh\" && node server.js" > "$PROJECT_DIR/server.log" 2>&1 &

echo -e "\e[1;32m✅ 安装完成！服务器已启动，日志记录在 server.log。\e[0m"
