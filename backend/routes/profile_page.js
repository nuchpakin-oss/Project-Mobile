// routes/profile.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('../db');

// ==============================
// upload dirs
// ==============================
const profileUploadDir = path.join(__dirname, '..', 'uploads', 'profiles');
if (!fs.existsSync(profileUploadDir)) {
  fs.mkdirSync(profileUploadDir, { recursive: true });
}

const portfolioUploadDir = path.join(__dirname, '..', 'uploads', 'portfolios');
if (!fs.existsSync(portfolioUploadDir)) {
  fs.mkdirSync(portfolioUploadDir, { recursive: true });
}

// ==============================
// multer: profile image
// ==============================
const profileStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, profileUploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname || '.jpg') || '.jpg';
    cb(null, `user_${req.params.id}_${Date.now()}${ext}`);
  },
});

const profileUpload = multer({
  storage: profileStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const mime = (file.mimetype || '').toLowerCase();
    const ext = path.extname(file.originalname || '').toLowerCase();

    const allowedExts = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
    const isImageMime = mime.startsWith('image/');
    const isImageExt = allowedExts.includes(ext);

    if (isImageMime || isImageExt) {
      return cb(null, true);
    }

    cb(new Error('อนุญาตเฉพาะไฟล์รูปภาพเท่านั้น'));
  },
});

// ==============================
// multer: portfolio images
// ==============================
const portfolioStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, portfolioUploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname || '.jpg') || '.jpg';
    cb(
      null,
      `portfolio_${req.params.id}_${Date.now()}_${Math.floor(
        Math.random() * 10000
      )}${ext}`
    );
  },
});

const portfolioUpload = multer({
  storage: portfolioStorage,
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const mime = (file.mimetype || '').toLowerCase();
    const ext = path.extname(file.originalname || '').toLowerCase();

    const allowedExts = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
    const isImageMime = mime.startsWith('image/');
    const isImageExt = allowedExts.includes(ext);

    if (isImageMime || isImageExt) {
      return cb(null, true);
    }

    cb(new Error('อนุญาตเฉพาะไฟล์รูปภาพเท่านั้น'));
  },
});

// ==============================
// helpers
// ==============================
function parseSkills(raw) {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [String(parsed)];
  } catch {
    return String(raw)
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
  }
}

function formatUser(u) {
  return {
    id: Number(u.id),
    full_name: u.full_name ?? '',
    email: u.email ?? '',
    phone: u.phone ?? null,
    bio: u.bio ?? null,
    job_title: u.job_title ?? null,
    skills: parseSkills(u.skills),
    profile_image_url: u.profile_image_url ?? null,
    rating: Number(u.rating) || 0,
    total_jobs: Number(u.total_jobs) || 0,
    is_verified: u.is_verified === 1 ? 1 : 0,
  };
}

// ==============================
// GET /api/users/:id/profile
// ==============================
router.get('/users/:id/profile', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, full_name, email, phone, bio,
              job_title, skills, profile_image_url,
              rating, total_jobs, is_verified
       FROM users
       WHERE id = ?`,
      [req.params.id]
    );

    if (!rows.length) {
      return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
    }

    res.json(formatUser(rows[0]));
  } catch (err) {
    console.error('GET /users/:id/profile error:', err);
    res.status(500).json({ message: err.message });
  }
});

// ==============================
// PUT /api/users/:id/profile
// ==============================
router.put(
  '/users/:id/profile',
  profileUpload.single('profile_image'),
  async (req, res) => {
    try {
      const { full_name, email, phone, bio, job_title, skills } = req.body;

      let skillsStr = null;
      if (skills !== undefined) {
        try {
          const arr = JSON.parse(skills);
          skillsStr = Array.isArray(arr) ? arr.join(',') : String(skills);
        } catch {
          skillsStr = String(skills);
        }
      }

      let profileImageUrl = undefined;
      if (req.file) {
        const host = `${req.protocol}://${req.get('host')}`;
        profileImageUrl = `${host}/uploads/profiles/${req.file.filename}`;
      }

      const sets = [];
      const params = [];

      if (full_name !== undefined) {
        sets.push('full_name = ?');
        params.push(full_name);
      }
      if (email !== undefined) {
        sets.push('email = ?');
        params.push(email);
      }
      if (phone !== undefined) {
        sets.push('phone = ?');
        params.push(phone || null);
      }
      if (bio !== undefined) {
        sets.push('bio = ?');
        params.push(bio || null);
      }
      if (job_title !== undefined) {
        sets.push('job_title = ?');
        params.push(job_title || null);
      }
      if (skillsStr !== null) {
        sets.push('skills = ?');
        params.push(skillsStr);
      }
      if (profileImageUrl !== undefined) {
        sets.push('profile_image_url = ?');
        params.push(profileImageUrl);
      }

      if (sets.length > 0) {
        sets.push('updated_at = NOW()');
        params.push(req.params.id);
        await db.query(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`, params);
      }

      const [rows] = await db.query(
        `SELECT id, full_name, email, phone, bio,
                job_title, skills, profile_image_url,
                rating, total_jobs, is_verified
         FROM users
         WHERE id = ?`,
        [req.params.id]
      );

      res.json(formatUser(rows[0]));
    } catch (err) {
      console.error('PUT /users/:id/profile error:', err);
      res.status(500).json({ message: err.message });
    }
  }
);

// ==============================
// POST /api/users/:id/portfolios
// ==============================
router.post(
  '/users/:id/portfolios',
  portfolioUpload.array('images', 20),
  async (req, res) => {
    try {
      const userId = req.params.id;

      const [userRows] = await db.query(
        `SELECT id, full_name FROM users WHERE id = ? LIMIT 1`,
        [userId]
      );

      if (!userRows.length) {
        return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
      }

      if (!req.files || !req.files.length) {
        return res.status(400).json({ message: 'กรุณาเลือกรูปผลงาน' });
      }

      const user = userRows[0];
      const description = req.body.description || '';
      const tags = req.body.tags || '';
      const host = `${req.protocol}://${req.get('host')}`;
      const inserted = [];

      for (const file of req.files) {
        const imageUrl = `${host}/uploads/portfolios/${file.filename}`;

        const [result] = await db.query(
          `
          INSERT INTO portfolios (
            user_id,
            user_name,
            description,
            tags,
            image_url,
            verify_status
          ) VALUES (?, ?, ?, ?, ?, 'approved')
          `,
          [userId, user.full_name || '', description, tags, imageUrl]
        );

        inserted.push({
          id: Number(result.insertId),
          user_id: Number(userId),
          user_name: user.full_name || '',
          description,
          tags,
          image_url: imageUrl,
          verify_status: 'approved',
        });
      }

      res.status(201).json(inserted);
    } catch (err) {
      console.error('POST /users/:id/portfolios error:', err);
      res.status(500).json({ message: err.message });
    }
  }
);

// ==============================
// GET /api/users/:id/portfolios
// ==============================
router.get('/users/:id/portfolios', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, user_id, user_name, description, tags, image_url, verify_status
       FROM portfolios
       WHERE user_id = ?
       ORDER BY id DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    console.error('GET /users/:id/portfolios error:', err);
    res.status(500).json({ message: err.message });
  }
});

// ==============================
// GET /api/users/:id/earnings
// ==============================
router.get('/users/:id/earnings', async (req, res) => {
  try {
    const userId = req.params.id;

    const [[monthRow]] = await db.query(
      `SELECT COALESCE(SUM(amount), 0) AS total_month
       FROM payments
       WHERE worker_user_id = ?
         AND status IN ('paid', 'withdrawn')
         AND MONTH(created_at) = MONTH(CURRENT_DATE())
         AND YEAR(created_at) = YEAR(CURRENT_DATE())`,
      [userId]
    );

    const [[prevRow]] = await db.query(
      `SELECT COALESCE(SUM(amount), 0) AS previous_month
       FROM payments
       WHERE worker_user_id = ?
         AND status IN ('paid', 'withdrawn')
         AND MONTH(created_at) = MONTH(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
         AND YEAR(created_at) = YEAR(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))`,
      [userId]
    );

    const [[balanceRow]] = await db.query(
      `SELECT COALESCE(SUM(amount), 0) AS available_balance
       FROM payments
       WHERE worker_user_id = ?
         AND status = 'paid'`,
      [userId]
    );

    const [recentItems] = await db.query(
      `SELECT
         id,
         worker_user_id AS user_id,
         amount,
         payment_method AS title,
         CONCAT('ชำระเงินงาน #', job_id) AS description,
         DATE(created_at) AS work_date,
         status
       FROM payments
       WHERE worker_user_id = ?
         AND status IN ('paid', 'withdrawn')
       ORDER BY created_at DESC
       LIMIT 10`,
      [userId]
    );

    res.json({
      total_month: Number(monthRow.total_month) || 0,
      previous_month: Number(prevRow.previous_month) || 0,
      available_balance: Number(balanceRow.available_balance) || 0,
      recent_items: recentItems,
    });
  } catch (err) {
    console.error('GET /users/:id/earnings error:', err);
    res.status(500).json({ message: err.message });
  }
});

// ==============================
// POST /api/users/:id/withdraw
// ==============================
router.post('/users/:id/withdraw', async (req, res) => {
  try {
    const userId = req.params.id;
    const {
      payout_method,
      payout_name,
      payout_account,
    } = req.body;

    if (!payout_method || !payout_account) {
      return res.status(400).json({
        message: 'กรุณากรอกข้อมูลการถอนเงินให้ครบ',
      });
    }

    const [[row]] = await db.query(
      `SELECT COALESCE(SUM(amount), 0) AS total
       FROM payments
       WHERE worker_user_id = ?
         AND status = 'paid'`,
      [userId]
    );

    const amount = Number(row.total || 0);

    if (amount <= 0) {
      return res.status(400).json({
        message: 'ไม่มียอดเงินให้ถอน',
      });
    }

    await db.query(
      `UPDATE payments
       SET status = 'withdrawn'
       WHERE worker_user_id = ?
         AND status = 'paid'`,
      [userId]
    );

    const now = new Date();
    const referenceCode = `WD${Date.now()}${Math.floor(Math.random() * 900 + 100)}`;

    const [insertResult] = await db.query(
      `INSERT INTO withdrawals (
        user_id,
        amount,
        reference_code,
        status,
        note,
        transferred_at,
        payout_method,
        payout_name,
        payout_account
      ) VALUES (?, ?, ?, 'success', ?, ?, ?, ?, ?)`,
      [
        userId,
        amount,
        referenceCode,
        'โอนเงินเข้าบัญชีเรียบร้อย',
        now,
        payout_method,
        payout_name || null,
        payout_account,
      ]
    );

    res.json({
      message: 'ถอนเงินสำเร็จ',
      withdrawal: {
        id: Number(insertResult.insertId),
        user_id: Number(userId),
        amount,
        reference_code: referenceCode,
        status: 'success',
        note: 'โอนเงินเข้าบัญชีเรียบร้อย',
        transferred_at: now,
        payout_method,
        payout_name: payout_name || '',
        payout_account,
      },
    });
  } catch (err) {
    console.error('POST /users/:id/withdraw error:', err);
    res.status(500).json({
      message: 'ถอนเงินไม่สำเร็จ',
      error: err.message,
    });
  }
});
module.exports = router;