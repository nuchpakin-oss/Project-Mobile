const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();
const db = require('../db');

function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'ไม่ได้ส่ง token' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Token ไม่ถูกต้องหรือหมดอายุ' });
  }
}

async function ensureParticipant(conversationId, userId) {
  const [rows] = await db.query(
    `
    SELECT id
    FROM chat_participants
    WHERE conversation_id = ? AND user_id = ?
    LIMIT 1
    `,
    [conversationId, userId]
  );

  return rows.length > 0;
}

// รายการห้องของ user/admin ที่ล็อกอิน
router.get('/conversations', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;

    const [rows] = await db.query(
      `
      SELECT
        c.id,
        c.type,
        c.title,
        c.updated_at,
        (
          SELECT m.text
          FROM chat_messages m
          WHERE m.conversation_id = c.id
          ORDER BY m.created_at DESC, m.id DESC
          LIMIT 1
        ) AS last_message,
        (
          SELECT DATE_FORMAT(m.created_at, '%H:%i')
          FROM chat_messages m
          WHERE m.conversation_id = c.id
          ORDER BY m.created_at DESC, m.id DESC
          LIMIT 1
        ) AS time_text,
        (
          SELECT COUNT(*)
          FROM chat_messages m
          WHERE m.conversation_id = c.id
            AND m.id > COALESCE(cp.last_read_message_id, 0)
            AND m.sender_id <> ?
        ) AS unread_count
      FROM chat_conversations c
      INNER JOIN chat_participants cp
        ON cp.conversation_id = c.id
      WHERE cp.user_id = ?
      ORDER BY COALESCE(c.updated_at, c.created_at) DESC, c.id DESC
      `,
      [userId, userId]
    );

    const enriched = [];

    for (const row of rows) {
      const [participantRows] = await db.query(
        `
        SELECT
          u.id,
          u.full_name,
          u.profile_image_url,
          p.role
        FROM chat_participants p
        INNER JOIN users u ON u.id = p.user_id
        WHERE p.conversation_id = ?
          AND p.user_id <> ?
        ORDER BY p.id ASC
        `,
        [row.id, userId]
      );

      let displayName = row.title || 'ห้องแชต';
      let avatarUrl = null;
      let isOnline = false;

      if (row.type === 'user_admin') {
        const adminParticipant =
          participantRows.find((p) => p.role === 'admin') || participantRows[0];
        displayName = adminParticipant?.full_name || 'แอดมิน';
        avatarUrl = adminParticipant?.profile_image_url || null;
      } else if (row.type === 'user_user') {
        const otherUser = participantRows[0];
        displayName = row.title || otherUser?.full_name || 'ผู้ใช้งาน';
        avatarUrl = otherUser?.profile_image_url || null;
      }

      enriched.push({
        id: Number(row.id),
        type: row.type,
        user_name: displayName,
        avatar_url: avatarUrl,
        is_online: isOnline,
        last_message: row.last_message || '',
        time_text: row.time_text || '',
        unread_count: Number(row.unread_count || 0),
      });
    }

    res.json(enriched);
  } catch (error) {
    console.error('GET /chat-v2/conversations error:', error);
    res.status(500).json({ message: error.message });
  }
});

// เริ่มแชต user-user
router.post('/conversations/start-user-chat', authMiddleware, async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const { other_user_id, title } = req.body;

    if (!other_user_id) {
      return res.status(400).json({ message: 'กรุณาระบุ other_user_id' });
    }

    if (Number(other_user_id) === Number(currentUserId)) {
      return res.status(400).json({ message: 'ไม่สามารถสร้างแชตกับตัวเองได้' });
    }

    const [existingRows] = await db.query(
      `
      SELECT c.id
      FROM chat_conversations c
      INNER JOIN chat_participants p1
        ON p1.conversation_id = c.id AND p1.user_id = ?
      INNER JOIN chat_participants p2
        ON p2.conversation_id = c.id AND p2.user_id = ?
      WHERE c.type = 'user_user'
      LIMIT 1
      `,
      [currentUserId, other_user_id]
    );

    if (existingRows.length > 0) {
      return res.json({
        conversation_id: Number(existingRows[0].id),
        message: 'มีห้องแชตอยู่แล้ว',
      });
    }

    const [result] = await db.query(
    `
    INSERT INTO chat_conversations (type, title, created_by, user_id, user_name, is_online)
    VALUES ('user_user', ?, ?, ?, 'ห้องแชต', 0)
    `,
    [title || null, currentUserId, currentUserId]
  );

    const conversationId = Number(result.insertId);

    await db.query(
      `
      INSERT INTO chat_participants (conversation_id, user_id, role)
      VALUES (?, ?, 'user'), (?, ?, 'user')
      `,
      [conversationId, currentUserId, conversationId, other_user_id]
    );

    res.status(201).json({
      conversation_id: conversationId,
      message: 'สร้างห้องแชต user-user สำเร็จ',
    });
  } catch (error) {
    console.error('POST /start-user-chat error:', error);
    res.status(500).json({ message: error.message });
  }
});

// เริ่มแชต user-admin
router.post('/conversations/start-admin-chat', authMiddleware, async (req, res) => {
  try {
    const currentUserId = req.user.id;

    const [adminRows] = await db.query(
      `
      SELECT id
      FROM users
      WHERE role = 'admin'
      ORDER BY id ASC
      LIMIT 1
      `
    );

    if (adminRows.length === 0) {
      return res.status(404).json({ message: 'ไม่พบ admin ในระบบ' });
    }

    const adminId = Number(adminRows[0].id);

    const [existingRows] = await db.query(
      `
      SELECT c.id
      FROM chat_conversations c
      INNER JOIN chat_participants p1
        ON p1.conversation_id = c.id AND p1.user_id = ?
      INNER JOIN chat_participants p2
        ON p2.conversation_id = c.id AND p2.user_id = ?
      WHERE c.type = 'user_admin'
      LIMIT 1
      `,
      [currentUserId, adminId]
    );

    if (existingRows.length > 0) {
      return res.json({
        conversation_id: Number(existingRows[0].id),
        message: 'มีห้องแชต admin อยู่แล้ว',
      });
    }

    const [result] = await db.query(
  `
  INSERT INTO chat_conversations (type, title, created_by, user_id, user_name, is_online)
  VALUES ('user_admin', 'คุยกับแอดมิน', ?, ?, 'แอดมิน', 0)
  `,
  [currentUserId, currentUserId]
  );

    const conversationId = Number(result.insertId);

    await db.query(
      `
      INSERT INTO chat_participants (conversation_id, user_id, role)
      VALUES (?, ?, 'user'), (?, ?, 'admin')
      `,
      [conversationId, currentUserId, conversationId, adminId]
    );

    res.status(201).json({
      conversation_id: conversationId,
      message: 'สร้างห้องแชต user-admin สำเร็จ',
    });
  } catch (error) {
    console.error('POST /start-admin-chat error:', error);
    res.status(500).json({ message: error.message });
  }
});

// โหลดข้อความในห้อง
router.get('/conversations/:conversationId/messages', authMiddleware, async (req, res) => {
  try {
    const conversationId = Number(req.params.conversationId);
    const userId = req.user.id;

    const isParticipant = await ensureParticipant(conversationId, userId);
    if (!isParticipant) {
      return res.status(403).json({ message: 'คุณไม่มีสิทธิ์เข้าห้องนี้' });
    }

    const [rows] = await db.query(
      `
      SELECT
        m.id,
        m.conversation_id,
        m.sender_id,
        m.text,
        m.image_url,
        DATE_FORMAT(m.created_at, '%H:%i') AS time_text
      FROM chat_messages m
      WHERE m.conversation_id = ?
      ORDER BY m.created_at ASC, m.id ASC
      `,
      [conversationId]
    );

    if (rows.length > 0) {
      const lastMessageId = Number(rows[rows.length - 1].id);

      await db.query(
        `
        UPDATE chat_participants
        SET last_read_message_id = ?
        WHERE conversation_id = ? AND user_id = ?
        `,
        [lastMessageId, conversationId, userId]
      );
    }

    res.json(
      rows.map((m) => ({
        id: Number(m.id),
        text: m.text || '',
        image_url: m.image_url || null,
        sender_id: Number(m.sender_id),
        is_me: Number(m.sender_id) === Number(userId),
        time_text: m.time_text || '',
      }))
    );
  } catch (error) {
    console.error('GET /messages error:', error);
    res.status(500).json({ message: error.message });
  }
});

// ส่งข้อความ
router.post('/conversations/:conversationId/messages', authMiddleware, async (req, res) => {
  try {
    const conversationId = Number(req.params.conversationId);
    const userId = req.user.id;
    const { text } = req.body;

    if (!text || !text.toString().trim()) {
      return res.status(400).json({ message: 'ข้อความห้ามว่าง' });
    }

    const isParticipant = await ensureParticipant(conversationId, userId);
    if (!isParticipant) {
      return res.status(403).json({ message: 'คุณไม่มีสิทธิ์ส่งข้อความในห้องนี้' });
    }

    const [result] = await db.query(
      `
      INSERT INTO chat_messages (conversation_id, sender_id, text, image_url)
      VALUES (?, ?, ?, NULL)
      `,
      [conversationId, userId, text.toString().trim()]
    );

    await db.query(
      `
      UPDATE chat_conversations
      SET updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
      `,
      [conversationId]
    );

    const [rows] = await db.query(
      `
      SELECT
        id,
        sender_id,
        text,
        image_url,
        DATE_FORMAT(created_at, '%H:%i') AS time_text
      FROM chat_messages
      WHERE id = ?
      LIMIT 1
      `,
      [result.insertId]
    );

    const m = rows[0];

    res.status(201).json({
      id: Number(m.id),
      text: m.text || '',
      image_url: m.image_url || null,
      sender_id: Number(m.sender_id),
      is_me: true,
      time_text: m.time_text || '',
    });
  } catch (error) {
    console.error('POST /messages error:', error);
    res.status(500).json({ message: error.message });
  }
});

// ลบแชต
router.delete('/conversations/:conversationId', authMiddleware, async (req, res) => {
  try {
    const conversationId = Number(req.params.conversationId);
    const userId = req.user.id;

    const isParticipant = await ensureParticipant(conversationId, userId);
    if (!isParticipant) {
      return res.status(403).json({ message: 'คุณไม่มีสิทธิ์ลบห้องนี้' });
    }

    await db.query(
      `DELETE FROM chat_messages WHERE conversation_id = ?`,
      [conversationId]
    );

    await db.query(
      `DELETE FROM chat_participants WHERE conversation_id = ?`,
      [conversationId]
    );

    await db.query(
      `DELETE FROM chat_conversations WHERE id = ?`,
      [conversationId]
    );

    res.json({ message: 'ลบแชตสำเร็จ' });
  } catch (error) {
    console.error('DELETE /conversations/:conversationId error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;