#!/bin/bash
set -e

echo "🚀 开始安装项目..."

# GitHub 仓库信息
GITHUB_USER="Limkon"
REPO_NAME="TCR"
BRANCH="master"

echo "👤 GitHub 用户名: $GITHUB_USER"
echo "📦 仓库名: $REPO_NAME"
echo "🌿 分支: $BRANCH"

# 下载链接
TAR_URL="https://github.com/$GITHUB_USER/$REPO_NAME/archive/refs/heads/$BRANCH.tar.gz"
echo "📦 下载链接: $TAR_URL"

# 验证下载链接是否可访问
if ! curl -fsSL --head "$TAR_URL" >/dev/null 2>&1; then
    echo "❌ 错误：无法访问 $TAR_URL，可能是网络问题或链接无效"
    exit 1
fi

# 获取当前脚本执行的目录作为项目目录的基准
PROJECT_DIR=$(pwd)
echo "📁 项目将安装到目录: $PROJECT_DIR"

# 创建临时目录并解压项目
TEMP_DIR=$(mktemp -d)
echo "📂 创建临时目录: $TEMP_DIR"

echo "⏳ 正在下载并解压项目..."
if ! curl -fsSL "$TAR_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1; then
    echo "❌ 错误：下载或解压 $TAR_URL 失败"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo "✅ 项目解压完成。"

# 删除 .github 目录（如果存在）
if [ -d "$TEMP_DIR/.github" ]; then
    echo "🗑️ 删除 $TEMP_DIR/.github 目录..."
    rm -rf "$TEMP_DIR/.github"
fi

# 将临时目录中的所有内容复制到项目目录
echo "⏳ 正在复制文件到 $PROJECT_DIR ..."
cd "$TEMP_DIR"
if find . -maxdepth 1 -mindepth 1 -exec cp -rft "$PROJECT_DIR" '{}' +; then
    echo "✅ 文件已成功复制到 $PROJECT_DIR"
else
    echo "❌ 错误：复制文件到 $PROJECT_DIR 失败"
    cd "$PROJECT_DIR"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 清理临时目录
echo "🗑️ 清理临时目录 $TEMP_DIR ..."
rm -rf "$TEMP_DIR"
cd "$PROJECT_DIR"

echo "🔧 检查系统 Node.js 和 npm 环境..."

if ! command -v node &> /dev/null; then
    echo "❌ 错误: Node.js 未安装。请先安装 Node.js (推荐 v18 或更高版本) 然后重试。"
    echo "    例如，在 Ubuntu/Debian 上: sudo apt update && sudo apt install nodejs npm"
    echo "    或从 NodeSource: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ 错误: npm 未安装。请确保 npm 与 Node.js 一起安装。"
    exit 1
fi

NODE_VERSION_OUTPUT=$(node -v)
NODE_MAJOR_VERSION=$(echo "$NODE_VERSION_OUTPUT" | sed -E 's/v([0-9]+)\..*//')
DESIRED_MAJOR_VERSION="18"

if [ "$NODE_MAJOR_VERSION" -lt "$DESIRED_MAJOR_VERSION" ]; then
    echo "❌ 错误: Node.js 版本过低。需要 v$DESIRED_MAJOR_VERSION 或更高版本, 当前版本: $NODE_VERSION_OUTPUT"
    echo "    请升级您的 Node.js 版本。"
    exit 1
else
    echo "✅ Node.js 版本检查通过: $NODE_VERSION_OUTPUT (主版本: $NODE_MAJOR_VERSION)"
fi

echo "🧩 当前使用 Node: $(which node) (版本: $NODE_VERSION_OUTPUT)"
echo "🧩 当前使用 npm: $(which npm) (版本: $(npm -v))"

if [ ! -f "$PROJECT_DIR/package.json" ]; then
    echo "⚠️  警告: $PROJECT_DIR/package.json 未找到。将创建一个空的 package.json。"
    echo "{ "name": "$REPO_NAME", "version": "1.0.0", "description": "Downloaded from GitHub", "main": "server.js", "scripts": { "start": "node server.js" } }" > "$PROJECT_DIR/package.json"
else
    echo "👍 $PROJECT_DIR/package.json 已存在。"
fi

echo "📦 正在安装依赖 ..."
if npm install; then
    echo "✅ 依赖安装成功。"
else
    echo "❌ 依赖安装过程中发生错误。"
    exit 1
fi

NODE_EXEC_PATH=$(command -v node)
if [ -z "$NODE_EXEC_PATH" ]; then
    echo "❌ 致命错误：无法找到 node 执行路径，即使之前检查通过。这不应该发生。"
    exit 1
fi

echo "🚀 准备创建开机启动项..."
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

AUTOSTART_FILE="$AUTOSTART_DIR/$REPO_NAME-startup.desktop"
echo "📝 创建开机启动项文件: $AUTOSTART_FILE"

cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$REPO_NAME Server
Comment=Start $REPO_NAME Server automatically at login
Exec=bash -c "cd '$PROJECT_DIR' && '$NODE_EXEC_PATH' server.js"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Icon=application-default-icon
Terminal=false
EOF

chmod +x "$AUTOSTART_FILE"

echo "✅ 项目安装完成！"
echo "👍 开机启动项已创建于: $AUTOSTART_FILE"
echo "    (可能需要重新登录或重启系统以使开机启动生效)"
echo "🚀 手动启动服务器: cd "$PROJECT_DIR" && npm start"
echo "    (如果 package.json 中没有 'start' 脚本, 请使用: cd "$PROJECT_DIR" && node server.js)"
