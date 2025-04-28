#!/bin/bash
set -e

echo "🚀 开始安装 TCR 聊天室项目..."

# 获取当前目录
PROJECT_DIR=$(pwd)

# 清理本地 Git 仓库（强制忽略本地是否为仓库）
echo "🗑️ 清理本地 Git 仓库（如果存在）..."
rm -rf "$PROJECT_DIR/.git"

# 拉取 TCR 项目到临时目录并覆盖本地文件
echo "📥 拉取 TCR 项目到当前目录（覆盖同名文件）..."
TEMP_DIR=$(mktemp -d)
# 使用 curl 下载仓库压缩包（避免 Git 权限问题）
curl -L https://github.com/Limkon/TCR/archive/refs/heads/main.tar.gz | tar -xz -C "$TEMP_DIR" --strip-components=1
# 强制覆盖本地文件
cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"
rm -rf "$TEMP_DIR"

# 初始化 Git 仓库（仅用于后续更新）
echo "🔄 初始化 Git 仓库以便后续更新..."
cd "$PROJECT_DIR"
git init -q
git remote add origin https://github.com/Limkon/TCR.git
git fetch origin -q
git checkout main -q || {
    echo "❌ 无法检出 main 分支，请检查远程仓库分支。"
    exit 1
}

# 检查 Node.js 是否安装
if ! command -v node &> /dev/null; then
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
