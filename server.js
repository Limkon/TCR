const express = require('express');
const WebSocket = require('ws');
const http = require('http');
const path = require('path');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

app.use(express.static(path.join(__dirname, 'public')));
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const chatRooms = {};

wss.on('connection', (ws, req) => {
    const roomId = req.url.split('/')[1] || 'default';
    console.log(`新连接至房间: ${roomId}`);

    if (!chatRooms[roomId]) {
        chatRooms[roomId] = {
            users: [],
            messages: [],
            timer: setInterval(() => clearChat(roomId), 600000)
        };
    }
    const room = chatRooms[roomId];

    ws.on('message', (message) => {
        console.log('收到消息:', message.toString());
        try {
            const data = JSON.parse(message);
            if (data.type === 'join') {
                if (room.users.includes(data.username)) {
                    ws.send(JSON.stringify({ type: 'error', message: '用户名已被占用' }));
                    console.log(`错误: 用户名 ${data.username} 在房间 ${roomId} 中已被占用`);
                } else {
                    room.users.push(data.username);
                    ws.username = data.username;
                    ws.roomId = roomId;
                    console.log(`用户 ${data.username} 加入房间 ${roomId}`);
                    broadcast(roomId, { type: 'userList', users: room.users });
                }
            } else if (data.type === 'message') {
                room.messages.push({ username: ws.username, message: data.message });
                console.log(`来自 ${ws.username} 在房间 ${roomId} 的消息: ${data.message}`);
                broadcast(roomId, { type: 'message', username: ws.username, message: data.message });
            }
        } catch (error) {
            console.error('消息解析错误:', error);
        }
    });

    ws.on('close', () => {
        console.log(`用户 ${ws.username} 在房间 ${ws.roomId} 的连接关闭`);
        if (ws.username && ws.roomId) {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({ type: 'clearChatBeforeDisconnect' }));
                console.log(`向 ${ws.username} 发送断开前清除聊天指令`);
            }

            const room = chatRooms[ws.roomId];
            room.users = room.users.filter(user => user !== ws.username);
            broadcast(ws.roomId, { type: 'userList', users: room.users });
            if (room.users.length === 0) {
                clearInterval(room.timer);
                delete chatRooms[ws.roomId];
                console.log(`房间 ${ws.roomId} 已销毁`);
            }
        }
    });
});

function broadcast(roomId, data) {
    console.log(`广播至房间 ${roomId}:`, data);
    wss.clients.forEach(client => {
        if (client.roomId === roomId && client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
        }
    });
}

function clearChat(roomId) {
    const room = chatRooms[roomId];
    if (room) {
        room.messages = [];
        console.log(`已清理房间 ${roomId} 的聊天记录`);
        broadcast(roomId, { type: 'clearChat' });
    }
}

const PORT = process.env.PORT || 8100;
server.listen(PORT, () => console.log(`服务器运行在端口 ${PORT}`));