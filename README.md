# EduBridge — جسر تعليمي لأطفال ذوي الاحتياجات الخاصة

مشروع تدريب ميداني — موبايل وويب وواجهتان خلفيتان (Node وLaravel) على نفس قاعدة البيانات ونفس عقد الـ API.

## محتوى المجلد

| الملف / المجلد | الوصف |
|----------------|-------|
| `edubridge_erd.mermaid` | مخطّط قاعدة البيانات (العلاقات بين الجداول) |
| `edubridge_schema.sql`  | سكربت إنشاء الجداول (PostgreSQL) |
| `edubridge_seed.sql`    | بيانات تجريبية |
| `edubridge-api/`        | الواجهة الخلفية الأصلية (Node.js + Express) |
| `edubridge-api-laravel/`| الواجهة الخلفية بـ Laravel — **نفس عقد الـ API** |
| `edubridge-app/`        | تطبيق الموبايل (Flutter — عربي RTL) |
| `edubridge-web/`        | واجهة الويب (React + Vite) |
| `branding/`             | ملفات الهوية (الشعار والأيقونات) |

## التقنيات

- **Backend:** Laravel 12 (PHP) — أو النسخة الأصلية Node.js + Express
- **الموبايل:** Flutter (مع قراءة صوتية flutter_tts)
- **الويب:** React + Vite + React Router
- **قاعدة البيانات:** PostgreSQL
- **المصادقة:** JWT + bcrypt (نفس التوكن في النسختين)

## خطوات التشغيل

### 1) قاعدة البيانات
أنشئ قاعدة باسم `edubridge` ونفّذ عليها `edubridge_schema.sql` ثم `edubridge_seed.sql`.

### 2) الـ Backend — نسخة Laravel (المعتمدة)
```bash
cd edubridge-api-laravel
composer install
cp .env.example .env
php artisan key:generate
# عدّل .env: بيانات PostgreSQL + أضف JWT_SECRET=نص عشوائي طويل
php artisan serve --host=0.0.0.0 --port=3000
```

<details>
<summary>بديل: النسخة الأصلية (Node.js)</summary>

```bash
cd edubridge-api
npm install
cp .env.example .env   # عدّل القيم
npm run dev
```
</details>

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

POST /api/children             (teacher/specialist/admin)
GET  /api/children             (ولي الأمر: أطفاله فقط)
GET  /api/children/:id
POST /api/children/:id/parents (teacher/specialist/admin)
GET  /api/children/:id/lessons (مفلترة حسب إعاقة الطفل)

POST /api/lessons              (teacher/admin)
GET  /api/lessons?disability_type_id=
GET  /api/lessons/:id

POST /api/progress             (upsert — teacher/specialist/admin)
GET  /api/progress/child/:childId
GET  /api/progress/child/:childId/summary
```

كل المسارات ما عدا `register`/`login` تتطلب هيدر `Authorization: Bearer <token>`.

## بيانات تجريبية

باسورد كل الحسابات: `password123`

- معلّم: teacher@edu.com
- مختص: specialist@edu.com
- ولي أمر: parent@edu.com
- أدمن: admin@edu.com

## الحالة

- [x] مسارات الأطفال والدروس والتقدّم (Node + Laravel)
- [x] تطبيق الموبايل: دخول/تسجيل، الأطفال، الدروس مع قراءة صوتية، زر «تمّ»، شاشة التقدّم، أيقونة وشاشة بداية بهوية «جسر»
- [x] واجهة الويب: نفس الشاشات + شريط علوي وبحث في الدروس وصفحة من نحن
- [ ] الإضافات الاختيارية: الوسائط، الجلسات، الملاحظات، الإشعارات
