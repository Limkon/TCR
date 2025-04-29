document.addEventListener('DOMContentLoaded', () => {
  const roomId = location.pathname.split('/')[1] || 'default';
  document.getElementById('roomTitle').innerText = `房间：${roomId}`;
  
  const joinBtn = document.getElementById('join-btn');
  const sendBtn = document.getElementById('send-btn');
  const toggleUsersBtn = document.getElementById('toggle-users');
  const chatArea = document.getElementById('chatArea');
  const messageInput = document.getElementById('messageInput');
  const usernameInput = document.getElementById('username');
  const userList = document.getElementById('userList');
  
  let ws;
  let username;

  joinBtn.addEventListener('click', () => {
    username = usernameInput.value.trim();
    if (!username) {
      alert('请输入用户名');
      return;
    }
    const protocol = location.protocol === 'https:' ? 'wss' : 'ws';
    ws = new WebSocket(`${protocol}://${location.host}/${roomId}`);
    ws.onopen = () => {
      ws.send(JSON.stringify({ type: 'join', user: username }));
    };
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type === 'join') {
        updateUsers(data.users);
        appendSystemMessage(`${data.user} 加入聊天室`);
      } else if (data.type === 'message') {
        appendMessage(data.user, data.message);
      } else if (data.type === 'leave') {
        updateUsers(data.users);
        appendSystemMessage(`${data.user} 离开聊天室`);
      }
    };
  });

  sendBtn.addEventListener('click', () => {
    const msg = messageInput.value.trim();
    if (!msg || !ws || ws.readyState !== WebSocket.OPEN) return;
    ws.send(JSON.stringify({ type: 'message', user: username, message: msg }));
    messageInput.value = '';
  });

  toggleUsersBtn.addEventListener('click', () => {
    userList.classList.toggle('hidden');
    toggleUsersBtn.innerText = userList.classList.contains('hidden') ? '显示用户列表' : '隐藏用户列表';
  });

  // Clear chat every 10 minutes
  setInterval(() => {
    chatArea.innerHTML = '<div style="text-align:center;color:gray;">系统提示：聊天记录已清空</div>';
  }, 600000);

  function updateUsers(users) {
    userList.innerHTML = '';
    users.forEach(u => {
      const li = document.createElement('li');
      li.innerText = u;
      userList.appendChild(li);
    });
  }

  function appendMessage(user, message) {
    const div = document.createElement('div');
    div.innerHTML = `<strong>${user}:</strong> ${message}`;
    chatArea.appendChild(div);
    chatArea.scrollTop = chatArea.scrollHeight;
  }

  function appendSystemMessage(text) {
    const div = document.createElement('div');
    div.style.color = 'gray';
    div.style.textAlign = 'center';
    div.innerText = `系统提示：${text}`;
    chatArea.appendChild(div);
    chatArea.scrollTop = chatArea.scrollHeight;
  }
});
