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

// ==============================
// GET /api/dashboard/overview
// ==============================
router.get('/overview', authMiddleware, async (req, res) => {
  try {
    // users
    const [[totalUsers]] = await pool.query(
      `SELECT COUNT(*) AS total FROM users`
    );

    const [[newUsersThisMonth]] = await pool.query(
      `SELECT COUNT(*) AS total
       FROM users
       WHERE MONTH(created_at) = MONTH(CURRENT_DATE())
         AND YEAR(created_at) = YEAR(CURRENT_DATE())`
    );

    const [[newUsersLastMonth]] = await pool.query(
      `SELECT COUNT(*) AS total
       FROM users
       WHERE MONTH(created_at) = MONTH(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
         AND YEAR(created_at) = YEAR(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))`
    );

    // jobs
    const [[openJobs]] = await pool.query(
      `SELECT COUNT(*) AS total
       FROM jobs
       WHERE status IN ('open', 'pending')`
    );

    const [[newJobsThisWeek]] = await pool.query(
      `SELECT COUNT(*) AS total
       FROM jobs
       WHERE created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)`
    );

    const [[jobsLastWeek]] = await pool.query(
      `SELECT COUNT(*) AS total
       FROM jobs
       WHERE created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY)
         AND created_at < DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)`
    );

    // earnings
    // สำคัญ: ต้องนับ paid + withdrawn ทั้งคู่
    const [[totalEarnings]] = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) AS total
       FROM payments
       WHERE status IN ('paid', 'withdrawn')`
    );

    const [[transactionCount]] = await pool.query(
      `SELECT COUNT(*) AS total
       FROM payments
       WHERE status IN ('paid', 'withdrawn')`
    );

    const [[earningsThisMonth]] = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) AS total
       FROM payments
       WHERE status IN ('paid', 'withdrawn')
         AND MONTH(created_at) = MONTH(CURRENT_DATE())
         AND YEAR(created_at) = YEAR(CURRENT_DATE())`
    );

    const [[earningsLastMonth]] = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) AS total
       FROM payments
       WHERE status IN ('paid', 'withdrawn')
         AND MONTH(created_at) = MONTH(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
         AND YEAR(created_at) = YEAR(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))`
    );

    const usersGrowthBase = Number(newUsersLastMonth.total || 0);
    const usersGrowth = usersGrowthBase > 0
        ? Math.round(((Number(newUsersThisMonth.total || 0) - usersGrowthBase) / usersGrowthBase) * 100)
        : (Number(newUsersThisMonth.total || 0) > 0 ? 100 : 0);

    const jobsGrowthBase = Number(jobsLastWeek.total || 0);
    const jobsGrowth = jobsGrowthBase > 0
        ? Math.round(((Number(newJobsThisWeek.total || 0) - jobsGrowthBase) / jobsGrowthBase) * 100)
        : (Number(newJobsThisWeek.total || 0) > 0 ? 100 : 0);

    const earningsGrowthBase = Number(earningsLastMonth.total || 0);
    const earningsGrowth = earningsGrowthBase > 0
        ? Math.round(((Number(earningsThisMonth.total || 0) - earningsGrowthBase) / earningsGrowthBase) * 100)
        : (Number(earningsThisMonth.total || 0) > 0 ? 100 : 0);

    res.json({
      users: {
        total: Number(totalUsers.total || 0),
        new_this_month: Number(newUsersThisMonth.total || 0),
        growth_percent: usersGrowth,
      },
      jobs: {
        open: Number(openJobs.total || 0),
        new_this_week: Number(newJobsThisWeek.total || 0),
        growth_percent: jobsGrowth,
      },
      earnings: {
        total: Number(totalEarnings.total || 0),
        transaction_count: Number(transactionCount.total || 0),
        growth_percent: earningsGrowth,
      },
    });
  } catch (error) {
    console.error('GET /dashboard/overview error:', error);
    res.status(500).json({ message: error.message });
  }
});

// ==============================
// GET /api/dashboard/activities
// ==============================
router.get('/activities', authMiddleware, async (req, res) => {
  try {
    const [newUsers] = await pool.query(
      `
      SELECT
        id,
        CONCAT(full_name, ' สมัครสมาชิกใหม่') AS title,
        CONCAT(TIMESTAMPDIFF(MINUTE, created_at, NOW()), ' นาทีที่แล้ว') AS subtitle,
        'person' AS icon_type,
        created_at
      FROM users
      ORDER BY created_at DESC
      LIMIT 5
      `
    );

    const [newJobs] = await pool.query(
      `
      SELECT
        id,
        CONCAT('มีการโพสต์งานใหม่: ', COALESCE(title, 'ไม่ระบุหัวข้องาน')) AS title,
        CONCAT(TIMESTAMPDIFF(MINUTE, created_at, NOW()), ' นาทีที่แล้ว') AS subtitle,
        'work' AS icon_type,
        created_at
      FROM jobs
      ORDER BY created_at DESC
      LIMIT 5
      `
    );

    const [newPayments] = await pool.query(
      `
      SELECT
        id,
        CONCAT('มีการชำระเงิน ฿', FORMAT(amount, 2)) AS title,
        CONCAT(TIMESTAMPDIFF(MINUTE, created_at, NOW()), ' นาทีที่แล้ว') AS subtitle,
        'payment' AS icon_type,
        created_at
      FROM payments
      WHERE status IN ('paid', 'withdrawn')
      ORDER BY created_at DESC
      LIMIT 5
      `
    );

    const allActivities = [...newUsers, ...newJobs, ...newPayments]
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, 10);

    res.json(allActivities);
  } catch (error) {
    console.error('GET /dashboard/activities error:', error);
    res.status(500).json({ message: error.message });
  }
});

// ==============================
// GET /api/dashboard/charts
// ==============================
router.get('/charts', authMiddleware, async (req, res) => {
  try {
    const [revenueRows] = await pool.query(
      `
      SELECT
        DATE(created_at) AS day_date,
        COALESCE(SUM(amount), 0) AS total
      FROM payments
      WHERE status IN ('paid', 'withdrawn')
        AND created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
      GROUP BY DATE(created_at)
      ORDER BY day_date ASC
      `
    );

    const [jobsRows] = await pool.query(
      `
      SELECT
        DATE(created_at) AS day_date,
        COUNT(*) AS total
      FROM jobs
      WHERE created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY)
      GROUP BY DATE(created_at)
      ORDER BY day_date ASC
      `
    );

    const revenueMap = {};
    for (const row of revenueRows) {
      const key = new Date(row.day_date).toISOString().slice(0, 10);
      revenueMap[key] = Number(row.total || 0);
    }

    const jobsMap = {};
    for (const row of jobsRows) {
      const key = new Date(row.day_date).toISOString().slice(0, 10);
      jobsMap[key] = Number(row.total || 0);
    }

    const revenue7d = [];
    const jobs7d = [];

    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setHours(0, 0, 0, 0);
      d.setDate(d.getDate() - i);

      const isoKey = d.toISOString().slice(0, 10);
      const label = `${String(d.getDate()).padStart(2, '0')}/${String(
        d.getMonth() + 1
      ).padStart(2, '0')}`;

      revenue7d.push({
        label,
        value: revenueMap[isoKey] ?? 0,
      });

      jobs7d.push({
        label,
        value: jobsMap[isoKey] ?? 0,
      });
    }

    res.json({
      revenue_7d: revenue7d,
      jobs_7d: jobs7d,
    });
  } catch (error) {
    console.error('GET /dashboard/charts error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;