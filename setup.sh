#!/bin/bash
set -e
set -x  # 开启调试输出

echo -e "\e[1;34m🚀 开始安装项目...\e[0m"

# 获取当前项目目录
PROJECT_DIR=$(pwd)
echo "📁 项目目录: $PROJECT_DIR"

# 获取当前 GitHub 仓库地址
echo "🔍 获取 GitHub 仓库地址..."
GIT_URL=$(git config --get remote.origin.url)

if [[ -z "$GIT_URL" ]]; then
    echo -e "\e[1;31m❌ 没有检测到 git 仓库，请先执行 git init 并添加 remote。\e[0m"
    exit 1
fi

if [[ "$GIT_URL" == git@* ]]; then
  GIT_URL="https://github.com/$(echo "$GIT_URL" | sed 's/git@github.com:\(.*\)\.git/\1/')"
else
  GIT_URL="${GIT_URL%.git}"
fi

# 获取当前分支（默认为 master）
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "master")
TAR_URL="$GIT_URL/archive/refs/heads/$BRANCH.tar.gz"
echo "🌐 下载链接: $TAR_URL"

# 创建临时目录并拉取压缩包
TEMP_DIR=$(mktemp -d)
curl -L "$TAR_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1

# 清理 .github 等不需要的内容
rm -rf "$TEMP_DIR/.github"

# 拷贝内容覆盖到当前目录
cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"
rm -rf "$TEMP_DIR"

# 检查 Node.js 和 npm
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo -e "\e[1;33m🔧 Node.js 未检测到，正在安装 nvm 和 Node.js...\e[0m"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$PROJECT_DIR/.nvm" bash
    export NVM_DIR="$PROJECT_DIR/.nvm"
    mkdir -p "$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
else
    echo "✅ Node.js 已安装，版本：$(node -v)"
fi

# 确保 nvm 环境可用
export NVM_DIR="$PROJECT_DIR/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装依赖
echo "📦 安装依赖..."
npm install

# 安装 axios
echo "📦 安装 axios..."
npm install axios --save

# 自动启动配置
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
AUTOSTART_FILE="$AUTOSTART_DIR/tcr-startup.desktop"

echo "⚙️ 配置开机自启..."
cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Exec=bash -c "cd \"$PROJECT_DIR\" && source \"$PROJECT_DIR/.nvm/nvm.sh\" && node server.js >> server.log 2>&1"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Chatroom Server
Comment=Start Server automatically
EOF

chmod +x "$AUTOSTART_FILE"

# 启动一次服务
echo "🚀 启动服务器（后台运行）..."
nohup bash -c "cd \"$PROJECT_DIR\" && source \"$PROJECT_DIR/.nvm/nvm.sh\" && node server.js" > "$PROJECT_DIR/server.log" 2>&1 &

echo -e "\e[1;32m✅ 安装完成！服务器将自动启动，日志位于：$PROJECT_DIR/server.log\e[0m"
