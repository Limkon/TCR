#!/bin/bash
set -e
set -x

echo -e "\e[1;34m🚀 开始安装项目...\e[0m"

# 获取当前路径
PROJECT_DIR=$(pwd)
echo "📁 项目目录: $PROJECT_DIR"

# --- 自动获取 GitHub tar.gz 地址 ---
RAW_URL=$(grep 'url =' .git/config | awk '{print $3}')

if [[ "$RAW_URL" == git@* ]]; then
  GIT_URL="https://github.com/$(echo "$RAW_URL" | sed 's/git@github.com:\(.*\)\.git/\1/')"
else
  GIT_URL="${RAW_URL%.git}"
fi

BRANCH=$(grep -A1 "\[branch" .git/config | grep merge | head -n1 | sed 's/.*\///')
[ -z "$BRANCH" ] && BRANCH="master"

TAR_URL="$GIT_URL/archive/refs/heads/$BRANCH.tar.gz"
echo "🌐 下载地址: $TAR_URL"

# --- 下载并覆盖项目 ---
TEMP_DIR=$(mktemp -d)
curl -L "$TAR_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1
rm -rf "$TEMP_DIR/.github"
cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"
rm -rf "$TEMP_DIR"

# --- 安装 Node.js（如未安装） ---
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "🔧 Node.js 未安装，安装 nvm 和 Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$PROJECT_DIR/.nvm" bash
    export NVM_DIR="$PROJECT_DIR/.nvm"
    mkdir -p "$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
fi

# --- 确保 nvm 环境可用 ---
export NVM_DIR="$PROJECT_DIR/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# --- 安装依赖 ---
echo "📦 安装依赖..."
npm install
npm install axios --save

# --- 配置开机自启动 ---
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

# --- 启动服务 ---
echo "🟢 正在启动服务..."
nohup bash -c "cd '$PROJECT_DIR' && source '$PROJECT_DIR/.nvm/nvm.sh' && node server.js" &

echo -e "\e[1;32m✅ 安装完成！服务已启动。\e[0m"
