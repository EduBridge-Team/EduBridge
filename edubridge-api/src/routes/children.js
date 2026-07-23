// مسارات الأطفال
const express = require("express");
const db = require("../db");
const { auth, allowRoles } = require("../middleware/auth");

const router = express.Router();

// كل المسارات هنا محمية بتوكن
router.use(auth);

// إضافة طفل (معلّم / مختص / أدمن)
// POST /api/children
router.post("/", allowRoles("teacher", "specialist", "admin"), async (req, res) => {
  const { name, birth_date, gender, disability_type_id, organization_id, notes } = req.body;

  if (!name) {
    return res.status(400).json({ error: "اسم الطفل مطلوب" });
  }

  try {
    const result = await db.query(
      `INSERT INTO children (name, birth_date, gender, disability_type_id, organization_id, notes)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [name, birth_date || null, gender || null, disability_type_id || null,
       organization_id || null, notes || null]
    );
    res.status(201).json({ child: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

// عرض الأطفال
// - ولي الأمر: يشوف أطفاله فقط
// - المعلّم/المختص/الأدمن: يشوفوا الكل
// GET /api/children
router.get("/", async (req, res) => {
  try {
    let result;
    if (req.user.role === "parent") {
      result = await db.query(
        `SELECT c.* FROM children c
         JOIN child_parent cp ON cp.child_id = c.id
         WHERE cp.parent_id = $1
         ORDER BY c.name`,
        [req.user.id]
      );
    } else {
      result = await db.query("SELECT * FROM children ORDER BY name");
    }
    res.json({ children: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

// عرض طفل واحد بالتفصيل (مع اسم نوع الإعاقة والمؤسسة)
// GET /api/children/:id
router.get("/:id", async (req, res) => {
  try {
    const result = await db.query(
      `SELECT c.*,
              dt.name AS disability_name,
              o.name  AS organization_name
       FROM children c
       LEFT JOIN disability_types dt ON dt.id = c.disability_type_id
       LEFT JOIN organizations o     ON o.id = c.organization_id
       WHERE c.id = $1`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "الطفل غير موجود" });
    }
    res.json({ child: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

// ربط طفل بولي أمر
// POST /api/children/:id/parents   body: { parent_id }
router.post("/:id/parents", allowRoles("teacher", "specialist", "admin"), async (req, res) => {
  const { parent_id } = req.body;
  if (!parent_id) {
    return res.status(400).json({ error: "parent_id مطلوب" });
  }

  try {
    await db.query(
      `INSERT INTO child_parent (child_id, parent_id)
       VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [req.params.id, parent_id]
    );
    res.status(201).json({ message: "تم الربط" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

// الدروس المناسبة لطفل معيّن (حسب نوع إعاقته) — جوهر الفكرة
// GET /api/children/:id/lessons
router.get("/:id/lessons", async (req, res) => {
  try {
    const result = await db.query(
      `SELECT l.* FROM lessons l
       JOIN children c ON c.disability_type_id = l.disability_type_id
       WHERE c.id = $1
       ORDER BY l.created_at DESC`,
      [req.params.id]
    );
    res.json({ lessons: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

module.exports = router;
