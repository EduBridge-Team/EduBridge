# تعليمات لـ Claude Code — مشروع EduBridge

هذا الملف يشرح المشروع الحالي وكيف تُكمله وتشغّله. اقرأه بالكامل قبل البدء.

---

## نظرة عامة

**EduBridge (جسر تعليمي)** جسر تعليمي لأطفال ذوي الاحتياجات الخاصة — مشروع تدريب ميداني جامعي.
يتكوّن من:
- **Backend** — Laravel 12 في `edubridge-api-laravel/`
- **تطبيق موبايل** (Flutter) في `edubridge-app/`
- **واجهة ويب** (React + Vite) في `edubridge-web/`
- **قاعدة بيانات** (سكربتات SQL في جذر المجلد)

اللغة العربية هي لغة الواجهة، والاتجاه من اليمين لليسار (RTL).

---

## هيكل المجلد

```
EduBridge/
├── edubridge_erd.mermaid        # مخطّط قاعدة البيانات
├── edubridge_schema.sql         # إنشاء الجداول
├── edubridge_seed.sql           # بيانات تجريبية (باسورد الكل: password123)
├── branding/                    # الهوية: الشعار والأيقونة الأصلية
├── .pgdata/ + .pgtool/          # PostgreSQL محمول محلي (غير مرفوع للمستودع)
├── edubridge-api-laravel/       # الـ Backend (Laravel)
│   ├── routes/api.php           # كل المسارات
│   ├── app/Http/Controllers/    # Auth / Child / Lesson / Progress
│   └── app/Http/Middleware/     # JwtAuth (توكن) + RoleMiddleware (أدوار)
├── edubridge-app/               # تطبيق Flutter
│   └── lib/
│       ├── config.dart          # عنوان الـ API
│       ├── main.dart            # الثيم + RTL + شاشة البداية حسب التوكن
│       ├── services/api_service.dart
│       └── screens/             # login / register / home / children /
│                                # child_lessons (تمّ + استمع) / child_progress
└── edubridge-web/               # واجهة React
    └── src/
        ├── api.js               # طبقة الاتصال (توكن في localStorage)
        ├── components/TopBar.jsx
        └── pages/               # Login / Register / Children / ChildLessons /
                                 # ChildProgress / Lessons / About
```

---

## خطوات التشغيل (نفّذها بالترتيب)

### 1) قاعدة البيانات
- **إن كان PostgreSQL مثبّتاً:** أنشئ قاعدة `edubridge` ونفّذ `edubridge_schema.sql` ثم `edubridge_seed.sql`.
- **النسخة المحمولة داخل المشروع** (لا تحتاج تثبيتاً ولا صلاحيات مدير):
  ```powershell
  .pgtool\bin\pg_ctl.exe -D .pgdata -o "-p 5432" start
  ```
  المستخدم `postgres` بمصادقة trust (بدون كلمة مرور فعلية)، والقاعدة `edubridge` جاهزة بالسكيما والبيانات.

### 2) الـ Backend (Laravel)
```bash
cd edubridge-api-laravel
composer install          # إن لم يكن vendor موجوداً
# .env جاهز محلياً؛ عند إعداد جديد: انسخ .env.example وأضف بيانات القاعدة و JWT_SECRET
php artisan serve --host=0.0.0.0 --port=3000
```
تحقّق: `http://localhost:3000` يرد برسالة نجاح.
> Composer محلياً: `php C:\Users\moham\toolchain\composer\composer.phar`

### 3) واجهة الويب
```bash
cd edubridge-web
npm run dev               # → http://localhost:5173 (يستمع على الشبكة أيضاً)
```
عنوان الـ API فيها ديناميكي (`window.location.hostname`) — تعمل من أي جهاز على الشبكة.

### 4) تطبيق Flutter
```bash
cd edubridge-app
flutter pub get
flutter run
```
**عنوان الـ API في `lib/config.dart`:**
- جهاز حقيقي عبر USB → `adb reverse tcp:3000 tcp:3000` + `http://127.0.0.1:3000/api` (الحالي)
- محاكي أندرويد → `http://10.0.2.2:3000/api`
- جهاز عبر الشبكة → `http://<IP-جهازك>:3000/api`

---

## حسابات تجريبية (بعد الـ seed)
الباسورد للجميع: `password123`
- معلّم: `teacher@edu.com`
- مختص: `specialist@edu.com`
- ولي أمر: `parent@edu.com`
- أدمن: `admin@edu.com`

اختبار الصلاحيات: دخول المعلّم يُظهر كل الأطفال؛ دخول ولي الأمر يُظهر أطفاله فقط.

---

## قواعد يجب الالتزام بها

1. **الصلاحيات:** أي مسار حسّاس يمرّ عبر `auth.jwt` و`role:...` (في Laravel) — ولي الأمر لا يضيف/يعدّل، فقط يعرض. الواجهات تخفي أزرار التعديل عنه أيضاً.
2. **الأمان:** الباسورد hash بـ bcrypt فقط. رسالة دخول خاطئ موحّدة. ملفات `.env` لا تُرفع للمستودع أبداً.
3. **RTL:** كل الشاشات تحترم الاتجاه من اليمين لليسار.
4. **إمكانية الوصول:** أزرار كبيرة (ارتفاع ≥ 56)، خطوط واضحة، تباين جيد، أيقونات معبّرة، وقراءة صوتية للدروس.
5. **معالجة الحالات:** كل شاشة تتعامل مع: تحميل / خطأ اتصال / قائمة فارغة.
6. **التعليقات بالعربية.**
7. اللون الأساسي: `Color(0xFF2E7D6B)` — وهوية «جسر» (تركوازي `#2FB9BE`) للشعار والأيقونة.
8. **Git:** لا تضف تريلر `Co-Authored-By` في رسائل الـ commit.
9. **تطابق العقد:** أي تعديل على مسارات Laravel يجب أن يحافظ على نفس أشكال الاستجابات الموثقة `{children: [...]}` / `{error: "..."}` لأن التطبيق والويب يعتمدان عليها.

---

## ما اكتمل

- كل مسارات الـ API (auth / children / lessons / progress) في Laravel — مختبرة بالكامل.
- تطبيق Flutter: دخول، تسجيل حساب، الأطفال، دروس الطفل مع «تمّ» و«استمع» (flutter_tts)، شاشة التقدّم، أيقونة «جسر» الأصلية وشاشة بداية، اختبار تكامل للدخول على جهاز حقيقي.
- واجهة React: نفس الشاشات + شريط علوي (بحث في الدروس، من نحن) بهوية جسر.
- المستودع: https://github.com/MohammedEmad333/EduBridge (خاص، فرع main).

## ما تبقّى (اختياري حسب متطلبات التدريب)

1. **مسارات إضافية:** الوسائط (media)، الجلسات (sessions)، الملاحظات (notes)، الإشعارات (notifications) — الجداول جاهزة في المخطّط.
2. **شاشات إدارة:** إضافة طفل/درس من الواجهات (المسارات جاهزة في الـ API).
3. **نشر:** استضافة الـ API والويب على خادم حقيقي.

---

## مرجع سريع للمسارات

```
POST /api/auth/register
POST /api/auth/login
GET  /api/me

POST /api/children                    (teacher/specialist/admin)
GET  /api/children                    (parent: أطفاله فقط)
GET  /api/children/:id
POST /api/children/:id/parents        (teacher/specialist/admin)
GET  /api/children/:id/lessons        (مفلترة حسب إعاقة الطفل)

POST /api/lessons                     (teacher/admin)
GET  /api/lessons?disability_type_id=
GET  /api/lessons/:id

POST /api/progress                    (upsert — teacher/specialist/admin)
GET  /api/progress/child/:childId
GET  /api/progress/child/:childId/summary
```

جميع المسارات ما عدا `register`/`login` تتطلّب هيدر:
`Authorization: Bearer <token>`
