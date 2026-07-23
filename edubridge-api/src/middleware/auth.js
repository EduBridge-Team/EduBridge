// ميدل وير للتحقق من التوكن — يحمي المسارات المحمية
const jwt = require("jsonwebtoken");

function auth(req, res, next) {
  const header = req.headers["authorization"];
  // الشكل المتوقع: "Bearer <token>"
  const token = header && header.split(" ")[1];

  if (!token) {
    return res.status(401).json({ error: "التوكن مفقود" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, role }
    next();
  } catch (err) {
    return res.status(403).json({ error: "توكن غير صالح" });
  }
}

// ميدل وير اختياري: يسمح فقط لأدوار معيّنة
function allowRoles(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: "لا تملك صلاحية لهذا الإجراء" });
    }
    next();
  };
}

module.exports = { auth, allowRoles };
