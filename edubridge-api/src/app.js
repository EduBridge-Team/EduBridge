// نقطة تشغيل السيرفر
const express = require("express");
const cors = require("cors");
require("dotenv").config();

const authRoutes = require("./routes/auth");
const childrenRoutes = require("./routes/children");
const lessonsRoutes = require("./routes/lessons");
const progressRoutes = require("./routes/progress");
const { auth } = require("./middleware/auth");

const app = express();

app.use(cors());
app.use(express.json()); // لقراءة JSON من جسم الطلب

// مسار فحص إن السيرفر شغّال
app.get("/", (req, res) => {
  res.json({ message: "EduBridge API شغّال ✅" });
});

// المسارات
app.use("/api/auth", authRoutes);
app.use("/api/children", childrenRoutes);
app.use("/api/lessons", lessonsRoutes);
app.use("/api/progress", progressRoutes);

// مثال على مسار محمي — لازم توكن صالح
app.get("/api/me", auth, (req, res) => {
  res.json({ user: req.user });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`السيرفر يعمل على المنفذ ${PORT}`);
});
