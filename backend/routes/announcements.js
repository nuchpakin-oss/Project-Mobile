const express = require('express');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const router = express.Router();

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

router.get('/', authMiddleware, async (req, res) => {
  try {
    const userRole = req.user.role || 'user';

    const [rows] = await pool.query(
      `
      SELECT
        id,
        title,
        content,
        target_group,
        image_url,
        created_at
      FROM announcements
      WHERE target_group IS NULL
         OR target_group = ''
         OR target_group = 'all'
         OR target_group = ?
      ORDER BY created_at DESC, id DESC
      `,
      [userRole]
    );

    res.json(
      rows.map((a) => ({
        id: Number(a.id),
        title: a.title || '',
        content: a.content || '',
        target_group: a.target_group || 'all',
        image_url: a.image_url || null,
        created_at: a.created_at,
      }))
    );
  } catch (error) {
    console.error('GET /announcements error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  try {
    const { title, content, target_group, image_url } = req.body;

    if (!title || !content) {
      return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบ' });
    }

    const [result] = await pool.query(
      `
      INSERT INTO announcements (title, content, target_group, image_url)
      VALUES (?, ?, ?, ?)
      `,
      [
        title.toString().trim(),
        content.toString().trim(),
        (target_group || 'all').toString().trim(),
        image_url ? image_url.toString().trim() : null,
      ]
    );

    res.status(201).json({
      message: 'สร้างประกาศสำเร็จ',
      id: Number(result.insertId),
    });
  } catch (error) {
    console.error('POST /announcements error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const announcementId = Number(req.params.id);
    const { title, content, target_group, image_url } = req.body;

    await pool.query(
      `
      UPDATE announcements
      SET title = ?, content = ?, target_group = ?, image_url = ?
      WHERE id = ?
      `,
      [
        title,
        content,
        target_group || 'all',
        image_url || null,
        announcementId,
      ]
    );

    res.json({ message: 'แก้ไขประกาศสำเร็จ' });
  } catch (error) {
    console.error('PUT /announcements/:id error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const announcementId = Number(req.params.id);

    await pool.query(
      `DELETE FROM announcements WHERE id = ?`,
      [announcementId]
    );

    res.json({ message: 'ลบประกาศสำเร็จ' });
  } catch (error) {
    console.error('DELETE /announcements/:id error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;