// مسارات التقدّم
const express = require("express");
const db = require("../db");
const { auth, allowRoles } = require("../middleware/auth");

const router = express.Router();

router.use(auth);

// تسجيل/تحديث تقدّم الطفل بدرس (ولي الأمر يعرض فقط — لا يعدّل)
// POST /api/progress   body: { child_id, lesson_id, status, score }
router.post("/", allowRoles("teacher", "specialist", "admin"), async (req, res) => {
  const { child_id, lesson_id, status, score } = req.body;

  if (!child_id || !lesson_id) {
    return res.status(400).json({ error: "child_id و lesson_id مطلوبان" });
  }

  const validStatus = ["not_started", "in_progress", "done"];
  if (status && !validStatus.includes(status)) {
    return res.status(400).json({ error: "الحالة غير صالحة" });
  }

  // إذا خلّص الدرس، نسجّل وقت الإتمام تلقائياً
  const completed_at = status === "done" ? new Date() : null;

  try {
    // upsert: موجود -> تحديث، غير موجود -> إضافة
    const result = await db.query(
      `INSERT INTO progress (child_id, lesson_id, status, score, completed_at)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (child_id, lesson_id)
       DO UPDATE SET status = EXCLUDED.status,
                     score = EXCLUDED.score,
                     completed_at = EXCLUDED.completed_at
       RETURNING *`,
      [child_id, lesson_id, status || "in_progress", score ?? null, completed_at]
    );
    res.status(201).json({ progress: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

// عرض تقدّم طفل عبر كل الدروس (مع عنوان الدرس)
// GET /api/progress/child/:childId
router.get("/child/:childId", async (req, res) => {
  try {
    const result = await db.query(
      `SELECT p.id, p.status, p.score, p.completed_at,
              l.id AS lesson_id, l.title AS lesson_title
       FROM progress p
       JOIN lessons l ON l.id = p.lesson_id
       WHERE p.child_id = $1
       ORDER BY p.completed_at DESC NULLS LAST`,
      [req.params.childId]
    );
    res.json({ progress: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

// ملخّص تقدّم الطفل (عدد المكتمل / الجاري / المتبقّي + متوسّط النتيجة)
// GET /api/progress/child/:childId/summary
router.get("/child/:childId/summary", async (req, res) => {
  try {
    const result = await db.query(
      `SELECT
         COUNT(*) FILTER (WHERE status = 'done')        AS done,
         COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress,
         COUNT(*) FILTER (WHERE status = 'not_started') AS not_started,
         ROUND(AVG(score) FILTER (WHERE score IS NOT NULL))::int AS avg_score
       FROM progress
       WHERE child_id = $1`,
      [req.params.childId]
    );
    res.json({ summary: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

module.exports = router;
