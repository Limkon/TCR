let ws;
let username = '';
let joined = false;
let currentRoomId = ''; // Store current room ID globally on client

// Cache DOM elements
const chatArea = document.getElementById('chat');
const userListArea = document.getElementById('userlist');
const usernameInput = document.getElementById('username');
const usernameLabel = document.getElementById('username-label');
const joinButton = document.getElementById('join');
const messageInput = document.getElementById('message');
const sendButton = document.getElementById('send');
const imageButton = document.getElementById('image-button');
const imageInput = document.getElementById('image-input');
const themeToggleButton = document.getElementById('theme-toggle');
const userListToggleButton = document.getElementById('userlist-toggle');


// 连接 WebSocket
function connect() {
    currentRoomId = location.pathname.split('/')[1] || 'default';
    // Ensure WebSocket connection uses wss for HTTPS or ws for HTTP
    const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(`${protocol}//${location.host}/${currentRoomId}`);

    ws.onopen = () => {
        console.log(`成功连接到房间: ${currentRoomId}`);
    };

    ws.onmessage = (event) => {
        try {
            const data = JSON.parse(event.data);
            console.log('收到消息:', data);
            switch (data.type) {
                case 'userList':
                    console.log('更新用户列表:', data.users);
                    updateUserList(data.users);
                    // Fallback join confirmation
                    if (!joined && username && data.users.includes(username)) {
                        console.log('通过 userList 确认加入成功 (fallback)，启用消息输入框');
                        setJoinedState(true);
                    }
                    break;
                case 'message':
                    console.log('收到聊天消息:', data.message);
                    addMessage(data.username, data.message, 'text');
                    break;
                case 'image':
                    console.log(`收到来自 ${data.username} 的图片`);
                    addMessage(data.username, data.imageData, 'image');
                    break;
                case 'joinSuccess':
                    console.log('收到 joinSuccess，启用消息输入框');
                    setJoinedState(true);
                    break;
                case 'joinError':
                    console.log('加入失败:', data.message);
                    alert(data.message || '用户名已存在，请重新输入');
                    setJoinedState(false); // Reset state
                    usernameInput.value = ''; // Clear input
                    username = ''; // Clear stored username
                    break;
                case 'clearChat':
                    console.log(`清理聊天记录: ${currentRoomId}`);
                    clearChatWithTip(currentRoomId, data.message || `已清理房间 ${currentRoomId} 的聊天记录`);
                    break;
                case 'error': // Generic error from server
                    console.error('服务器错误:', data.message);
                    alert(`服务器错误: ${data.message}`);
                    break;
                default:
                    console.warn('未知消息类型:', data);
                    break;
            }
        } catch (error) {
            console.error('消息解析失败:', error, '原始数据:', event.data);
        }
    };

    ws.onclose = () => {
        console.log('连接关闭');
        addSystemMessage(`已从房间 ${currentRoomId} 断开连接。请重新加入。`);
        setJoinedState(false);
        updateUserList([]); // Clear user list on disconnect
        // Optionally, try to reconnect after a delay
        // setTimeout(connect, 5000); // Reconnect after 5 seconds
    };

    ws.onerror = (error) => {
        console.error('WebSocket 错误:', error);
        addSystemMessage('连接发生错误，请刷新页面或稍后再试。');
        setJoinedState(false);
    };
}

function setJoinedState(isJoined) {
    joined = isJoined;
    messageInput.disabled = !isJoined;
    sendButton.disabled = !isJoined;
    imageButton.disabled = !isJoined;

    usernameLabel.style.display = isJoined ? 'none' : 'block';
    usernameInput.style.display = isJoined ? 'none' : 'block';
    joinButton.style.display = isJoined ? 'none' : 'block';

    if (!isJoined) {
        usernameInput.value = username; // Keep username in input if join failed or disconnected
    }
}

// 加入聊天
joinButton.onclick = () => {
    const name = usernameInput.value.trim();
    if (!name) {
        alert('请输入用户名');
        return;
    }
    if (joined) {
        alert('已加入聊天室');
        return;
    }
    if (!ws || ws.readyState !== WebSocket.OPEN) {
        alert('尚未连接到服务器，请稍候或刷新。');
        console.log('尝试加入，但WebSocket未连接或未打开。');
        connect(); // Attempt to connect if not already
        return;
    }
    console.log('尝试加入，用户名:', name);
    username = name; // Set username before sending join message
    ws.send(JSON.stringify({ type: 'join', username }));
    // Temporarily disable join UI, will be re-enabled on joinError or enabled chat on joinSuccess
    usernameLabel.style.display = 'none';
    usernameInput.style.display = 'none';
    joinButton.style.display = 'none';
};

// 发送消息
sendButton.onclick = () => {
    const msg = messageInput.value.trim();
    if (!msg) return;
    if (!joined || !ws || ws.readyState !== WebSocket.OPEN) {
        alert('尚未加入聊天或连接已断开。');
        return;
    }
    ws.send(JSON.stringify({ type: 'message', message: msg }));
    messageInput.value = '';
};

// 回车键快捷发送
messageInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { // Send on Enter, allow Shift+Enter for newline
        e.preventDefault(); // Prevent default Enter behavior (like newline in some cases)
        sendButton.click();
    }
});

// 图片按钮点击
imageButton.onclick = () => {
    if (!joined || !ws || ws.readyState !== WebSocket.OPEN) {
        alert('尚未加入聊天或连接已断开。');
        return;
    }
    imageInput.click(); // Trigger hidden file input
};

// 处理图片选择
imageInput.onchange = (event) => {
    const file = event.target.files[0];
    if (file) {
        if (file.size > 2 * 1024 * 1024) { // 2MB limit
            alert('图片文件过大，请选择小于2MB的图片。');
            imageInput.value = ''; // Clear the input
            return;
        }
        const reader = new FileReader();
        reader.onload = (e) => {
            const imageData = e.target.result; // Base64 string
            if (joined && ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({ type: 'image', username: username, imageData: imageData }));
            } else {
                 alert('无法发送图片：未连接或未加入聊天。');
            }
        };
        reader.onerror = (error) => {
            console.error('FileReader error:', error);
            alert('读取文件失败。');
        };
        reader.readAsDataURL(file);
        imageInput.value = ''; // Clear the input to allow selecting the same file again
    }
};


// 主题切换
themeToggleButton.onclick = () => {
    document.body.classList.toggle('dark-mode');
    document.body.classList.toggle('light-mode');
    // Optionally, save theme preference to localStorage
    // localStorage.setItem('theme', document.body.classList.contains('dark-mode') ? 'dark' : 'light');
};

// 用户列表显示切换
userListToggleButton.onclick = () => {
    userListArea.classList.toggle('hidden');
};

// 添加聊天消息到DOM
function addMessage(user, data, type = 'text') {
    const messageContainer = document.createElement('div');
    messageContainer.className = user === username ? 'message-right' : 'message-left';

    const usernameSpan = document.createElement('span');
    usernameSpan.className = 'message-username-display';
    usernameSpan.textContent = user + ": ";
    messageContainer.appendChild(usernameSpan);

    if (type === 'text') {
        const textNode = document.createTextNode(data);
        messageContainer.appendChild(textNode);
    } else if (type === 'image') {
        // For images, data is the base64 string
        messageContainer.appendChild(document.createElement('br'));
        const img = document.createElement('img');
        img.src = data;
        img.alt = `来自 ${user} 的图片`;
        img.className = 'chat-image';
        messageContainer.appendChild(img);
    }

    chatArea.appendChild(messageContainer);
    chatArea.scrollTop = chatArea.scrollHeight; // Auto-scroll to bottom
}

// 更新在线用户列表
function updateUserList(users) {
    userListArea.innerHTML = '<h3>在线用户</h3>';
    if (users && users.length > 0) {
        users.filter(user => user !== null).forEach(user => {
            const div = document.createElement('div');
            div.textContent = user;
            userListArea.appendChild(div);
        });
    } else {
        const p = document.createElement('p');
        p.textContent = '当前无其他用户在线。';
        userListArea.appendChild(p);
    }
}

// 清空聊天并提示
function clearChatWithTip(roomId, tipMessage) {
    chatArea.innerHTML = ''; // Clear all messages
    addSystemMessage(tipMessage || `系统提示：已清理房间 ${roomId} 的聊天记录`);
}

// Add a system message to the chat
function addSystemMessage(message) {
    const tip = document.createElement('div');
    tip.className = 'system-message'; // Use a general class for system messages
    tip.textContent = message;
    chatArea.appendChild(tip);
    chatArea.scrollTop = chatArea.scrollHeight;
}


// Initialize: Load theme preference if any
// document.addEventListener('DOMContentLoaded', () => {
//     const savedTheme = localStorage.getItem('theme');
//     if (savedTheme === 'dark') {
//         document.body.classList.remove('light-mode');
//         document.body.classList.add('dark-mode');
//     }
// });

connect(); // Initial connection
