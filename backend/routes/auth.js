const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db');

const router = express.Router();

function generateToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      role: user.role,
    },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
}

router.post('/register', async (req, res) => {
  try {
    const { full_name, email, password, confirm_password } = req.body;

    if (!full_name || !email || !password || !confirm_password) {
      return res.status(400).json({
        message: 'กรุณากรอกข้อมูลให้ครบ',
      });
    }

    if (password !== confirm_password) {
      return res.status(400).json({
        message: 'รหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        message: 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร',
      });
    }

    const [existingUsers] = await pool.query(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [email]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        message: 'อีเมลนี้ถูกใช้งานแล้ว',
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const [result] = await pool.query(
      `
      INSERT INTO users (
        full_name,
        email,
        password_hash,
        role,
        status,
        is_verified,
        verify_status
      )
      VALUES (?, ?, ?, ?, ?, ?, ?)
      `,
      [full_name, email, passwordHash, 'user', 'active', 0, 'pending']
    );

    const [rows] = await pool.query(
      `
      SELECT
        id,
        full_name,
        email,
        role,
        status,
        is_verified,
        verify_status,
        created_at
      FROM users
      WHERE id = ?
      LIMIT 1
      `,
      [result.insertId]
    );

    const user = rows[0];
    const token = generateToken(user);

    res.status(201).json({
      message: 'สมัครสมาชิกสำเร็จ',
      token,
      user,
    });
  } catch (error) {
    res.status(500).json({
      message: 'เกิดข้อผิดพลาดในเซิร์ฟเวอร์',
      error: error.message,
    });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        message: 'กรุณากรอกอีเมลและรหัสผ่าน',
      });
    }

    const [rows] = await pool.query(
      `
      SELECT
        id,
        full_name,
        email,
        password_hash,
        role,
        status,
        is_verified,
        verify_status,
        created_at
      FROM users
      WHERE email = ?
      LIMIT 1
      `,
      [email]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        message: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
      });
    }

    const user = rows[0];

    if (role && user.role !== role) {
      return res.status(403).json({
        message: 'สิทธิ์การเข้าใช้งานไม่ถูกต้อง',
      });
    }

    if (user.status === 'suspended') {
      return res.status(403).json({
        message: 'บัญชีของคุณถูกระงับการใช้งาน',
      });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
      return res.status(401).json({
        message: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
      });
    }

    const token = generateToken(user);

    res.json({
      message: 'เข้าสู่ระบบสำเร็จ',
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
        status: user.status,
        is_verified: user.is_verified,
        verify_status: user.verify_status,
      },
    });
  } catch (error) {
    res.status(500).json({
      message: 'เกิดข้อผิดพลาดในเซิร์ฟเวอร์',
      error: error.message,
    });
  }
});

async function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        message: 'ไม่ได้ส่ง token',
      });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const [rows] = await pool.query(
      `
      SELECT
        id,
        full_name,
        email,
        role,
        status,
        is_verified,
        verify_status,
        created_at
      FROM users
      WHERE id = ?
      LIMIT 1
      `,
      [decoded.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'ไม่พบผู้ใช้',
      });
    }

    const user = rows[0];

    if (user.status === 'suspended') {
      return res.status(403).json({
        message: 'บัญชีของคุณถูกระงับการใช้งาน',
      });
    }

    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
      status: user.status,
    };

    next();
  } catch (error) {
    return res.status(401).json({
      message: 'Token ไม่ถูกต้องหรือหมดอายุ',
    });
  }
}

router.get('/me', authMiddleware, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `
      SELECT
        id,
        full_name,
        email,
        role,
        status,
        is_verified,
        verify_status,
        created_at
      FROM users
      WHERE id = ?
      LIMIT 1
      `,
      [req.user.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        message: 'ไม่พบผู้ใช้',
      });
    }

    res.json({
      user: rows[0],
    });
  } catch (error) {
    res.status(500).json({
      message: 'เกิดข้อผิดพลาดในเซิร์ฟเวอร์',
      error: error.message,
    });
  }
});

module.exports = router;