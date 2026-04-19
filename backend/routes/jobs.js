const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('../db');

const router = express.Router();

const uploadDir = path.join(__dirname, '..', 'uploads', 'jobs');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadDir),
  filename: (_, file, cb) => {
    const ext = path.extname(file.originalname || '.jpg');
    cb(null, `job_${Date.now()}${ext}`);
  },
});

const upload = multer({ storage });

function formatJob(job) {
  return {
    id: Number(job.id),
    title: job.title ?? '',
    category: job.category ?? '',
    description: job.description ?? '',
    image_url: job.image_url ?? '',
    budget: Number(job.budget || 0),
    location: job.location ?? '',
    work_date: job.work_date ?? '',
    work_time: job.work_time ?? '',
    status: job.status ?? 'open',
    payment_status: job.payment_status ?? 'pending',
    user_id: job.user_id == null ? null : Number(job.user_id),
    assigned_worker_id:
      job.assigned_worker_id == null ? null : Number(job.assigned_worker_id),
    created_at: job.created_at,
  };
}

router.get('/jobs', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT
        j.*,
        (
          SELECT p.status
          FROM payments p
          WHERE p.job_id = j.id
          ORDER BY p.id DESC
          LIMIT 1
        ) AS payment_status
      FROM jobs j
      WHERE j.status <> 'closed'
      ORDER BY j.created_at DESC, j.id DESC
    `);

    res.json(rows.map(formatJob));
  } catch (error) {
    console.error('GET /jobs error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/jobs/:id', async (req, res) => {
  try {
    const [rows] = await db.query(
      `
      SELECT
        j.*,
        (
          SELECT p.status
          FROM payments p
          WHERE p.job_id = j.id
          ORDER BY p.id DESC
          LIMIT 1
        ) AS payment_status
      FROM jobs j
      WHERE j.id = ?
      LIMIT 1
      `,
      [req.params.id]
    );

    if (!rows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    res.json(formatJob(rows[0]));
  } catch (error) {
    console.error('GET /jobs/:id error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.post('/jobs', upload.single('image'), async (req, res) => {
  try {
    const {
      title,
      category,
      description,
      budget,
      location,
      work_date,
      work_time,
      user_id,
    } = req.body;

    let imageUrl = '';
    if (req.file) {
        imageUrl = `https://192.168.1.162:3000/uploads/jobs/${req.file.filename}`;
    }

    const [result] = await db.query(
      `INSERT INTO jobs
       (title, category, description, image_url, budget, location, work_date, work_time, status, user_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'open', ?)`,
      [
        title,
        category || null,
        description || null,
        imageUrl || null,
        budget || 0,
        location || null,
        work_date || null,
        work_time || null,
        user_id || null,
      ]
    );

    const [rows] = await db.query(
      `
      SELECT
        j.*,
        (
          SELECT p.status
          FROM payments p
          WHERE p.job_id = j.id
          ORDER BY p.id DESC
          LIMIT 1
        ) AS payment_status
      FROM jobs j
      WHERE j.id = ?
      LIMIT 1
      `,
      [result.insertId]
    );

    res.status(201).json(formatJob(rows[0]));
  } catch (error) {
    console.error('POST /jobs error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/jobs/user/:userId/hiring', async (req, res) => {
  try {
    const [rows] = await db.query(
      `
      SELECT
        j.*,
        (
          SELECT p.status
          FROM payments p
          WHERE p.job_id = j.id
          ORDER BY p.id DESC
          LIMIT 1
        ) AS payment_status
      FROM jobs j
      WHERE j.user_id = ?
        AND j.status <> 'closed'
      ORDER BY j.created_at DESC, j.id DESC
      `,
      [req.params.userId]
    );

    res.json(rows.map(formatJob));
  } catch (error) {
    console.error('GET /jobs/user/:userId/hiring error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.post('/jobs/:id/apply', async (req, res) => {
  try {
    const { worker_user_id } = req.body;
    const jobId = req.params.id;

    const [rows] = await db.query(
      `SELECT * FROM jobs WHERE id = ?`,
      [jobId]
    );

    if (!rows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    const job = rows[0];

    if (Number(job.user_id) === Number(worker_user_id)) {
      return res.status(400).json({ message: 'ไม่สามารถสมัครงานของตัวเองได้' });
    }

    const [existing] = await db.query(
      `SELECT * FROM job_applicants
       WHERE job_id = ? AND worker_user_id = ?`,
      [jobId, worker_user_id]
    );

    if (existing.length) {
      return res.status(400).json({ message: 'คุณสมัครงานนี้ไปแล้ว' });
    }

    await db.query(
      `INSERT INTO job_applicants (job_id, worker_user_id, status)
       VALUES (?, ?, 'applied')`,
      [jobId, worker_user_id]
    );

    res.json({
      message: 'สมัครงานสำเร็จ',
      job_id: Number(jobId),
      worker_user_id: Number(worker_user_id),
    });
  } catch (error) {
    console.error('POST /jobs/:id/apply error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.put('/jobs/:id/cancel', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT * FROM jobs WHERE id = ?`,
      [req.params.id]
    );

    if (!rows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    await db.query(
      `UPDATE jobs
       SET status = 'closed'
       WHERE id = ?`,
      [req.params.id]
    );

    const [updatedRows] = await db.query(
      `
      SELECT
        j.*,
        (
          SELECT p.status
          FROM payments p
          WHERE p.job_id = j.id
          ORDER BY p.id DESC
          LIMIT 1
        ) AS payment_status
      FROM jobs j
      WHERE j.id = ?
      LIMIT 1
      `,
      [req.params.id]
    );

    res.json(formatJob(updatedRows[0]));
  } catch (error) {
    console.error('PUT /jobs/:id/cancel error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/jobs/user/:userId/accepted', async (req, res) => {
  try {
    const [rows] = await db.query(
      `
      SELECT
        j.*,
        (
          SELECT p.status
          FROM payments p
          WHERE p.job_id = j.id
          ORDER BY p.id DESC
          LIMIT 1
        ) AS payment_status
      FROM jobs j
      WHERE j.assigned_worker_id = ?
        AND j.status <> 'closed'
      ORDER BY j.created_at DESC, j.id DESC
      `,
      [req.params.userId]
    );

    res.json(rows.map(formatJob));
  } catch (error) {
    console.error('GET /jobs/user/:userId/accepted error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/jobs/:id/applicants', async (req, res) => {
  try {
    const jobId = req.params.id;

    const [jobRows] = await db.query(
      `
      SELECT
        j.*,
        (
          SELECT p.status
          FROM payments p
          WHERE p.job_id = j.id
          ORDER BY p.id DESC
          LIMIT 1
        ) AS payment_status
      FROM jobs j
      WHERE j.id = ?
      LIMIT 1
      `,
      [jobId]
    );

    if (!jobRows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    const [rows] = await db.query(
      `
      SELECT
        ja.id,
        ja.job_id,
        ja.worker_user_id,
        ja.status,
        ja.applied_at,
        u.full_name,
        u.email,
        u.phone,
        u.profile_image_url,
        u.job_title,
        u.bio,
        u.skills
      FROM job_applicants ja
      INNER JOIN users u ON u.id = ja.worker_user_id
      WHERE ja.job_id = ?
      ORDER BY ja.applied_at DESC, ja.id DESC
      `,
      [jobId]
    );

    res.json({
      job: formatJob(jobRows[0]),
      applicants: rows.map((r) => ({
        id: Number(r.id),
        job_id: Number(r.job_id),
        worker_user_id: Number(r.worker_user_id),
        status: r.status ?? 'applied',
        applied_at: r.applied_at,
        name: r.full_name ?? '',
        email: r.email ?? '',
        phone: r.phone ?? '',
        img: r.profile_image_url ?? '',
        job_title: r.job_title ?? '',
        desc: r.bio ?? '',
        skills: r.skills ?? '',
      })),
    });
  } catch (error) {
    console.error('GET /jobs/:id/applicants error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.put('/jobs/:jobId/hire/:applicantId', async (req, res) => {
  try {
    const { jobId, applicantId } = req.params;

    const [applicantRows] = await db.query(
      `SELECT * FROM job_applicants WHERE id = ? AND job_id = ?`,
      [applicantId, jobId]
    );

    if (!applicantRows.length) {
      return res.status(404).json({ message: 'ไม่พบผู้สมัคร' });
    }

    const applicant = applicantRows[0];

    await db.query(
      `UPDATE jobs
       SET assigned_worker_id = ?, status = 'pending'
       WHERE id = ?`,
      [applicant.worker_user_id, jobId]
    );

    await db.query(
      `UPDATE job_applicants
       SET status = CASE
         WHEN id = ? THEN 'hired'
         ELSE 'rejected'
       END
       WHERE job_id = ?`,
      [applicantId, jobId]
    );

    const [updatedJobRows] = await db.query(
      `
      SELECT
        j.*,
        (
          SELECT p.status
          FROM payments p
          WHERE p.job_id = j.id
          ORDER BY p.id DESC
          LIMIT 1
        ) AS payment_status
      FROM jobs j
      WHERE j.id = ?
      LIMIT 1
      `,
      [jobId]
    );

    res.json(formatJob(updatedJobRows[0]));
  } catch (error) {
    console.error('PUT /jobs/:jobId/hire/:applicantId error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/jobs/:id/hired-worker', async (req, res) => {
  try {
    const jobId = req.params.id;

    const [jobRows] = await db.query(
      `SELECT * FROM jobs WHERE id = ?`,
      [jobId]
    );

    if (!jobRows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    const job = jobRows[0];

    if (!job.assigned_worker_id) {
      return res.status(404).json({ message: 'งานนี้ยังไม่มีผู้รับจ้าง' });
    }

    const [rows] = await db.query(
      `
      SELECT
        u.id,
        u.full_name,
        u.email,
        u.phone,
        u.profile_image_url,
        u.job_title,
        u.bio,
        u.skills,
        ja.id AS applicant_id,
        ja.status
      FROM users u
      LEFT JOIN job_applicants ja
        ON ja.worker_user_id = u.id AND ja.job_id = ?
      WHERE u.id = ?
      LIMIT 1
      `,
      [jobId, job.assigned_worker_id]
    );

    if (!rows.length) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลผู้รับจ้าง' });
    }

    const r = rows[0];

    res.json({
      id: Number(r.applicant_id || 0),
      job_id: Number(jobId),
      worker_user_id: Number(r.id),
      status: r.status ?? 'hired',
      name: r.full_name ?? '',
      email: r.email ?? '',
      phone: r.phone ?? '',
      img: r.profile_image_url ?? '',
      job_title: r.job_title ?? '',
      desc: r.bio ?? '',
      skills: r.skills ?? '',
    });
  } catch (error) {
    console.error('GET /jobs/:id/hired-worker error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/jobs/:id/payment-summary/:workerUserId', async (req, res) => {
  try {
    const jobId = req.params.id;
    const workerUserId = req.params.workerUserId;

    const [jobRows] = await db.query(
      `
      SELECT
        j.*,
        (
          SELECT p.status
          FROM payments p
          WHERE p.job_id = j.id
          ORDER BY p.id DESC
          LIMIT 1
        ) AS payment_status
      FROM jobs j
      WHERE j.id = ?
      LIMIT 1
      `,
      [jobId]
    );

    if (!jobRows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    const [workerRows] = await db.query(
      `
      SELECT
        id,
        full_name,
        email,
        phone,
        profile_image_url,
        job_title,
        bio,
        skills
      FROM users
      WHERE id = ?
      LIMIT 1
      `,
      [workerUserId]
    );

    if (!workerRows.length) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลผู้รับจ้าง' });
    }

    const [paymentRows] = await db.query(
      `
      SELECT *
      FROM payments
      WHERE job_id = ? AND worker_user_id = ?
      ORDER BY id DESC
      LIMIT 1
      `,
      [jobId, workerUserId]
    );

    const job = jobRows[0];
    const worker = workerRows[0];
    const latestPayment = paymentRows[0] || null;

    res.json({
      job: formatJob(job),
      worker: {
        id: Number(worker.id),
        name: worker.full_name ?? '',
        email: worker.email ?? '',
        phone: worker.phone ?? '',
        img: worker.profile_image_url ?? '',
        job_title: worker.job_title ?? '',
        desc: worker.bio ?? '',
        skills: worker.skills ?? '',
      },
      payment: latestPayment
        ? {
            id: Number(latestPayment.id),
            amount: Number(latestPayment.amount || 0),
            status: latestPayment.status ?? 'pending',
            payment_method: latestPayment.payment_method ?? 'manual',
            paid_at: latestPayment.paid_at,
          }
        : null,
    });
  } catch (error) {
    console.error('GET /jobs/:id/payment-summary/:workerUserId error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.post('/jobs/:id/pay', async (req, res) => {
  try {
    const jobId = req.params.id;
    const { worker_user_id, amount, payment_method } = req.body;

    const [jobRows] = await db.query(
      `SELECT * FROM jobs WHERE id = ?`,
      [jobId]
    );

    if (!jobRows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    const [workerRows] = await db.query(
      `SELECT * FROM users WHERE id = ?`,
      [worker_user_id]
    );

    if (!workerRows.length) {
      return res.status(404).json({ message: 'ไม่พบผู้รับจ้าง' });
    }

    const finalAmount = Number(amount || 0);

    const [result] = await db.query(
      `
      INSERT INTO payments (
        job_id,
        worker_user_id,
        amount,
        status,
        payment_method,
        paid_at
      ) VALUES (?, ?, ?, 'paid', ?, NOW())
      `,
      [
        jobId,
        worker_user_id,
        finalAmount,
        payment_method || 'manual',
      ]
    );

    const [rows] = await db.query(
      `SELECT * FROM payments WHERE id = ? LIMIT 1`,
      [result.insertId]
    );

    res.status(201).json({
      id: Number(rows[0].id),
      job_id: Number(rows[0].job_id),
      worker_user_id: Number(rows[0].worker_user_id),
      amount: Number(rows[0].amount || 0),
      status: rows[0].status ?? 'paid',
      payment_method: rows[0].payment_method ?? 'manual',
      paid_at: rows[0].paid_at,
    });
  } catch (error) {
    console.error('POST /jobs/:id/pay error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/jobs/:id/status-updates', async (req, res) => {
  try {
    const jobId = req.params.id;

    const [rows] = await db.query(
      `
      SELECT
        jsu.id,
        jsu.job_id,
        jsu.worker_user_id,
        jsu.update_type,
        jsu.message,
        jsu.created_at,
        u.full_name AS worker_name,
        u.profile_image_url AS worker_img
      FROM job_status_updates jsu
      INNER JOIN users u ON u.id = jsu.worker_user_id
      WHERE jsu.job_id = ?
      ORDER BY jsu.created_at ASC, jsu.id ASC
      `,
      [jobId]
    );

    res.json(
      rows.map((r) => ({
        id: Number(r.id),
        job_id: Number(r.job_id),
        worker_user_id: Number(r.worker_user_id),
        update_type: r.update_type ?? 'note',
        message: r.message ?? '',
        created_at: r.created_at,
        worker_name: r.worker_name ?? '',
        worker_img: r.worker_img ?? '',
      }))
    );
  } catch (error) {
    console.error('GET /jobs/:id/status-updates error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.post('/jobs/:id/status-updates', async (req, res) => {
  try {
    const jobId = req.params.id;
    const { worker_user_id, update_type, message } = req.body;

    const [jobRows] = await db.query(
      `SELECT * FROM jobs WHERE id = ? LIMIT 1`,
      [jobId]
    );

    if (!jobRows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    const normalizedType = update_type || 'note';
    const normalizedMessage = (message || '').trim();

    if (!normalizedMessage) {
      return res.status(400).json({ message: 'กรุณาระบุข้อความอัปเดต' });
    }

    await db.query(
      `
      INSERT INTO job_status_updates (
        job_id,
        worker_user_id,
        update_type,
        message
      ) VALUES (?, ?, ?, ?)
      `,
      [jobId, worker_user_id, normalizedType, normalizedMessage]
    );

    await db.query(
      `
      UPDATE jobs
      SET status = 'in_progress'
      WHERE id = ?
      `,
      [jobId]
    );

    res.json({ message: 'อัปเดตสถานะงานสำเร็จ' });
  } catch (error) {
    console.error('POST /jobs/:id/status-updates error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.post('/jobs/:id/complete', async (req, res) => {
  try {
    const jobId = req.params.id;
    const { worker_user_id } = req.body;

    const [jobRows] = await db.query(
      `SELECT * FROM jobs WHERE id = ? LIMIT 1`,
      [jobId]
    );

    if (!jobRows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    await db.query(
      `
      UPDATE jobs
      SET status = 'waiting_review'
      WHERE id = ?
      `,
      [jobId]
    );

    await db.query(
      `
      INSERT INTO job_status_updates (
        job_id,
        worker_user_id,
        update_type,
        message
      ) VALUES (?, ?, 'waiting_review', ?)
      `,
      [jobId, worker_user_id, 'งานเสร็จแล้ว รอลูกค้ายืนยัน']
    );

    res.json({ message: 'เปลี่ยนสถานะเป็น waiting_review แล้ว' });
  } catch (error) {
    console.error('POST /jobs/:id/complete error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.post('/jobs/:id/customer-confirm', async (req, res) => {
  try {
    const jobId = req.params.id;

    const [jobRows] = await db.query(
      `SELECT * FROM jobs WHERE id = ? LIMIT 1`,
      [jobId]
    );

    if (!jobRows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    const job = jobRows[0];

    await db.query(
      `
      UPDATE jobs
      SET status = 'completed',
          customer_confirmed_at = NOW()
      WHERE id = ?
      `,
      [jobId]
    );

    if (job.assigned_worker_id) {
      await db.query(
        `
        INSERT INTO job_status_updates (
          job_id,
          worker_user_id,
          update_type,
          message
        ) VALUES (?, ?, 'completed', ?)
        `,
        [jobId, job.assigned_worker_id, 'ลูกค้ายืนยันงานแล้ว']
      );
    }

    res.json({ message: 'ลูกค้ายืนยันงานแล้ว' });
  } catch (error) {
    console.error('POST /jobs/:id/customer-confirm error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/workers/:workerUserId/reviews', async (req, res) => {
  try {
    const workerUserId = req.params.workerUserId;

    const [rows] = await db.query(
      `
      SELECT
        wr.id,
        wr.job_id,
        wr.worker_user_id,
        wr.reviewer_user_id,
        wr.rating,
        wr.review_text,
        wr.image_url,
        wr.tip_amount,
        wr.created_at,
        j.title AS job_title,
        u.full_name AS reviewer_name,
        u.profile_image_url AS reviewer_img
      FROM worker_reviews wr
      INNER JOIN jobs j ON j.id = wr.job_id
      INNER JOIN users u ON u.id = wr.reviewer_user_id
      WHERE wr.worker_user_id = ?
      ORDER BY wr.created_at DESC, wr.id DESC
      `,
      [workerUserId]
    );

    const [summaryRows] = await db.query(
      `
      SELECT
        COUNT(*) AS review_count,
        COALESCE(AVG(rating), 0) AS rating_avg
      FROM worker_reviews
      WHERE worker_user_id = ?
      `,
      [workerUserId]
    );

    res.json({
      summary: {
        worker_user_id: Number(workerUserId),
        rating_avg: Number(summaryRows[0]?.rating_avg || 0),
        review_count: Number(summaryRows[0]?.review_count || 0),
      },
      reviews: rows.map((r) => ({
        id: Number(r.id),
        job_id: Number(r.job_id),
        worker_user_id: Number(r.worker_user_id),
        reviewer_user_id: Number(r.reviewer_user_id),
        rating: Number(r.rating || 0),
        review_text: r.review_text ?? '',
        image_url: r.image_url ?? '',
        tip_amount: Number(r.tip_amount || 0),
        created_at: r.created_at,
        job_title: r.job_title ?? '',
        reviewer_name: r.reviewer_name ?? '',
        reviewer_img: r.reviewer_img ?? '',
      })),
    });
  } catch (error) {
    console.error('GET /workers/:workerUserId/reviews error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.post('/jobs/:id/review', async (req, res) => {
  try {
    const jobId = req.params.id;
    const {
      worker_user_id,
      reviewer_user_id,
      rating,
      review_text,
      image_url,
      tip_amount,
    } = req.body;

    const [jobRows] = await db.query(
      `SELECT * FROM jobs WHERE id = ? LIMIT 1`,
      [jobId]
    );

    if (!jobRows.length) {
      return res.status(404).json({ message: 'ไม่พบงาน' });
    }

    const [existingRows] = await db.query(
      `
      SELECT id
      FROM worker_reviews
      WHERE job_id = ? AND reviewer_user_id = ?
      LIMIT 1
      `,
      [jobId, reviewer_user_id]
    );

    if (existingRows.length) {
      return res.status(400).json({ message: 'งานนี้ถูกรีวิวแล้ว' });
    }

    const finalRating = Number(rating || 0);
    if (finalRating < 1 || finalRating > 5) {
      return res.status(400).json({ message: 'คะแนนต้องอยู่ระหว่าง 1 ถึง 5' });
    }

    const finalTip = Number(tip_amount || 0);

    const [result] = await db.query(
      `
      INSERT INTO worker_reviews (
        job_id,
        worker_user_id,
        reviewer_user_id,
        rating,
        review_text,
        image_url,
        tip_amount
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      `,
      [
        jobId,
        worker_user_id,
        reviewer_user_id,
        finalRating,
        review_text || '',
        image_url || '',
        finalTip,
      ]
    );

    const [avgRows] = await db.query(
      `
      SELECT
        COUNT(*) AS review_count,
        COALESCE(AVG(rating), 0) AS rating_avg
      FROM worker_reviews
      WHERE worker_user_id = ?
      `,
      [worker_user_id]
    );

    await db.query(
      `
      UPDATE users
      SET rating_avg = ?, rating_count = ?
      WHERE id = ?
      `,
      [
        Number(avgRows[0].rating_avg || 0),
        Number(avgRows[0].review_count || 0),
        worker_user_id,
      ]
    );

    await db.query(
      `
      UPDATE jobs
      SET status = 'closed'
      WHERE id = ?
      `,
      [jobId]
    );

    const [rows] = await db.query(
      `
      SELECT *
      FROM worker_reviews
      WHERE id = ?
      LIMIT 1
      `,
      [result.insertId]
    );

    res.status(201).json({
      id: Number(rows[0].id),
      job_id: Number(rows[0].job_id),
      worker_user_id: Number(rows[0].worker_user_id),
      reviewer_user_id: Number(rows[0].reviewer_user_id),
      rating: Number(rows[0].rating || 0),
      review_text: rows[0].review_text ?? '',
      image_url: rows[0].image_url ?? '',
      tip_amount: Number(rows[0].tip_amount || 0),
      created_at: rows[0].created_at,
      rating_avg: Number(avgRows[0].rating_avg || 0),
      rating_count: Number(avgRows[0].review_count || 0),
    });
  } catch (error) {
    console.error('POST /jobs/:id/review error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/workers/:workerUserId/profile', async (req, res) => {
  try {
    const workerUserId = req.params.workerUserId;

    const [rows] = await db.query(
      `
      SELECT
        id,
        full_name,
        email,
        phone,
        profile_image_url,
        job_title,
        bio,
        skills,
        rating_avg,
        rating_count
      FROM users
      WHERE id = ?
      LIMIT 1
      `,
      [workerUserId]
    );

    if (!rows.length) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลช่าง' });
    }

    const worker = rows[0];

    res.json({
      id: Number(worker.id),
      name: worker.full_name ?? '',
      email: worker.email ?? '',
      phone: worker.phone ?? '',
      img: worker.profile_image_url ?? '',
      job_title: worker.job_title ?? '',
      desc: worker.bio ?? '',
      skills: worker.skills ?? '',
      rating_avg: Number(worker.rating_avg || 0),
      rating_count: Number(worker.rating_count || 0),
    });
  } catch (error) {
    console.error('GET /workers/:workerUserId/profile error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;