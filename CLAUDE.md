# تعليمات لـ Claude Code — مشروع EduBridge

هذا الملف يشرح المشروع الحالي وكيف تُكمله وتشغّله. اقرأه بالكامل قبل البدء.

---

## نظرة عامة

**EduBridge** جسر تعليمي لأطفال ذوي الاحتياجات الخاصة — مشروع تدريب ميداني جامعي.
يتكوّن من:
- **Backend** (Node.js + Express + PostgreSQL) في `edubridge-api/`
- **تطبيق موبايل** (Flutter) في `edubridge-app/`
- **قاعدة بيانات** (سكربتات SQL في جذر المجلد)

اللغة العربية هي لغة الواجهة، والاتجاه من اليمين لليسار (RTL).

---

## هيكل المجلد

```
EduBridge/
├── edubridge_erd.mermaid      # مخطّط قاعدة البيانات
├── edubridge_schema.sql       # إنشاء الجداول
├── edubridge_seed.sql         # بيانات تجريبية (باسورد الكل: password123)
├── edubridge-api/             # الـ Backend
│   ├── .env.example
│   ├── package.json
│   └── src/
│       ├── app.js             # نقطة التشغيل + ربط المسارات
│       ├── db.js              # اتصال PostgreSQL (pool)
│       ├── middleware/auth.js # التحقق من التوكن + الصلاحيات (allowRoles)
│       └── routes/
│           ├── auth.js        # register / login
│           ├── children.js    # الأطفال + دروس الطفل حسب إعاقته
│           ├── lessons.js     # الدروس + فلترة حسب نوع الإعاقة
│           └── progress.js    # التقدّم (upsert + ملخّص)
└── edubridge-app/             # تطبيق Flutter
    ├── pubspec.yaml
    └── lib/
        ├── config.dart        # عنوان الـ API
        ├── main.dart          # الثيم + RTL + شاشة البداية حسب التوكن
        ├── services/api_service.dart
        └── screens/           # login / home / children / child_lessons
```

---

## خطوات التشغيل (نفّذها بالترتيب)

### 1) قاعدة البيانات
- تأكّد أن PostgreSQL مثبّت ويعمل.
- أنشئ قاعدة بيانات باسم `edubridge`.
- نفّذ `edubridge_schema.sql` ثم `edubridge_seed.sql` عليها.

### 2) الـ Backend
```bash
cd edubridge-api
npm install
cp .env.example .env
# عدّل .env: بيانات قاعدة البيانات + JWT_SECRET عشوائي طويل
npm run dev
```
تحقّق: افتح `http://localhost:3000` — يجب أن يرد برسالة نجاح.

### 3) تطبيق Flutter
```bash
cd edubridge-app
flutter pub get
flutter run
```
**مهم — عنوان الـ API في `lib/config.dart`:**
- محاكي أندرويد → `http://10.0.2.2:3000/api`
- جهاز حقيقي → `http://<IP-جهازك>:3000/api`

---

## حسابات تجريبية (بعد الـ seed)
الباسورد للجميع: `password123`
- معلّم: `teacher@edu.com`
- مختص: `specialist@edu.com`
- ولي أمر: `parent@edu.com`
- أدمن: `admin@edu.com`

اختبار الصلاحيات: دخول المعلّم يُظهر كل الأطفال؛ دخول ولي الأمر يُظهر أطفاله فقط.

---

## قواعد يجب الالتزام بها عند إكمال المشروع

1. **الصلاحيات:** أي مسار حسّاس يمرّ عبر `auth` و`allowRoles(...)`. ولي الأمر لا يضيف/يعدّل، فقط يعرض.
2. **الأمان:** الباسورد يُخزّن كـ hash (bcrypt) فقط. رسالة دخول خاطئ موحّدة (لا تكشف إن كان الإيميل أو الباسورد الخطأ).
3. **RTL:** كل الشاشات تحترم الاتجاه من اليمين لليسار (مطبّق في `main.dart`).
4. **إمكانية الوصول (accessibility):** أزرار كبيرة (ارتفاع ≥ 56)، خطوط واضحة، تباين لون جيد، أيقونات معبّرة. هذا جوهر المشروع لأنه لأطفال ذوي احتياجات خاصة.
5. **معالجة الحالات:** كل شاشة تتعامل مع: تحميل / خطأ اتصال / قائمة فارغة.
6. **التعليقات بالعربية** لتتوافق مع باقي الكود.
7. اللون الأساسي للتطبيق: `Color(0xFF2E7D6B)`.

---

## ما تبقّى (نفّذه بهذا الترتيب المقترح)

1. **شاشة تقدّم الطفل** (Flutter): تستهلك:
   - `GET /api/progress/child/:childId/summary` → ملخّص (done / in_progress / not_started + متوسّط النتيجة)
   - `GET /api/progress/child/:childId` → تفاصيل التقدّم
   أضف زر «التقدّم» في شاشة دروس الطفل أو الرئيسية.

2. **تسجيل إتمام درس:** في `child_lessons_screen.dart` أضف زر «تمّ» يستدعي `POST /api/progress`.

3. **شاشة إنشاء حساب (register)** تربط بـ `ApiService.register`.

4. **دعم Text-to-Speech** للدروس (مكتبة `flutter_tts`) — لقراءة محتوى الدرس صوتياً للأطفال.

5. **مسارات إضافية بالـ Backend عند الحاجة:** الوسائط (media)، الجلسات (sessions)، الملاحظات (notes)، الإشعارات (notifications) — الجداول جاهزة في المخطّط.

6. **واجهة ويب (React)** إن تطلّب المشروع نسخة ويب — تستهلك نفس الـ API.

---

## مرجع سريع للمسارات الجاهزة

```
POST /api/auth/register
POST /api/auth/login
GET  /api/me

POST /api/children                    (teacher/specialist/admin)
GET  /api/children                    (parent: أطفاله فقط)
GET  /api/children/:id
POST /api/children/:id/parents
GET  /api/children/:id/lessons        (مفلترة حسب إعاقة الطفل)

POST /api/lessons                     (teacher/admin)
GET  /api/lessons?disability_type_id=
GET  /api/lessons/:id

POST /api/progress                    (upsert)
GET  /api/progress/child/:childId
GET  /api/progress/child/:childId/summary
```

جميع المسارات ما عدا `register`/`login` تتطلّب هيدر:
`Authorization: Bearer <token>`
