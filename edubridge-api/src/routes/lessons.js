// مسارات الدروس
const express = require("express");
const db = require("../db");
const { auth, allowRoles } = require("../middleware/auth");

const router = express.Router();

router.use(auth);

// إضافة درس (معلّم / أدمن)
// POST /api/lessons
router.post("/", allowRoles("teacher", "admin"), async (req, res) => {
  const { title, content, disability_type_id } = req.body;

  if (!title) {
    return res.status(400).json({ error: "عنوان الدرس مطلوب" });
  }

  try {
    const result = await db.query(
      `INSERT INTO lessons (title, content, disability_type_id, teacher_id)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [title, content || null, disability_type_id || null, req.user.id]
    );
    res.status(201).json({ lesson: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

// عرض الدروس، مع فلترة اختيارية حسب نوع الإعاقة
// GET /api/lessons
// GET /api/lessons?disability_type_id=2
router.get("/", async (req, res) => {
  const { disability_type_id } = req.query;

  try {
    let result;
    if (disability_type_id) {
      result = await db.query(
        `SELECT * FROM lessons
         WHERE disability_type_id = $1
         ORDER BY created_at DESC`,
        [disability_type_id]
      );
    } else {
      result = await db.query("SELECT * FROM lessons ORDER BY created_at DESC");
    }
    res.json({ lessons: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

// عرض درس واحد مع وسائطه
// GET /api/lessons/:id
router.get("/:id", async (req, res) => {
  try {
    const lesson = await db.query("SELECT * FROM lessons WHERE id = $1", [req.params.id]);
    if (lesson.rows.length === 0) {
      return res.status(404).json({ error: "الدرس غير موجود" });
    }

    const media = await db.query(
      "SELECT id, type, url FROM media WHERE lesson_id = $1",
      [req.params.id]
    );

    res.json({ lesson: lesson.rows[0], media: media.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

module.exports = router;
