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
    const [rows] = await pool.query(
      `
      SELECT
        r.id,
        r.job_id,
        r.reporter_user_id,
        r.reported_user_id,
        r.reason,
        r.details,
        r.status,
        r.created_at,
        reporter.full_name AS reporter_name,
        reported.full_name AS reported_name,
        j.title AS job_title
      FROM reports r
      LEFT JOIN users reporter ON reporter.id = r.reporter_user_id
      LEFT JOIN users reported ON reported.id = r.reported_user_id
      LEFT JOIN jobs j ON j.id = r.job_id
      ORDER BY r.created_at DESC
      `
    );

    res.json(
      rows.map((r) => ({
        id: Number(r.id),
        job_id: r.job_id == null ? null : Number(r.job_id),
        reporter_user_id: Number(r.reporter_user_id),
        reported_user_id:
            r.reported_user_id == null ? null : Number(r.reported_user_id),
        reason: r.reason || '',
        details: r.details || '',
        status: r.status || 'pending',
        created_at: r.created_at,
        reporter_name: r.reporter_name || '-',
        reported_name: r.reported_name || '-',
        job_title: r.job_title || '-',
      }))
    );
  } catch (error) {
    console.error('GET /report error:', error);
    res.status(500).json({ message: error.message });
  }
});

// POST /api/report
router.post('/', authMiddleware, async (req, res) => {
  try {
    const {
      job_id,
      reporter_user_id,
      reported_user_id,
      reason,
      details,
    } = req.body;

    if (!job_id || !reporter_user_id || !reported_user_id || !reason) {
      return res.status(400).json({
        message: 'ข้อมูลไม่ครบ',
      });
    }

    await pool.query(
      `
      INSERT INTO reports 
      (job_id, reporter_user_id, reported_user_id, reason, details, status)
      VALUES (?, ?, ?, ?, ?, 'pending')
      `,
      [job_id, reporter_user_id, reported_user_id, reason, details || '']
    );

    res.status(201).json({
      message: 'รายงานสำเร็จ',
    });
  } catch (error) {
    console.error('POST /report error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;