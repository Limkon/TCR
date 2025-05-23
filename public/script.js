let ws;
let username = '';
let joined = false;
let currentRoomId = ''; // 在客戶端全域儲存目前房間 ID

// 快取 DOM 元素
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


// 連接 WebSocket
function connect() {
    currentRoomId = location.pathname.split('/')[1] || 'default';
    // 確保 WebSocket 連接對 HTTPS 使用 wss，對 HTTP 使用 ws
    const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(`${protocol}//${location.host}/${currentRoomId}`);

    ws.onopen = () => {
        console.log(`成功連接到房間: ${currentRoomId}`);
    };

    ws.onmessage = (event) => {
        try {
            const data = JSON.parse(event.data);
            console.log('收到訊息:', data);
            switch (data.type) {
                case 'userList':
                    console.log('更新使用者列表:', data.users);
                    updateUserList(data.users);
                    // 後備加入確認
                    if (!joined && username && data.users.includes(username)) {
                        console.log('透過 userList 確認加入成功 (fallback)，啟用訊息輸入框');
                        setJoinedState(true);
                    }
                    break;
                case 'message':
                    console.log('收到聊天訊息:', data.message);
                    addMessage(data.username, data.message, 'text');
                    break;
                case 'image':
                    console.log(`收到來自 ${data.username} 的圖片`);
                    addMessage(data.username, data.imageData, 'image');
                    break;
                case 'joinSuccess':
                    console.log('收到 joinSuccess，啟用訊息輸入框');
                    setJoinedState(true);
                    break;
                case 'joinError':
                    console.log('加入失敗:', data.message);
                    alert(data.message || '使用者名稱已存在，請重新輸入');
                    setJoinedState(false); // 重設狀態
                    usernameInput.value = ''; // 清除輸入
                    username = ''; // 清除儲存的使用者名稱
                    break;
                case 'clearChat':
                    console.log(`清理聊天記錄: ${currentRoomId}`);
                    clearChatWithTip(currentRoomId, data.message || `已清理房間 ${currentRoomId} 的聊天記錄`);
                    break;
                case 'error': // 來自伺服器的通用錯誤
                    console.error('伺服器錯誤:', data.message);
                    alert(`伺服器錯誤: ${data.message}`);
                    break;
                default:
                    console.warn('未知訊息類型:', data);
                    break;
            }
        } catch (error) {
            console.error('訊息解析失敗:', error, '原始資料:', event.data);
        }
    };

    ws.onclose = () => {
        console.log('連接關閉');
        addSystemMessage(`已從房間 ${currentRoomId} 斷開連接。請重新加入。`);
        setJoinedState(false);
        updateUserList([]); // 斷線時清除使用者列表
        // 可選：延遲後嘗試重新連接
        // setTimeout(connect, 5000); // 5 秒後重新連接
    };

    ws.onerror = (error) => {
        console.error('WebSocket 錯誤:', error);
        addSystemMessage('連接發生錯誤，請刷新頁面或稍後再試。');
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
        usernameInput.value = username; // 如果加入失敗或斷線，則在輸入框中保留使用者名稱
    }
}

// 加入聊天
joinButton.onclick = () => {
    const name = usernameInput.value.trim();
    if (!name) {
        alert('請輸入使用者名稱');
        return;
    }
    if (joined) {
        alert('已加入聊天室');
        return;
    }
    if (!ws || ws.readyState !== WebSocket.OPEN) {
        alert('尚未連接到伺服器，請稍候或刷新。');
        console.log('嘗試加入，但WebSocket未連接或未打開。');
        connect(); // 如果尚未連接，則嘗試連接
        return;
    }
    console.log('嘗試加入，使用者名稱:', name);
    username = name; // 在傳送加入訊息前設定使用者名稱
    ws.send(JSON.stringify({ type: 'join', username }));
    // 暫時停用加入 UI，將在 joinError 時重新啟用或在 joinSuccess 時啟用聊天
    usernameLabel.style.display = 'none';
    usernameInput.style.display = 'none';
    joinButton.style.display = 'none';
};

// 發送訊息
sendButton.onclick = () => {
    const msg = messageInput.value.trim();
    if (!msg) return;
    if (!joined || !ws || ws.readyState !== WebSocket.OPEN) {
        alert('尚未加入聊天或連接已斷開。');
        return;
    }
    ws.send(JSON.stringify({ type: 'message', message: msg }));
    messageInput.value = '';
};

// Enter 鍵快捷發送
messageInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { // 按 Enter 發送，允許 Shift+Enter 換行
        e.preventDefault(); // 防止預設 Enter 行為 (例如在某些情況下換行)
        sendButton.click();
    }
});

// 圖片按鈕點擊
imageButton.onclick = () => {
    if (!joined || !ws || ws.readyState !== WebSocket.OPEN) {
        alert('尚未加入聊天或連接已斷開。');
        return;
    }
    imageInput.click(); // 觸發隱藏的檔案輸入
};

// 處理圖片選擇
imageInput.onchange = (event) => {
    const file = event.target.files[0];
    if (file) {
        if (file.size > 2 * 1024 * 1024) { // 2MB 限制
            alert('圖片檔案過大，請選擇小於2MB的圖片。');
            imageInput.value = ''; // 清除輸入
            return;
        }
        const reader = new FileReader();
        reader.onload = (e) => {
            const imageData = e.target.result; // Base64 字串
            if (joined && ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({ type: 'image', username: username, imageData: imageData }));
            } else {
                 alert('無法傳送圖片：未連接或未加入聊天。');
            }
        };
        reader.onerror = (error) => {
            console.error('FileReader error:', error);
            alert('讀取檔案失敗。');
        };
        reader.readAsDataURL(file);
        imageInput.value = ''; // 清除輸入以允許再次選擇相同的檔案
    }
};


// 主題切換
themeToggleButton.onclick = () => {
    document.body.classList.toggle('dark-mode');
    document.body.classList.toggle('light-mode');
    // 可選：將主題偏好儲存到 localStorage
    // localStorage.setItem('theme', document.body.classList.contains('dark-mode') ? 'dark' : 'light');
};

// 使用者列表顯示切換
userListToggleButton.onclick = () => {
    userListArea.classList.toggle('hidden');
};

// 將聊天訊息新增到 DOM
function addMessage(user, data, type = 'text') {
    const messageContainer = document.createElement('div');
    messageContainer.className = user === username ? 'message-right' : 'message-left';

    const usernameSpan = document.createElement('span');
    usernameSpan.className = 'message-username-display';
    usernameSpan.textContent = user; // 修改此處：移除冒號和空格
    messageContainer.appendChild(usernameSpan);

    // 創建一個新的 div 來容納訊息內容（文字或圖片）
    // 這樣可以讓用戶名和內容在 CSS 中更容易分開控制對齊
    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content'; // 給內容 div 一個 class

    if (type === 'text') {
        const textNode = document.createTextNode(data);
        contentDiv.appendChild(textNode);
    } else if (type === 'image') {
        // 對於圖片，data 是 base64 字串
        const img = document.createElement('img');
        img.src = data;
        img.alt = `來自 ${user} 的圖片`;
        img.className = 'chat-image';
        contentDiv.appendChild(img);
    }
    messageContainer.appendChild(contentDiv); // 將內容 div 加入到 messageContainer

    chatArea.appendChild(messageContainer);
    chatArea.scrollTop = chatArea.scrollHeight; // 自動捲動到底部
}

// 更新在線使用者列表
function updateUserList(users) {
    userListArea.innerHTML = '<h3>在線用戶</h3>';
    if (users && users.length > 0) {
        users.filter(user => user !== null).forEach(user => {
            const div = document.createElement('div');
            div.textContent = user;
            userListArea.appendChild(div);
        });
    } else {
        const p = document.createElement('p');
        p.textContent = '目前無其他用戶在線。';
        userListArea.appendChild(p);
    }
}

// 清空聊天並提示
function clearChatWithTip(roomId, tipMessage) {
    chatArea.innerHTML = ''; // 清除所有訊息
    addSystemMessage(tipMessage || `系統提示：已清理房間 ${roomId} 的聊天記錄`);
}

// 將系統訊息新增到聊天中
function addSystemMessage(message) {
    const tip = document.createElement('div');
    tip.className = 'system-message'; // 對系統訊息使用通用 class
    tip.textContent = message;
    chatArea.appendChild(tip);
    chatArea.scrollTop = chatArea.scrollHeight;
}


// 初始化：如果有的話，載入主題偏好
// document.addEventListener('DOMContentLoaded', () => {
//     const savedTheme = localStorage.getItem('theme');
//     if (savedTheme === 'dark') {
//         document.body.classList.remove('light-mode');
//         document.body.classList.add('dark-mode');
//     }
// });

connect(); // 初始連接
