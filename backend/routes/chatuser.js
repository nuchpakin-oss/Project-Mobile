const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/conversations', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT
        c.id,
        c.user_name,
        c.avatar_url,
        c.is_online,
        (
          SELECT m.text
          FROM chat_messages m
          WHERE m.conversation_id = c.id
          ORDER BY m.created_at DESC, m.id DESC
          LIMIT 1
        ) AS last_message,
        (
          SELECT COUNT(*)
          FROM chat_messages m
          WHERE m.conversation_id = c.id
            AND m.is_read = 0
            AND m.is_admin = 0
        ) AS unread_count,
        COALESCE(
          DATE_FORMAT((
            SELECT m.created_at
            FROM chat_messages m
            WHERE m.conversation_id = c.id
            ORDER BY m.created_at DESC, m.id DESC
            LIMIT 1
          ), '%H:%i'),
          ''
        ) AS time_text
      FROM chat_conversations c
      ORDER BY c.created_at DESC, c.id DESC
    `);

    res.json(rows);
  } catch (error) {
    console.error('GET /user-chat/conversations error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/conversations/:conversationId/messages', async (req, res) => {
  try {
    const [rows] = await db.query(
      `
      SELECT
        id,
        text,
        image_url,
        is_admin,
        is_read,
        DATE_FORMAT(created_at, '%H:%i') AS time_text
      FROM chat_messages
      WHERE conversation_id = ?
      ORDER BY created_at ASC, id ASC
      `,
      [req.params.conversationId]
    );

    res.json(
      rows.map((m) => ({
        id: Number(m.id),
        text: m.text ?? '',
        image_url: m.image_url ?? null,
        is_me: Number(m.is_admin || 0) === 1,
        is_admin: Number(m.is_admin || 0) === 1,
        is_read: Number(m.is_read || 0) === 1,
        time_text: m.time_text ?? '',
      }))
    );
  } catch (error) {
    console.error('GET /user-chat/conversations/:conversationId/messages error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.post('/conversations/:conversationId/messages', async (req, res) => {
  try {
    const { text, is_me, is_admin } = req.body;

    const finalIsAdmin =
      typeof is_admin !== 'undefined'
        ? (is_admin ? 1 : 0)
        : (is_me ? 1 : 0);

    const [result] = await db.query(
      `
      INSERT INTO chat_messages (
        conversation_id,
        text,
        is_admin,
        is_read
      ) VALUES (?, ?, ?, ?)
      `,
      [
        req.params.conversationId,
        text || '',
        finalIsAdmin,
        0,
      ]
    );

    const [rows] = await db.query(
      `
      SELECT
        id,
        text,
        image_url,
        is_admin,
        is_read,
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
      text: m.text ?? '',
      image_url: m.image_url ?? null,
      is_me: Number(m.is_admin || 0) === 1,
      is_admin: Number(m.is_admin || 0) === 1,
      is_read: Number(m.is_read || 0) === 1,
      time_text: m.time_text ?? '',
    });
  } catch (error) {
    console.error('POST /user-chat/conversations/:conversationId/messages error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;