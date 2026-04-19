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

function formatRegisteredDate(dateValue) {
  const date = new Date(dateValue);
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = date.getFullYear();
  return `สมัครเมื่อ ${day}/${month}/${year}`;
}

router.get('/', authMiddleware, async (req, res) => {
  try {
    const search = (req.query.search || '').toString().trim();
    const status = (req.query.status || 'all').toString().trim();

    const conditions = [];
    const params = [];

    if (search) {
      conditions.push(`(
        u.full_name LIKE ?
        OR u.email LIKE ?
        OR u.phone LIKE ?
      )`);
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    if (status !== 'all') {
      if (status === 'pending') {
        conditions.push(`u.verify_status = 'pending'`);
      } else {
        conditions.push(`u.status = ?`);
        params.push(status);
      }
    }

    const whereClause =
      conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const [rows] = await pool.query(
      `
      SELECT
        u.id,
        u.full_name,
        u.email,
        u.created_at,
        u.status,
        u.phone,
        u.rating_avg,
        u.total_jobs,
        u.is_verified,
        u.bio,
        u.profile_image_url
      FROM users u
      ${whereClause}
      ORDER BY u.created_at DESC, u.id DESC
      `,
      params
    );

    res.json(
      rows.map((u) => ({
        id: Number(u.id),
        name: u.full_name || '',
        email: u.email || '',
        registeredDate: formatRegisteredDate(u.created_at),
        status: u.status || 'active',
        isOnline: false,
        phone: u.phone || null,
        rating: Number(u.rating_avg || 0),
        totalJobs: Number(u.total_jobs || 0),
        isVerified: Number(u.is_verified || 0) === 1,
        bio: u.bio || null,
        avatarUrl: u.profile_image_url || null,
      }))
    );
  } catch (error) {
    console.error('GET /users error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.patch('/:id/status', authMiddleware, async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { status } = req.body;

    if (!['active', 'suspended', 'pending'].includes(status)) {
      return res.status(400).json({ message: 'status ไม่ถูกต้อง' });
    }

    await pool.query(
      `
      UPDATE users
      SET status = ?
      WHERE id = ?
      `,
      [status, id]
    );

    res.json({ message: 'อัปเดตสถานะผู้ใช้สำเร็จ' });
  } catch (error) {
    console.error('PATCH /users/:id/status error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const id = Number(req.params.id);

    await pool.query(`DELETE FROM users WHERE id = ?`, [id]);

    res.json({ message: 'ลบผู้ใช้สำเร็จ' });
  } catch (error) {
    console.error('DELETE /users/:id error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;