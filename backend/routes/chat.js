const express = require('express');
const pool = require('../db');
const router = express.Router();

// list conversations
router.get('/conversations', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT
        c.id,
        c.user_name,
        c.avatar_url,
        c.priority,
        c.is_online,
        (
          SELECT m.text
          FROM chat_messages m
          WHERE m.conversation_id = c.id
          ORDER BY m.created_at DESC
          LIMIT 1
        ) AS last_message,
        (
          SELECT DATE_FORMAT(m.created_at, '%H:%i')
          FROM chat_messages m
          WHERE m.conversation_id = c.id
          ORDER BY m.created_at DESC
          LIMIT 1
        ) AS last_time
      FROM chat_conversations c
      ORDER BY c.created_at DESC
    `);

    res.json(rows);
  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({ message: error.message });
  }
});

// get messages by conversation
router.get('/conversations/:id/messages', async (req, res) => {
  try {
    const { id } = req.params;

    const [conversationRows] = await pool.query(
      `SELECT * FROM chat_conversations WHERE id = ?`,
      [id]
    );

    if (conversationRows.length === 0) {
      return res.status(404).json({ message: 'ไม่พบห้องแชท' });
    }

    const [messageRows] = await pool.query(
      `SELECT * FROM chat_messages WHERE conversation_id = ? ORDER BY created_at ASC`,
      [id]
    );

    res.json({
      conversation: conversationRows[0],
      messages: messageRows,
    });
  } catch (error) {
    console.error('Get chat messages error:', error);
    res.status(500).json({ message: error.message });
  }
});

// send message
router.post('/conversations/:id/messages', async (req, res) => {
  try {
    const { id } = req.params;
    const { text, is_admin } = req.body;

    if (!text || text.trim() === '') {
      return res.status(400).json({ message: 'ข้อความห้ามว่าง' });
    }

    const [result] = await pool.query(
      `INSERT INTO chat_messages (conversation_id, text, is_admin, is_read)
       VALUES (?, ?, ?, false)`,
      [id, text, !!is_admin]
    );

    res.status(201).json({
      message: 'ส่งข้อความสำเร็จ',
      id: result.insertId,
    });
  } catch (error) {
    console.error('Send chat message error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

