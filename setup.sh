#!/bin/bash
set -e
set -x  # 输出每一步

echo "🚀 开始安装项目..."

# 获取当前目录
PROJECT_DIR=$(pwd)
echo "📁 项目目录: $PROJECT_DIR"

# 获取 GitHub 原始地址（通过运行时参数传入）
if [ -z "$1" ]; then
  echo "❌ 错误：请通过参数传入 setup.sh 的 GitHub 原始地址（raw.githubusercontent.com/...）"
  exit 1
fi

RAW_URL="$1"
echo "🌐 脚本原始地址: $RAW_URL"

# 提取用户名、仓库名和分支
GITHUB_USER=$(echo "$RAW_URL" | cut -d'/' -f4)
REPO_NAME=$(echo "$RAW_URL" | cut -d'/' -f5)
BRANCH=$(echo "$RAW_URL" | cut -d'/' -f6)

TAR_URL="https://github.com/$GITHUB_USER/$REPO_NAME/archive/refs/heads/$BRANCH.tar.gz"
echo "📦 下载链接: $TAR_URL"

# 下载并解压
TEMP_DIR=$(mktemp -d)
curl -L "$TAR_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1
rm -rf "$TEMP_DIR/.github"
cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"
rm -rf "$TEMP_DIR"

# 检查 Node.js 是否安装
if ! command -v node &> /dev/null; then
    echo "Node.js 未检测到，安装 nvm 和 Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$PROJECT_DIR/.nvm" bash
    export NVM_DIR="$PROJECT_DIR/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
else
    echo "✅ Node.js 已安装，版本：$(node -v)"
fi

# 加载 nvm 环境
export NVM_DIR="$PROJECT_DIR/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装项目依赖
echo "📦 安装依赖..."
npm install

# 确保安装 axios
echo "📦 安装 axios..."
npm install axios

# 创建开机自启配置
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
