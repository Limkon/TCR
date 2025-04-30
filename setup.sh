#!/bin/bash
set -e
set -x  # 开启调试输出

echo -e "\e[1;34m🚀 开始安装项目...\e[0m"

# 获取当前项目目录
PROJECT_DIR=$(pwd)
echo "📁 项目目录: $PROJECT_DIR"

# 临时目录用于拉取代码
TEMP_DIR=$(mktemp -d)
TAR_URL="https://github.com/Limkon/liuyanshi/archive/refs/heads/master.tar.gz"
echo "🌐 下载地址: $TAR_URL"

# 下载并解压
curl -L "$TAR_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1

# 清理不需要的 GitHub 配置
rm -rf "$TEMP_DIR/.github"

# 拷贝内容覆盖当前目录
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

# 安装项目依赖
echo "📦 安装依赖..."
npm install

# 安装 axios 模块
echo "📦 安装 axios..."
npm install axios --save

# 配置开机启动
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

# 可选：首次立即运行一次服务器（后台运行）
echo "🚀 启动服务器（后台运行）..."
nohup bash -c "cd \"$PROJECT_DIR\" && source \"$PROJECT_DIR/.nvm/nvm.sh\" && node server.js" > "$PROJECT_DIR/server.log" 2>&1 &

echo -e "\e[1;32m✅ 安装完成！下次登录会自动启动服务器。\e[0m"
echo -e "📄 日志文件位置：$PROJECT_DIR/server.log"
