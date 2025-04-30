#!/bin/bash
set -e

echo "🚀 开始安装项目..."

# 获取当前目录
PROJECT_DIR=$(pwd)
echo "📁 项目目录: $PROJECT_DIR"

# 自动推导 GitHub 原始脚本 URL
SCRIPT_URL="$1"
if [[ -z "$SCRIPT_URL" ]]; then
  echo "❌ 错误：请通过参数传入 setup.sh 的 GitHub 原始地址（raw.githubusercontent.com/...）"
  exit 1
fi

# 提取 GitHub 用户名、仓库名、分支
GITHUB_USER=$(echo "$SCRIPT_URL" | cut -d'/' -f4)
REPO_NAME=$(echo "$SCRIPT_URL" | cut -d'/' -f5)
BRANCH=$(echo "$SCRIPT_URL" | cut -d'/' -f6)

# 根据 GitHub 信息构造下载地址
TAR_URL="https://github.com/$GITHUB_USER/$REPO_NAME/archive/refs/heads/$BRANCH.tar.gz"
echo "📦 下载链接: $TAR_URL"

# 创建临时目录并解压项目文件
TEMP_DIR=$(mktemp -d)
curl -fsSL "$TAR_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1
rm -rf "$TEMP_DIR/.github"
cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"
rm -rf "$TEMP_DIR"

# 检查 Node.js 是否安装
if ! command -v node &> /dev/null; then
  echo "📦 安装 Node.js（通过 nvm）..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$PROJECT_DIR/.nvm" bash
  export NVM_DIR="$PROJECT_DIR/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install 18
else
  echo "✅ Node.js 已安装：$(node -v)"
fi

# 加载 nvm
export NVM_DIR="$PROJECT_DIR/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装依赖
echo "📦 安装依赖..."
npm install || echo "⚠️ npm install 失败，继续安装 axios"

# 安装 axios
echo "📦 安装 axios..."
npm install axios

# 创建开机启动项
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/tcr-startup.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=bash -c "cd $PROJECT_DIR && source $PROJECT_DIR/.nvm/nvm.sh && node server.js"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Chatroom Server
Comment=Start Server automatically
EOF

echo "✅ 安装完成！系统重启后将自动启动服务器。"
