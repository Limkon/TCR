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
            console.log('收到消息:', data);
            switch (data.type) {
                case 'userList':
                    console.log('更新用户列表:', data.users);
                    updateUserList(data.users);
                    // 备用机制：如果用户列表包含当前用户名，确认加入成功
                    if (!joined && data.users.includes(username)) {
                        console.log('通过 userList 确认加入成功，启用消息输入框');
                        joined = true;
                        document.getElementById('message').disabled = false;
                        document.getElementById('send').disabled = false;
                        document.getElementById('username-label').style.display = 'none';
                        document.getElementById('username').style.display = 'none';
                        document.getElementById('join').style.display = 'none';
                    }
                    break;
                case 'message':
                    console.log('收到聊天消息:', data.message);
                    addMessage(data.username, data.message);
                    break;
                case 'joinSuccess':
                    console.log('收到 joinSuccess，启用消息输入框');
                    joined = true;
                    document.getElementById('message').disabled = false;
                    document.getElementById('send').disabled = false;
                    document.getElementById('username-label').style.display = 'none';
                    document.getElementById('username').style.display = 'none';
                    document.getElementById('join').style.display = 'none';
                    break;
                case 'joinError':
                    console.log('加入失败:', data.message);
                    alert(data.message || '用户名已存在，请重新输入');
                    joined = false;
                    username = '';
                    document.getElementById('username').value = '';
                    document.getElementById('username-label').style.display = 'block';
                    document.getElementById('username').style.display = 'block';
                    document.getElementById('join').style.display = 'block';
                    document.getElementById('message').disabled = true;
                    document.getElementById('send').disabled = true;
                    break;
                case 'clearChat':
                    console.log('清理聊天记录:', roomId);
                    clearChatWithTip(roomId);
                    break;
                case 'clearChatBeforeDisconnect':
                    console.log('断开连接前清理:', roomId);
                    clearChatWithTip(roomId);
                    updateUserList([]); // 清空用户列表
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
        clearChatWithTip(roomId); // 客户端本地清理聊天记录
        updateUserList([]); // 客户端本地清理用户列表
        joined = false;
        username = '';
        document.getElementById('message').disabled = true;
        document.getElementById('send').disabled = true;
        document.getElementById('username-label').style.display = 'block';
        document.getElementById('username').style.display = 'block';
        document.getElementById('join').style.display = 'block';
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
    console.log('尝试加入，用户名:', name);
    username = name;
    ws.send(JSON.stringify({ type: 'join', username }));
    // 临时隐藏用户名输入框、标签和加入按钮，等待服务器确认
    document.getElementById('username-label').style.display = 'none';
    document.getElementById('username').style.display = 'none';
    document.getElementById('join').style.display = 'none';
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
    users.filter(user => user !== null).forEach(user => {
        const div = document.createElement('div');
        div.textContent = user;
        list.appendChild(div);
    });
}

// 清空聊天并提示
function clearChatWithTip(roomId) {
    const chat = document.getElementById('chat');
    chat.innerHTML = '';
    const tip = document.createElement('div');
    tip.className = 'message-left';
    tip.textContent = `系统提示：已清理房间 ${roomId} 的聊天记录`;
    chat.appendChild(tip);
}

connect();
