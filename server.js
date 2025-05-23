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

const chatRooms = {}; // { roomId: { users: [], messages: [], clients: Set(), timer: intervalId } }

wss.on('connection', (ws, req) => {
    const roomIdFromUrl = req.url.split('/')[1] || 'default';
    ws.currentRoomId = roomIdFromUrl; // Associate ws with a room ID from the URL early

    console.log(`新连接尝试至房间: ${ws.currentRoomId}`);

    // Initialize room if not exists
    if (!chatRooms[ws.currentRoomId]) {
        chatRooms[ws.currentRoomId] = {
            users: [],
            messages: [],
            clients: new Set(), // Stores WebSocket client objects for this room
            timer: setInterval(() => clearChat(ws.currentRoomId), 600000) // Every 10 minutes
        };
        console.log(`房间 ${ws.currentRoomId} 已创建`);
    }

    ws.on('message', (message) => {
        console.log(`收到原始消息事件: 房间 ${ws.currentRoomId}`);
        try {
            const data = JSON.parse(message);
            const room = chatRooms[ws.currentRoomId];

            if (!room) {
                console.error(`错误: 房间 ${ws.currentRoomId} 在消息处理中不存在。`);
                ws.send(JSON.stringify({ type: 'error', message: 'Room not found.' }));
                return;
            }

            if (data.type === 'join') {
                if (room.users.includes(data.username)) {
                    console.log(`错误: 用户名 ${data.username} 在房间 ${ws.currentRoomId} 中已被占用`);
                    ws.send(JSON.stringify({ type: 'joinError', message: '用户名已被占用' }));
                } else {
                    room.users = room.users.filter(user => user !== null); // Clean nulls if any
                    room.users.push(data.username);
                    ws.username = data.username; // Assign username to this WebSocket connection

                    room.clients.add(ws); // Add client to the room's specific client set

                    console.log(`用户 ${data.username} 加入房间 ${ws.currentRoomId}, 当前用户列表: ${room.users.join(', ')}`);
                    broadcast(ws.currentRoomId, { type: 'userList', users: room.users });
                    console.log(`发送 joinSuccess 给 ${data.username}`);
                    ws.send(JSON.stringify({ type: 'joinSuccess', message: '加入成功' }));
                }
            } else if (data.type === 'message') {
                if (!ws.username) {
                    console.warn(`来自未加入用户的消息事件，房间 ${ws.currentRoomId}`);
                    return; // Ignore messages from clients not properly joined
                }
                room.messages.push({ username: ws.username, message: data.message, type: 'text' });
                console.log(`来自 ${ws.username} 在房间 ${ws.currentRoomId} 的文本消息事件`);
                broadcast(ws.currentRoomId, { type: 'message', username: ws.username, message: data.message });
            } else if (data.type === 'image') {
                 if (!ws.username) {
                    console.warn(`来自未加入用户的图片事件，房间 ${ws.currentRoomId}`);
                    return; // Ignore images from clients not properly joined
                }
                // Consider size limits for Base64 strings if memory is a concern
                room.messages.push({ username: ws.username, imageData: data.imageData, type: 'image' });
                console.log(`来自 ${ws.username} 在房间 ${ws.currentRoomId} 的图片消息事件`);
                broadcast(ws.currentRoomId, { type: 'image', username: ws.username, imageData: data.imageData });
            }
        } catch (error) {
            console.error('消息解析或处理错误:', error.message, '原始消息:', message);
        }
    });

    ws.on('close', () => {
        const closedRoomId = ws.currentRoomId;
        const closedUsername = ws.username;

        console.log(`用户 ${closedUsername || '未知用户'} 在房间 ${closedRoomId || '未知房间'} 的连接关闭`);

        if (closedRoomId && chatRooms[closedRoomId]) {
            const room = chatRooms[closedRoomId];
            
            room.clients.delete(ws); // Remove client from room's set

            if (closedUsername) {
                const oldUserCount = room.users.length;
                room.users = room.users.filter(user => user !== closedUsername && user !== null);
                
                if (room.users.length < oldUserCount) {
                    console.log(`用户 ${closedUsername} 离开房间 ${closedRoomId}，更新用户列表: ${room.users.join(', ')}`);
                    broadcast(closedRoomId, { type: 'userList', users: room.users });
                }
            }

            // If room is empty (no users and no active clients), destroy it
            if (room.users.length === 0 && room.clients.size === 0) {
                clearInterval(room.timer);
                delete chatRooms[closedRoomId];
                console.log(`房间 ${closedRoomId} 已销毁，因其已空。`);
            }
        } else {
            console.log(`无法处理关闭事件: 用户名 (${closedUsername}), 房间号 (${closedRoomId}) 或房间对象无效，或用户未成功加入。`);
        }
    });

    ws.on('error', (error) => {
        console.error(`WebSocket error for client in room ${ws.currentRoomId} (user: ${ws.username || 'N/A'}):`, error.message);
    });
});

function broadcast(roomId, data) {
    const room = chatRooms[roomId];
    if (!room) {
        console.error(`广播错误: 房间 ${roomId} 不存在。`);
        return;
    }
    if (!data || typeof data !== 'object') {
        console.error('无效广播数据:', data);
        return;
    }

    console.log(`广播至房间 ${roomId} (类型 ${data.type})，目标客户端数: ${room.clients.size}`);
    const messageString = JSON.stringify(data);
    room.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(messageString);
        }
    });
}

function clearChat(roomId) {
    const room = chatRooms[roomId];
    if (room) {
        room.messages = []; // Clear only messages, users and clients remain
        console.log(`定时清理房间 ${roomId} 的聊天记录，用户列表保持: ${room.users.join(', ')}`);
        broadcast(roomId, { type: 'clearChat', message: `已清理房间 ${roomId} 的聊天记录` });
    }
}

const PORT = process.env.PORT || 8100;
server.listen(PORT, () => console.log(`服务器运行在端口 ${PORT}`));
