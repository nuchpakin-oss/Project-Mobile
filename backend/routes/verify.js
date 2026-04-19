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

function formatTimeAgo(dateValue) {
  const created = new Date(dateValue);
  const now = new Date();
  const diffMs = now - created;
  const diffMin = Math.max(1, Math.floor(diffMs / 60000));

  if (diffMin < 60) return `${diffMin} นาทีที่แล้ว`;

  const diffHour = Math.floor(diffMin / 60);
  if (diffHour < 24) return `${diffHour} ชั่วโมงที่แล้ว`;

  const diffDay = Math.floor(diffHour / 24);
  return `${diffDay} วันที่แล้ว`;
}

// users
router.get('/users', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT
        id,
        full_name,
        email,
        id_number,
        verify_status,
        created_at
      FROM users
      WHERE role = 'user'
      ORDER BY created_at DESC, id DESC
    `);

    res.json(
      rows.map((u) => ({
        id: Number(u.id),
        badge: 'PENDING',
        timeAgo: formatTimeAgo(u.created_at),
        name: u.full_name || '',
        description: u.email || '',
        idNumber: u.id_number || null,
        location: null,
        salary: null,
        tags: [],
        imageUrl: null,
        type: 'person',
        status: u.verify_status || 'pending',
      }))
    );
  } catch (error) {
    console.error('GET /verify/users error:', error);
    res.status(500).json({ message: error.message });
  }
});

// portfolios
router.get('/portfolios', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT
        id,
        user_name,
        description,
        tags,
        image_url,
        verify_status,
        created_at
      FROM portfolios
      ORDER BY created_at DESC, id DESC
    `);

    res.json(
      rows.map((p) => ({
        id: Number(p.id),
        badge: 'PENDING',
        timeAgo: formatTimeAgo(p.created_at),
        name: p.user_name || '',
        description: p.description || '',
        idNumber: null,
        location: null,
        salary: null,
        tags: (p.tags || '')
          .split(',')
          .map((t) => t.trim())
          .filter((t) => t.isNotEmpty),
        imageUrl: p.image_url || null,
        type: 'portfolio',
        status: p.verify_status || 'pending',
      }))
    );
  } catch (error) {
    console.error('GET /verify/portfolios error:', error);
    res.status(500).json({ message: error.message });
  }
});

// jobs
router.get('/jobs', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT
        id,
        company_name,
        description,
        location,
        salary,
        image_url,
        verify_status,
        created_at
      FROM verify_jobs
      ORDER BY created_at DESC, id DESC
    `);

    res.json(
      rows.map((j) => ({
        id: Number(j.id),
        badge: 'PENDING',
        timeAgo: formatTimeAgo(j.created_at),
        name: j.company_name || '',
        description: j.description || '',
        idNumber: null,
        location: j.location || null,
        salary: j.salary || null,
        tags: [],
        imageUrl: j.image_url || null,
        type: 'company',
        status: j.verify_status || 'pending',
      }))
    );
  } catch (error) {
    console.error('GET /verify/jobs error:', error);
    res.status(500).json({ message: error.message });
  }
});

// update users
router.patch('/users/:id', authMiddleware, async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { status } = req.body;

    if (!['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'status ไม่ถูกต้อง' });
    }

    await pool.query(
      `
      UPDATE users
      SET verify_status = ?, is_verified = ?
      WHERE id = ?
      `,
      [status, status === 'approved' ? 1 : 0, id]
    );

    res.json({ message: 'อัปเดตการตรวจสอบผู้ใช้สำเร็จ' });
  } catch (error) {
    console.error('PATCH /verify/users/:id error:', error);
    res.status(500).json({ message: error.message });
  }
});

// update portfolios
router.patch('/portfolios/:id', authMiddleware, async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { status } = req.body;

    if (!['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'status ไม่ถูกต้อง' });
    }

    await pool.query(
      `
      UPDATE portfolios
      SET verify_status = ?
      WHERE id = ?
      `,
      [status, id]
    );

    res.json({ message: 'อัปเดตการตรวจสอบพอร์ตโฟลิโอสำเร็จ' });
  } catch (error) {
    console.error('PATCH /verify/portfolios/:id error:', error);
    res.status(500).json({ message: error.message });
  }
});

// update jobs
router.patch('/jobs/:id', authMiddleware, async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { status } = req.body;

    if (!['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'status ไม่ถูกต้อง' });
    }

    await pool.query(
      `
      UPDATE verify_jobs
      SET verify_status = ?
      WHERE id = ?
      `,
      [status, id]
    );

    res.json({ message: 'อัปเดตการตรวจสอบงานสำเร็จ' });
  } catch (error) {
    console.error('PATCH /verify/jobs/:id error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;