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
    ws.currentRoomId = roomIdFromUrl; 

    if (!chatRooms[ws.currentRoomId]) {
        chatRooms[ws.currentRoomId] = {
            users: [],
            messages: [],
            clients: new Set(), 
            timer: setInterval(() => clearChat(ws.currentRoomId), 600000) 
        };
    }

    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            const room = chatRooms[ws.currentRoomId];

            if (!room) {
                ws.send(JSON.stringify({ type: 'error', message: 'Room not found.' }));
                return;
            }

            if (data.type === 'join') {
                if (room.users.includes(data.username)) {
                    ws.send(JSON.stringify({ type: 'joinError', message: '用户名已被占用' }));
                } else {
                    room.users = room.users.filter(user => user !== null); 
                    room.users.push(data.username);
                    ws.username = data.username; 

                    room.clients.add(ws); 

                    broadcast(ws.currentRoomId, { type: 'userList', users: room.users });
                    ws.send(JSON.stringify({ type: 'joinSuccess', message: '加入成功' }));
                }
            } else if (data.type === 'message') {
                if (!ws.username) {
                    return; 
                }
                room.messages.push({ username: ws.username, message: data.message, type: 'text' });
                broadcast(ws.currentRoomId, { type: 'message', username: ws.username, message: data.message });
            } else if (data.type === 'image') {
                 if (!ws.username) {
                    return; 
                }
                room.messages.push({ username: ws.username, imageData: data.imageData, type: 'image' });
                broadcast(ws.currentRoomId, { type: 'image', username: ws.username, imageData: data.imageData });
            }
        } catch (error) {
            // Error during message parsing or handling, silently ignore or send generic error to client
            // ws.send(JSON.stringify({ type: 'error', message: 'An error occurred processing your message.' }));
        }
    });

    ws.on('close', () => {
        const closedRoomId = ws.currentRoomId;
        const closedUsername = ws.username;

        if (closedRoomId && chatRooms[closedRoomId]) {
            const room = chatRooms[closedRoomId];
            
            room.clients.delete(ws); 

            if (closedUsername) {
                const oldUserCount = room.users.length;
                room.users = room.users.filter(user => user !== closedUsername && user !== null);
                
                if (room.users.length < oldUserCount) {
                    broadcast(closedRoomId, { type: 'userList', users: room.users });
                }
            }

            if (room.users.length === 0 && room.clients.size === 0) {
                clearInterval(room.timer);
                delete chatRooms[closedRoomId];
            }
        }
    });

    ws.on('error', (error) => {
        // Silently ignore WebSocket errors on the server side for individual clients
    });
});

function broadcast(roomId, data) {
    const room = chatRooms[roomId];
    if (!room) {
        return;
    }
    if (!data || typeof data !== 'object') {
        return;
    }

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
        room.messages = []; 
        broadcast(roomId, { type: 'clearChat', message: `已清理房间 ${roomId} 的聊天记录` });
    }
}

const PORT = process.env.PORT || 8100;
server.listen(PORT, () => {
    // Server listening message can be kept or removed based on preference for deployment
    // For a completely silent server, remove the next line too.
    // console.log(`服务器运行在端口 ${PORT}`); 
});
