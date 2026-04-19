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
        r.worker_user_id,
        r.reviewer_user_id,
        r.rating,
        r.review_text,
        r.image_url,
        r.tip_amount,
        r.created_at,
        worker.full_name AS worker_name,
        reviewer.full_name AS reviewer_name,
        j.title AS job_title
      FROM worker_reviews r
      LEFT JOIN users worker ON worker.id = r.worker_user_id
      LEFT JOIN users reviewer ON reviewer.id = r.reviewer_user_id
      LEFT JOIN jobs j ON j.id = r.job_id
      ORDER BY r.created_at DESC
      `
    );

    res.json(
      rows.map((r) => ({
        id: Number(r.id),
        job_id: Number(r.job_id),
        worker_user_id: Number(r.worker_user_id),
        reviewer_user_id: Number(r.reviewer_user_id),
        rating: Number(r.rating),
        review_text: r.review_text || '',
        image_url: r.image_url || null,
        tip_amount: Number(r.tip_amount || 0),
        created_at: r.created_at,
        worker_name: r.worker_name || '-',
        reviewer_name: r.reviewer_name || '-',
        job_title: r.job_title || '-',
      }))
    );
  } catch (error) {
    console.error('GET /reviews error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;