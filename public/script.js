const roomId = location.pathname.split('/')[1] || 'default';
document.getElementById('roomTitle').innerText = `房间：${roomId}`;
let ws;
let username;
let joined = false;
let currentUsers = [];

function connectWebSocket(protocol) {
  const host = location.hostname;
  const port = location.port || (location.protocol === 'https:' ? '443' : '80');
  const wsUrl = `${protocol}://${host}:${port}/${roomId}`;
  ws = new WebSocket(wsUrl);

  ws.onopen = () => console.log('WebSocket 已连接');
  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      if (data.type === 'userList') {
        updateUserList(data.users);
      } else if (data.type === 'message') {
        addMessage(data.username, data.message);
      } else if (data.type === 'clearChat') {
        clearChat(true);
      } else if (data.type === 'error') {
        alert(data.message);
        joined = false;
      }
    } catch (error) {
      console.error('消息解析错误:', error);
    }
  };
  ws.onclose = () => { console.log('WebSocket 连接断开'); clearChat(false); };
  ws.onerror = (err) => console.error('WebSocket 错误:', err);
}

connectWebSocket(location.protocol === 'https:' ? 'wss' : 'ws');

function joinChat() {
  if (joined) { alert('您已经加入过了'); return; }
  username = document.getElementById('username').value.trim();
  if (!username) { alert('请输入用户名'); return; }
  if (currentUsers.includes(username)) { alert('用户名已存在，请换一个'); return; }
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type: 'join', username }));
    joined = true;
  } else {
    alert('服务器未连接');
  }
}

function sendMessage() {
  const msgEl = document.getElementById('message');
  const message = msgEl.value.trim();
  if (message && username && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type: 'message', message }));
    msgEl.value = '';
  } else {
    alert('请先加入聊天室');
  }
}

function addMessage(sender, text) {
  const chat = document.getElementById('chat');
  const div = document.createElement('div');
  div.className = sender === username ? 'message-right' : 'message-left';
  div.innerHTML = `<div><b>${sender}</b>: ${text}</div>`;
  chat.appendChild(div);
  chat.scrollTop = chat.scrollHeight;
}

function updateUserList(users) {
  currentUsers = users;
  const list = document.getElementById('userList');
  list.innerHTML = '';
  users.forEach(u => {
    const li = document.createElement('li');
    li.textContent = u;
    list.appendChild(li);
  });
}

function clearChat(system) {
  document.getElementById('chat').innerHTML = system ? '<div style="text-align:center;color:gray;">系统提示：聊天记录已清空</div>' : '';
  document.getElementById('userList').innerHTML = '';
  joined = false;
}

document.getElementById('join-btn').addEventListener('click', joinChat);
document.getElementById('send-btn').addEventListener('click', sendMessage);
document.getElementById('dark-mode-toggle').addEventListener('click', () => document.body.classList.toggle('dark-mode'));
document.getElementById('toggle-users').addEventListener('click', () => document.getElementById('left').classList.toggle('hidden'));
document.getElementById('message').addEventListener('keypress', (e) => { if (e.key === 'Enter') sendMessage(); });

// 每10分钟清屏
setInterval(() => {
  document.getElementById('chat').innerHTML = '<div style="text-align:center;color:gray;">系统提示：聊天记录已清空</div>';
}, 600000);
