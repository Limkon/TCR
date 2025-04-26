聊天室应用部署说明
本说明指导如何将包含 index.html 和 server.js 的聊天室应用部署到本地或云服务器，确保应用正常运行，支持回车键发送消息和断开连接前清除聊天内容功能。
1. 环境要求
操作系统：Windows、Linux 或 macOS

Node.js：版本 14.x 或更高（推荐 LTS 版本）

浏览器：支持 WebSocket 的现代浏览器（Chrome、Firefox、Edge 等）

网络：本地测试需开放指定端口（默认 8100）；云部署需配置防火墙和域名

依赖：express 和 ws（WebSocket 库）

2. 项目结构
确保项目目录结构如下：

project/
├── public/
│   └── index.html
├── server.js
├── package.json
└── node_modules/ (安装依赖后生成)

index.html：客户端代码，提供聊天室界面和 WebSocket 交互。

server.js：服务器代码，处理 WebSocket 连接、消息广播和用户管理。

package.json：定义项目元数据和依赖。

