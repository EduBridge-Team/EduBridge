// مسارات المصادقة: إنشاء حساب + تسجيل دخول
const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const db = require("../db");

const router = express.Router();

// إنشاء حساب جديد
// POST /api/auth/register
router.post("/register", async (req, res) => {
  const { name, email, password, role, phone } = req.body;

  // تحقق أساسي من المدخلات
  if (!name || !email || !password || !role) {
    return res.status(400).json({ error: "الاسم والإيميل والباسورد والدور مطلوبة" });
  }
  const validRoles = ["parent", "teacher", "specialist", "admin"];
  if (!validRoles.includes(role)) {
    return res.status(400).json({ error: "الدور غير صالح" });
  }

  try {
    // تشفير الباسورد قبل التخزين
    const password_hash = await bcrypt.hash(password, 10);

    const result = await db.query(
      `INSERT INTO users (name, email, password_hash, role, phone)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, name, email, role, phone, created_at`,
      [name, email, password_hash, role, phone || null]
    );

    res.status(201).json({ user: result.rows[0] });
  } catch (err) {
    // 23505 = تكرار قيمة فريدة (الإيميل موجود مسبقاً)
    if (err.code === "23505") {
      return res.status(409).json({ error: "الإيميل مستخدم مسبقاً" });
    }
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

// تسجيل الدخول
// POST /api/auth/login
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "الإيميل والباسورد مطلوبان" });
  }

  try {
    const result = await db.query(
      "SELECT * FROM users WHERE email = $1",
      [email]
    );
    const user = result.rows[0];

    // نفس الرسالة سواء الإيميل غلط أو الباسورد غلط (أأمن)
    if (!user) {
      return res.status(401).json({ error: "بيانات الدخول غير صحيحة" });
    }

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ error: "بيانات الدخول غير صحيحة" });
    }

    // إنشاء التوكن
    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "خطأ في السيرفر" });
  }
});

module.exports = router;
