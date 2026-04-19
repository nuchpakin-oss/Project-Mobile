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

// รายได้รวมฝั่ง admin จาก payments จริง
router.get('/summary', authMiddleware, async (req, res) => {
  try {
    const [[summary]] = await pool.query(
      `
      SELECT
        IFNULL(SUM(amount), 0) AS total_amount,
        COUNT(*) AS total_transactions
      FROM payments
      WHERE status = 'paid'
      `
    );

    const [recent] = await pool.query(
      `
      SELECT
        p.id,
        p.job_id,
        p.worker_user_id,
        u.full_name AS worker_name,
        j.title AS job_title,
        p.amount,
        p.status,
        p.payment_method,
        p.created_at,
        p.paid_at
      FROM payments p
      LEFT JOIN users u ON u.id = p.worker_user_id
      LEFT JOIN jobs j ON j.id = p.job_id
      WHERE p.status = 'paid'
      ORDER BY p.created_at DESC
      LIMIT 20
      `
    );

    res.json({
      total_amount: Number(summary.total_amount),
      total_transactions: Number(summary.total_transactions),
      items: recent.map((r) => ({
        id: Number(r.id),
        job_id: Number(r.job_id),
        worker_user_id: Number(r.worker_user_id),
        worker_name: r.worker_name || '-',
        job_title: r.job_title || '-',
        amount: Number(r.amount),
        status: r.status || 'pending',
        payment_method: r.payment_method || '-',
        created_at: r.created_at,
        paid_at: r.paid_at,
      })),
    });
  } catch (error) {
    console.error('GET /earnings/summary error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;