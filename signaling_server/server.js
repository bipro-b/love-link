const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
  pingTimeout: 60000,
  pingInterval: 25000,
});

// Only 2 users: "user1" and "user2" with fixed room "lovelink"
const ROOM_ID = 'lovelink';
const connectedUsers = {}; // socketId -> { userId, inCall }

// ── Health check ─────────────────────────────────────
app.get('/health', (req, res) => res.json({ status: 'ok', users: Object.keys(connectedUsers).length }));

// ── Socket.io ─────────────────────────────────────────
io.on('connection', (socket) => {
  console.log(`[+] Socket connected: ${socket.id}`);

  // ── Register user ──────────────────────────────────
  socket.on('register', ({ userId }) => {
    // Disconnect old socket for same user if exists
    Object.entries(connectedUsers).forEach(([sid, u]) => {
      if (u.userId === userId && sid !== socket.id) {
        io.to(sid).emit('force_disconnect', { reason: 'Logged in from another device' });
        delete connectedUsers[sid];
      }
    });

    connectedUsers[socket.id] = { userId, inCall: false };
    socket.join(ROOM_ID);
    console.log(`[register] ${userId} -> ${socket.id}`);

    // Notify the other user this person is online
    socket.to(ROOM_ID).emit('partner_status', { online: true, userId });

    // Tell this user if their partner is already online
    const partner = Object.values(connectedUsers).find(
      (u) => u.userId !== userId
    );
    socket.emit('partner_status', { online: !!partner, userId: partner?.userId });
  });

  // ── Call initiation ────────────────────────────────
  socket.on('call_user', ({ callType, offer }) => {
    const caller = connectedUsers[socket.id];
    if (!caller) return;

    console.log(`[call] ${caller.userId} -> ${callType}`);
    socket.to(ROOM_ID).emit('incoming_call', {
      callType,        // 'video' | 'audio'
      offer,           // WebRTC SDP offer
      callerId: caller.userId,
    });
  });

  // ── Call answer ────────────────────────────────────
  socket.on('call_answer', ({ answer }) => {
    const user = connectedUsers[socket.id];
    if (!user) return;
    console.log(`[answer] ${user.userId}`);
    socket.to(ROOM_ID).emit('call_answered', { answer });
    // Mark both users as inCall
    Object.values(connectedUsers).forEach((u) => (u.inCall = true));
  });

  // ── ICE candidates ─────────────────────────────────
  socket.on('ice_candidate', ({ candidate }) => {
    socket.to(ROOM_ID).emit('ice_candidate', { candidate });
  });

  // ── Call rejection / hang up ───────────────────────
  socket.on('call_rejected', () => {
    const user = connectedUsers[socket.id];
    console.log(`[reject] ${user?.userId}`);
    socket.to(ROOM_ID).emit('call_rejected');
    Object.values(connectedUsers).forEach((u) => (u.inCall = false));
  });

  socket.on('hang_up', () => {
    const user = connectedUsers[socket.id];
    console.log(`[hangup] ${user?.userId}`);
    socket.to(ROOM_ID).emit('call_ended');
    Object.values(connectedUsers).forEach((u) => (u.inCall = false));
  });

  // ── Text message during call ───────────────────────
  socket.on('send_message', ({ message }) => {
    const user = connectedUsers[socket.id];
    if (!user) return;
    socket.to(ROOM_ID).emit('receive_message', {
      message,
      senderId: user.userId,
      timestamp: Date.now(),
    });
  });

  // ── Disconnect ─────────────────────────────────────
  socket.on('disconnect', () => {
    const user = connectedUsers[socket.id];
    if (user) {
      console.log(`[-] ${user.userId} disconnected`);
      socket.to(ROOM_ID).emit('partner_status', { online: false, userId: user.userId });
      if (user.inCall) {
        socket.to(ROOM_ID).emit('call_ended');
      }
      delete connectedUsers[socket.id];
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`🚀 LoveLink signaling server on port ${PORT}`));
