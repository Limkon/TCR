#!/bin/bash
set -e

echo "🚀 开始安装项目..."

# 获取当前目录
PROJECT_DIR=$(pwd)
echo "📁 项目目录: $PROJECT_DIR"

# 检查是否传入 SCRIPT_URL
SCRIPT_URL="$1"
if [[ -z "$SCRIPT_URL" ]]; then
    echo "❌ 错误：请通过参数传入 setup.sh 的 GitHub 原始地址（raw.githubusercontent.com/...）"
    exit 1
fi

# 验证 SCRIPT_URL 是否为 GitHub raw URL
if [[ ! "$SCRIPT_URL" =~ ^https://raw.githubusercontent.com/[^/]+/[^/]+/ ]]; then
    echo "❌ 错误：SCRIPT_URL 格式不正确，必须是 GitHub raw URL（例如 https://raw.githubusercontent.com/USER/REPO/BRANCH/setup.sh）"
    exit 1
fi

# 提取 GitHub 用户名、仓库名、分支
# 使用字符串操作提取
TEMP_URL="${SCRIPT_URL#https://raw.githubusercontent.com/}"
IFS='/' read -r -a PARTS <<< "$TEMP_URL"
GITHUB_USER="${PARTS[0]}"
REPO_NAME="${PARTS[1]}"

# 拼接分支路径，跳过最后一个元素（setup.sh）
BRANCH_PATH=""
for i in $(seq 2 $(( ${#PARTS[@]} - 2 )) ); do
    BRANCH_PATH="${BRANCH_PATH}/${PARTS[$i]}"
done
BRANCH="${BRANCH_PATH#/}" # 移除开头的斜杠

echo "👤 GitHub 用户名: $GITHUB_USER"
echo "📦 仓库名: $REPO_NAME"
echo "🌿 分支: $BRANCH"

# 构造下载地址
TAR_URL="https://github.com/$GITHUB_USER/$REPO_NAME/archive/refs/heads/$BRANCH.tar.gz"
echo "📦 下载链接: $TAR_URL"

# 验证 TAR_URL 是否有效
if ! curl -fsSL --head "$TAR_URL" >/dev/null 2>&1; then
    echo "❌ 错误：无法访问 $TAR_URL，可能是仓库、分支不存在或网络问题"
    exit 1
fi

# 创建临时目录并解压项目文件
TEMP_DIR=$(mktemp -d)
echo "📂 临时目录: $TEMP_DIR"
if ! curl -fsSL "$TAR_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1; then
    echo "❌ 错误：下载或解压 $TAR_URL 失败"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 删除不需要的 .github 目录并复制文件
rm -rf "$TEMP_DIR/.github"
if ! cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"; then
    echo "❌ 错误：复制文件到 $PROJECT_DIR 失败"
    rm -rf "$TEMP_DIR"
    exit 1
fi
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
if ! npm install; then
    echo "⚠️ npm install 失败，继续安装 axios"
fi

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
