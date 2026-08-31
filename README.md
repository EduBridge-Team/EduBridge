# EduBridge — جسر تعليمي لأطفال ذوي الاحتياجات الخاصة

مشروع تدريب ميداني — تطبيق موبايل وواجهة ويب وواجهة خلفية بـ Laravel على قاعدة PostgreSQL.

## محتوى المجلد

| الملف / المجلد | الوصف |
|----------------|-------|
| `edubridge_erd.mermaid` | مخطّط قاعدة البيانات (العلاقات بين الجداول) |
| `edubridge_schema.sql`  | سكربت إنشاء الجداول (PostgreSQL) |
| `edubridge_seed.sql`    | بيانات تجريبية |
| `edubridge-api-laravel/`| الواجهة الخلفية (Laravel) |
| `edubridge-app/`        | تطبيق الموبايل (Flutter — عربي RTL) |
| `edubridge-web/`        | واجهة الويب (React + Vite) |
| `deploy/`               | حزمة النشر من الجوال (سكربت SSH + نسخة الموقع المبنية) |
| `دليل التحديث والنشر.docx` | دليل تحديث ونشر المشروع خطوة بخطوة |
| `branding/`             | ملفات الهوية (الشعار والأيقونات) |

## التقنيات

- **Backend:** Laravel 12 (PHP)
- **الموبايل:** Flutter (مع قراءة صوتية flutter_tts)
- **الويب:** React + Vite + React Router
- **قاعدة البيانات:** PostgreSQL
- **المصادقة:** JWT + bcrypt

## خطوات التشغيل

### 1) قاعدة البيانات
أنشئ قاعدة باسم `edubridge` ونفّذ عليها `edubridge_schema.sql` ثم `edubridge_seed.sql`.

### 2) الـ Backend (Laravel)
```bash
cd edubridge-api-laravel
composer install
cp .env.example .env
php artisan key:generate
# عدّل .env: بيانات PostgreSQL + أضف JWT_SECRET=نص عشوائي طويل
php artisan serve --host=0.0.0.0 --port=3000
```

تحقّق: افتح `http://localhost:3000` — يجب أن يرد برسالة نجاح.

### 3) واجهة الويب
```bash
cd edubridge-web
npm install
npm run dev            # → http://localhost:5173
```

### 4) تطبيق الموبايل
```bash
cd edubridge-app
flutter pub get
flutter run
```
عنوان الـ API في `lib/config.dart`:
- جهاز حقيقي عبر USB: `adb reverse tcp:3000 tcp:3000` مع `http://127.0.0.1:3000/api`
- محاكي أندرويد: `http://10.0.2.2:3000/api`

## المسارات الجاهزة

```
POST /api/auth/register        إنشاء حساب
POST /api/auth/login           تسجيل دخول (يرجّع token)
GET  /api/me                   حمولة التوكن (محمي)

POST /api/children             (parent/teacher/specialist/admin)
GET  /api/children             (ولي الأمر: أطفاله فقط)
GET  /api/children/:id
PUT  /api/children/:id         (تعديل بيانات الطفل)
POST /api/children/:id/parents (teacher/specialist/admin)
POST /api/children/:id/assign-teacher (teacher/specialist/admin)
GET  /api/children/:id/lessons (مفلترة حسب إعاقة الطفل)
GET  /api/children/:id/evaluations

POST /api/lessons              (teacher/admin)
GET  /api/lessons?disability_type_id=
GET  /api/lessons/:id

POST /api/progress             (upsert — teacher/specialist/admin)
GET  /api/progress/child/:childId
GET  /api/progress/child/:childId/summary

GET  /api/evaluations/child/:childId
POST /api/evaluations/child/:childId  (teacher/specialist/admin)

GET  /api/notifications
GET  /api/notifications/unread/count
PUT  /api/notifications/:id/read
PUT  /api/notifications/read-all
```

كل المسارات ما عدا `register`/`login` تتطلب هيدر `Authorization: Bearer <token>`.

## بيانات تجريبية

باسورد كل الحسابات: `password123`

- معلّم: teacher@edu.com
- مختص: specialist@edu.com
- ولي أمر: parent@edu.com
- أدمن: admin@edu.com

## النشر

الموقع منشور على: <https://edubridge.alwaysdata.net>

للتحديث من الجوال (عبر SSH/Termius) بأمر واحد بعد الدمج إلى `main`:

```bash
cd ~/EduBridge && git pull && bash deploy/deploy.sh
```

السكربت يرقّي قاعدة البيانات (`database/upgrade_parent_features.sql` — آمن وقابل للتكرار)،
ويمسح إعدادات Laravel، وينشر نسخة الموقع المبنية من `deploy/web`. التفاصيل في
`deploy/README.md` و`دليل التحديث والنشر.docx`.

## الحالة

- [x] مسارات الأطفال والدروس والتقدّم (Laravel)
- [x] لوحة ولي الأمر: إضافة/تعديل الأطفال، تفاصيل الطفل والتقييمات، الإشعارات (Laravel + الويب)
- [x] تطبيق الموبايل: دخول/تسجيل، الأطفال، الدروس مع قراءة صوتية، زر «تمّ»، شاشة التقدّم، لوحة ولي الأمر، أيقونة وشاشة بداية بهوية «جسر»
- [x] واجهة الويب: لوحات لكل دور (ولي أمر/معلّم/مختص/أدمن) + الإشعارات + شريط علوي وبحث في الدروس وصفحة من نحن
- [ ] الإضافات الاختيارية: الوسائط، الجلسات، الملاحظات
