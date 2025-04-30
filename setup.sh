#!/bin/bash
set -e
set -x  # 调试输出每一步

echo "开始安装项目..."

# 获取当前目录
PROJECT_DIR=$(pwd)
echo "项目目录: $PROJECT_DIR"

# 创建临时目录并拉取固定 GitHub 项目
echo "拉取项目到当前目录（覆盖同名文件）..."
TEMP_DIR=$(mktemp -d)

# 固定使用你提供的地址
TAR_URL="https://github.com/Limkon/liuyanshi/archive/refs/heads/master.tar.gz"
echo "下载链接: $TAR_URL"

# 下载并解压 master 分支压缩包
curl -L "$TAR_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1

# 删除 .github 文件夹
rm -rf "$TEMP_DIR/.github"

# 拷贝所有内容覆盖到当前目录
cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"
rm -rf "$TEMP_DIR"

# 检查 Node.js 是否安装
if ! command -v node &> /dev/null; then
    echo "Node.js 未检测到，开始安装 nvm 和 Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR="$PROJECT_DIR/.nvm" bash
    export NVM_DIR="$PROJECT_DIR/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
else
    echo "Node.js 已安装，版本：$(node -v)"
fi

# 确保 nvm 环境可用
export NVM_DIR="$PROJECT_DIR/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 安装项目依赖
echo "安装 npm 依赖..."
npm install

# 创建 autostart 文件夹
mkdir -p "$HOME/.config/autostart"

# 配置开机启动
echo "配置开机启动..."
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

echo "✅ 安装完成！下次开机登录后会自动启动服务器！"
