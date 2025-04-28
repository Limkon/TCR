#!/bin/bash
set -e

echo "🚀 正在开始安装 TCR 聊天室项目..."

# 获取当前目录
PROJECT_DIR=$(pwd)

# 强制设置 Git safe.directory 以避免所有权问题
echo "🔒 配置 Git safe.directory 以避免所有权问题..."
git config --global --add safe.directory "$PROJECT_DIR" || {
    echo "⚠️ 无法设置 Git safe.directory，尝试临时禁用所有权检查..."
    export GIT_CEILING_DIRECTORIES="$PROJECT_DIR/.."
}

# 动态检测远程仓库的默认分支
get_default_branch() {
    local repo_url=$1
    # 获取 HEAD 指向的分支
    default_branch=$(git ls-remote --symref "$repo_url" HEAD | grep '^ref:' | sed 's|.*refs/heads/\(.*\)\tHEAD|\1|')
    if [ -z "$default_branch" ]; then
        echo "❌ 无法检测默认分支，假设为 master"
        echo "master"
    else
        echo "$default_branch"
    fi
}

# 检查 Git 仓库状态并处理未跟踪文件
handle_git_status() {
    echo "🔍 检查 Git 工作区状态..."
    if git status --porcelain | grep -q "^??"; then
        echo "⚠️ 检测到未跟踪文件："
        git status --porcelain | grep "^??" | sed 's/^?? //'
        echo "这些文件可能被 git pull 覆盖。请选择操作："
        echo "1) 备份未跟踪文件"
        echo "2) 删除未跟踪文件"
        echo "3) 退出以手动处理"
        echo "4) 强制覆盖（警告：将丢失所有未提交的更改！）"
        read -p "请输入选项 (1/2/3/4): " choice
        case $choice in
            1)
                echo "📂 备份未跟踪文件到 backup_$(date +%F_%H-%M-%S)..."
                backup_dir="$PROJECT_DIR/backup_$(date +%F_%H-%M-%S)"
                mkdir -p "$backup_dir"
                git status --porcelain | grep "^??" | sed 's/^?? //' | while read -r file; do
                    cp -r "$file" "$backup_dir/"
                done
                git clean -f
                ;;
            2)
                echo "🗑️ 删除未跟踪文件..."
                git clean -f
                ;;
            3)
                echo "🚪 退出脚本，请手动处理未跟踪文件后重新运行。"
                echo "建议运行：git status"
                exit 1
                ;;
            4)
                echo "⚠️ 警告：强制覆盖将删除所有未跟踪文件和本地修改！"
                read -p "确认继续？(y/N): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    echo "🔄 强制覆盖本地更改..."
                    git reset --hard
                    git clean -fd
                else
                    echo "🚪 已取消强制覆盖，退出。"
                    exit 1
                fi
                ;;
            *)
                echo "❌ 无效选项，退出。"
                exit 1
                ;;
        esac
    fi
}

# 检查当前目录是否已是 Git 仓库
REPO_URL="https://github.com/Limkon/TCR.git"
DEFAULT_BRANCH=$(get_default_branch "$REPO_URL")

if [ -d "$PROJECT_DIR/.git" ]; then
    echo "📁 当前目录已经是 Git 仓库，尝试更新..."
    cd "$PROJECT_DIR"
    handle_git_status
    git pull origin "$DEFAULT_BRANCH" || {
        echo "❌ 无法更新仓库，请检查 Git 配置或手动运行以下命令："
        echo "cd $PROJECT_DIR && git config --global --add safe.directory $PROJECT_DIR && git pull origin $DEFAULT_BRANCH"
        exit 1
    }
else
    # 检查是否存在 TCR 项目文件（如 package.json）以避免重复克隆
    if [ -f "$PROJECT_DIR/package.json" ]; then
        echo "📁 检测到 TCR 项目文件，尝试更新现有项目..."
        cd "$PROJECT_DIR"
        git init 2>/dev/null || true
        git remote set-url origin "$REPO_URL" 2>/dev/null || git remote add origin "$REPO_URL"
        git fetch origin
        handle_git_status
        git checkout "$DEFAULT_BRANCH" -- . || {
            echo "❌ 无法检出 $DEFAULT_BRANCH 分支，请检查仓库分支。"
            exit 1
        }
    else
        # 克隆 TCR 项目到临时目录，然后复制文件到当前目录
        echo "📥 追加 TCR 项目到当前目录（覆盖同名文件）..."
        TEMP_DIR=$(mktemp -d)
        git clone "$REPO_URL" "$TEMP_DIR"
        # 复制所有文件（包括隐藏文件）到当前目录，强制覆盖同名文件
        cp -rf "$TEMP_DIR"/. "$PROJECT_DIR"
        # 初始化 Git 仓库
        cd "$PROJECT_DIR"
        git init 2>/dev/null || true
        git remote add origin "$REPO_URL"
        git fetch origin
        git checkout "$DEFAULT_BRANCH" -- . || {
            echo "❌ 无法检出 $DEFAULT_BRANCH 分支，请检查仓库分支。"
            exit 1
        }
        rm -rf "$TEMP_DIR"
    fi
fi

# 检查 node 是否安装
if ! command -v node &> /dev/null
then
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
