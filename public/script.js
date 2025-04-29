let ws;
let username = '';
let joined = false;

// 连接 WebSocket
function connect() {
    const roomId = location.pathname.split('/')[1] || 'default';
    ws = new WebSocket(`wss://${location.host}/${roomId}`);

    ws.onopen = () => {
        console.log('连接成功');
    };

    ws.onmessage = (event) => {
        try {
            const data = JSON.parse(event.data);
            switch (data.type) {
                case 'userList':
                    updateUserList(data.users);
                    break;
                case 'message':
                    addMessage(data.username, data.message);
                    break;
                case 'joinError':
                    alert('用户名已存在，请重新输入');
                    joined = false;
                    username = '';
                    document.getElementById('username').value = '';
                    break;
                case 'clearChat':
                    clearChatWithTip();
                    break;
                case 'clearChatBeforeDisconnect':
                    clearChatWithTip();
                    break;
                default:
                    console.warn('未知消息类型:', data);
                    break;
            }
        } catch (error) {
            console.error('消息解析失败:', error);
        }
    };

    ws.onclose = () => {
        console.log('连接关闭');
    };
}

// 加入聊天
document.getElementById('join').onclick = () => {
    const input = document.getElementById('username');
    const name = input.value.trim();
    if (!name) {
        alert('请输入用户名');
        return;
    }
    if (joined) {
        alert('已加入聊天室');
        return;
    }
    username = name;
    ws.send(JSON.stringify({ type: 'join', username }));
    joined = true;
    document.getElementById('message').disabled = false;
    document.getElementById('send').disabled = false;
};

// 发送消息
document.getElementById('send').onclick = () => {
    const input = document.getElementById('message');
    const msg = input.value.trim();
    if (!msg) return;
    ws.send(JSON.stringify({ type: 'message', message: msg }));
    input.value = '';
};

// 回车键快捷发送
document.getElementById('message').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        document.getElementById('send').click();
    }
});

// 主题切换
document.getElementById('theme-toggle').onclick = () => {
    document.body.classList.toggle('dark-mode');
    document.body.classList.toggle('light-mode');
};

// 用户列表显示切换
document.getElementById('userlist-toggle').onclick = () => {
    document.getElementById('userlist').classList.toggle('hidden');
};

// 添加聊天消息
function addMessage(user, message) {
    const chat = document.getElementById('chat');
    const div = document.createElement('div');
    div.className = user === username ? 'message-right' : 'message-left';
    div.textContent = `${user}: ${message}`;
    chat.appendChild(div);
    chat.scrollTop = chat.scrollHeight;
}

// 更新在线用户列表
function updateUserList(users) {
    const list = document.getElementById('userlist');
    list.innerHTML = '<h3>在线用户</h3>';
    users.forEach(user => {
        const div = document.createElement('div');
        div.textContent = user;
        list.appendChild(div);
    });
}

// 清空聊天并提示
function clearChatWithTip() {
    const chat = document.getElementById('chat');
    chat.innerHTML = '';
    const tip = document.createElement('div');
    tip.className = 'message-left';
    tip.textContent = '系统提示：聊天记录已清空';
    chat.appendChild(tip);
}

connect();
