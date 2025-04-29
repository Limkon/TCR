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

    // 初始化房间
    if (!chatRooms[roomId]) {
        chatRooms[roomId] = {
            users: [],
            messages: [],
            timer: setInterval(() => clearChat(roomId), 600000) // 每10分钟清理聊天记录
        };
    }
    const room = chatRooms[roomId];

    ws.on('message', (message) => {
        // 仅记录消息事件，不记录内容
        console.log(`收到消息事件: 房间 ${roomId}`);
        try {
            const data = JSON.parse(message);
            if (data.type === 'join') {
                // 重复用户名检测
                if (room.users.includes(data.username)) {
                    console.log(`错误: 用户名 ${data.username} 在房间 ${roomId} 中已被占用`);
                    ws.send(JSON.stringify({ type: 'joinError', message: '用户名已被占用' }));
                } else {
                    // 清理 null 值并添加新用户
                    room.users = room.users.filter(user => user !== null);
                    room.users.push(data.username);
                    ws.username = data.username;
                    ws.roomId = roomId;
                    console.log(`用户 ${data.username} 加入房间 ${roomId}, 当前用户列表: ${room.users}`);
                    // 广播用户列表
                    broadcast(roomId, { type: 'userList', users: room.users });
                    // 通知客户端加入成功
                    console.log(`发送 joinSuccess 给 ${data.username}`);
                    ws.send(JSON.stringify({ type: 'joinSuccess', message: '加入成功' }));
                }
            } else if (data.type === 'message') {
                // 存储并广播消息，不记录内容
                room.messages.push({ username: ws.username, message: data.message });
                console.log(`来自 ${ws.username} 在房间 ${roomId} 的消息事件`);
                broadcast(roomId, { type: 'message', username: ws.username, message: data.message });
            }
        } catch (error) {
            console.error('消息解析错误:', error.message);
        }
    });

    ws.on('close', () => {
        console.log(`用户 ${ws.username} 在房间 ${ws.roomId} 的连接关闭`);
        if (ws.username && ws.roomId) {
            // 从房间移除用户并清理 null 值
            const room = chatRooms[ws.roomId];
            room.users = room.users.filter(user => user !== ws.username && user !== null);
            console.log(`用户 ${ws.username} 离开，更新用户列表: ${room.users}`);
            // 清理聊天记录
            room.messages = [];
            broadcast(ws.roomId, { type: 'clearChatBeforeDisconnect', message: `用户 ${ws.username} 离开，已清理房间 ${ws.roomId} 的聊天记录` });
            // 广播更新后的用户列表
            broadcast(ws.roomId, { type: 'userList', users: room.users });
            // 如果房间空了，销毁房间
            if (room.users.length === 0) {
                clearInterval(room.timer);
                delete chatRooms[ws.roomId];
                console.log(`房间 ${ws.roomId} 已销毁`);
            }
        }
    });
});

function broadcast(roomId, data) {
    // 仅记录广播事件和消息类型
    console.log(`广播至房间 ${roomId}: 类型 ${data.type}`);
    if (data && typeof data === 'object') {
        wss.clients.forEach(client => {
            if (client.roomId === roomId && client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify(data));
            }
        });
    } else {
        console.error('无效广播数据');
    }
}

function clearChat(roomId) {
    const room = chatRooms[roomId];
    if (room) {
        // 仅清理聊天记录，不影响用户列表
        room.messages = [];
        console.log(`定时清理房间 ${roomId} 的聊天记录，用户列表保持: ${room.users}`);
        broadcast(roomId, { type: 'clearChat', message: `已清理房间 ${roomId} 的聊天记录` });
    }
}

const PORT = process.env.PORT || 8100;
server.listen(PORT, () => console.log(`服务器运行在端口 ${PORT}`));
