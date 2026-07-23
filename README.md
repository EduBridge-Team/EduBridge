# EduBridge — جسر تعليمي لأطفال ذوي الاحتياجات الخاصة

مشروع تدريب ميداني — ويب وموبايل.

## محتوى المجلد

| الملف | الوصف |
|-------|-------|
| `edubridge_erd.mermaid` | مخطّط قاعدة البيانات (العلاقات بين الجداول) |
| `edubridge_schema.sql`  | سكربت إنشاء الجداول (PostgreSQL) |
| `edubridge-api/`        | الواجهة الخلفية (Node.js + Express) |

## التقنيات

- **Backend:** Node.js + Express
- **قاعدة البيانات:** PostgreSQL
- **المصادقة:** JWT + bcrypt

## خطوات التشغيل

1. أنشئ قاعدة بيانات باسم `edubridge` ونفّذ عليها `edubridge_schema.sql`.
2. ادخل مجلد الـAPI:
   ```
   cd edubridge-api
   npm install
   ```
3. انسخ `.env.example` باسم `.env` وعبّي القيم.
4. شغّل السيرفر:
   ```
   npm run dev
   ```

## المسارات الجاهزة حتى الآن

- `POST /api/auth/register` — إنشاء حساب
- `POST /api/auth/login` — تسجيل دخول (يرجّع token)
- `GET  /api/me` — بيانات المستخدم الحالي (محمي بتوكن)

## بيانات تجريبية

شغّل `edubridge_seed.sql` بعد إنشاء الجداول. باسورد كل الحسابات: `password123`

- معلّم: teacher@edu.com
- مختص: specialist@edu.com
- ولي أمر: parent@edu.com
- أدمن: admin@edu.com

## قيد الإنجاز

- [x] مسارات الأطفال (children)
- [x] مسارات الدروس (lessons) وفلترتها حسب نوع الإعاقة
- [x] مسارات التقدّم (progress)
- [ ] واجهة الويب والموبايل
