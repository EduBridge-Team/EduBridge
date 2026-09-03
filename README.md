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

# ===== بطاقات لوحة EduBridge =====

POST /api/uploads                         رفع ملف (هوية/شهادة/قرابة) → { url }

# توثيق الهوية (البطاقات 1، 4، 9)
POST /api/me/identity                      إرسال رقم الهوية وصورتها للتوثيق
GET  /api/me/verification                  حالة توثيق المستخدم الحالي
GET  /api/verifications/users?status=       (admin) طلبات توثيق المستخدمين
PUT  /api/verifications/users/:id           (admin) اعتماد/رفض مستخدم
GET  /api/verifications/children?status=    (admin) توثيق بيانات الأطفال
PUT  /api/verifications/children/:id        (admin) اعتماد/رفض بيانات طفل

# الشهادات (البطاقة 9)
GET  /api/certificates                      شهاداتي (admin: الكل، ?status=/?user_id=)
POST /api/certificates                      (teacher/specialist) رفع شهادة
PUT  /api/certificates/:id                  (admin) اعتماد/رفض شهادة
DELETE /api/certificates/:id                حذف شهادة (صاحبها/admin)

# البحث برقم الهوية (البطاقة 2)
GET  /api/search/national-id?q=             (موظفون) بحث برقم الهوية

# مراجعة المناهج (البطاقة 3)
GET  /api/ministry/lessons?status=          (ministry/admin) دروس للمراجعة
PUT  /api/ministry/lessons/:id              (ministry/admin) اعتماد/رفض درس

# تقييمات الدروس (البطاقة 8)
GET  /api/lessons/:id/ratings              تقييمات درس + المتوسط
POST /api/lessons/:id/ratings              تقييم درس (نجوم 1..5 + تعليق)
DELETE /api/ratings/:id                    حذف تقييم (صاحبه/admin)

# الدعم الفني والشكاوى (البطاقة 11)
GET  /api/support                          تذاكري (admin: الكل)
POST /api/support                          إنشاء تذكرة/شكوى
PUT  /api/support/:id                       (admin) رد/تغيير الحالة
DELETE /api/users/:id                       (admin) حذف مستخدم

# دراسة الحالة مع المختصين (البطاقة 7)
GET  /api/consultations                     الاستشارات حسب الدور
POST /api/consultations                     طلب دراسة حالة
GET  /api/consultations/:id                 تفاصيل + ملاحظات المختص
PUT  /api/consultations/:id                 (specialist/admin) استلام/حالة
POST /api/consultations/:id/notes           (specialist/admin) إضافة توصية

# قائمة المستخدمين — أصبحت متاحة للمعلّم/المختص (المعلّمون فقط)
GET  /api/users                            (admin: الكل، teacher/specialist: المعلّمون)
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
- [x] بطاقات اللوحة (باك + فرونت): توثيق هوية الطالب وولي الأمر (1)، البحث برقم الهوية (2)، حساب الوزارة ومراجعة المناهج (3)، توثيق هوية الموظفين (4)، دراسة الحالة مع المختصين (7)، تقييمات الدروس (8)، إثبات ملكية المعلّم/المختص بالشهادات (9)، حساب المؤسسة (10)، الدعم الفني والشكاوى وحذف المستخدمين (11)، وإصلاح ظهور المعلّمين عند تعيين معلّم من حساب المختص (12)
- [ ] الإضافات الاختيارية: الوسائط، الجلسات، الملاحظات

> ملاحظة: بعد السحب على الخادم، شغّل `bash deploy/deploy.sh` لترقية قاعدة البيانات
> (`database/upgrade_board_cards.sql` — آمنة وقابلة للتكرار) قبل استخدام الميزات الجديدة.
