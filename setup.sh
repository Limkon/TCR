#!/bin/bash
set -e

echo -e "\e[1;34m🚀 开始安装项目...\e[0m"

# 获取当前目录
PROJECT_DIR=$(pwd)
echo "📁 项目目录: $PROJECT_DIR"

# 指定 GitHub 仓库地址
GITHUB_USER="Limkon"
REPO_NAME="TCR"
BRANCH="master"

# 拼接 tar.gz 下载地址
TAR_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}/archive/refs/heads/${BRANCH}.tar.gz"
echo "🌐 下载地址: $TAR_URL"

# 创建临时目录并拉取文件
TEMP_DIR=$(mktemp -d)
curl -fsSL "$TAR_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1
rm -rf "$TEMP_DIR/.github"
cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"
rm -rf "$TEMP_DIR"

# 安装 Node.js（如未安装）
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "🔧 安装 Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$PROJECT_DIR/.nvm" bash
    export NVM_DIR="$PROJECT_DIR/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
fi

# 加载 nvm 环境
export NVM_DIR="$PROJECT_DIR/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装依赖
echo "📦 安装依赖..."
npm install
npm install axios --save

# 设置开机自启
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/tcr-startup.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=bash -c "cd '$PROJECT_DIR' && source '$PROJECT_DIR/.nvm/nvm.sh' && node server.js"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Chatroom Server
Comment=Start Server automatically
EOF

# 启动服务
echo "🟢 启动服务器..."
nohup bash -c "cd '$PROJECT_DIR' && source '$PROJECT_DIR/.nvm/nvm.sh' && node server.js" >/dev/null 2>&1 &

echo -e "\e[1;32m✅ 安装完成！服务已启动。\e[0m"
