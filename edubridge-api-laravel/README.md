# EduBridge API

Laravel API for the EduBridge education and accessibility platform.

## Runtime

- PHP 8.4
- Laravel 13
- PostgreSQL
- JWT authentication
- Cloudflare R2 for production file storage
- Groq for the Noor educational assistant

Production is deployed on Oracle Cloud. The public API domain is:

```text
https://api.edubridge.win
```

## Local setup

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

For tests:

```bash
php artisan test
```

## Required production configuration

Authentication:

```env
JWT_SECRET=
GOOGLE_CLIENT_ID=
```

Noor assistant:

```env
GROQ_API_KEY=
GROQ_MODEL=openai/gpt-oss-20b
```

Cloudflare R2:

```env
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=auto
AWS_ENDPOINT=
AWS_USE_PATH_STYLE_ENDPOINT=true

R2_PRIVATE_BUCKET=edubridge-private
R2_MEDIA_BUCKET=edubridge-media
R2_MEDIA_PUBLIC_URL=https://media.edubridge.win
```

The private bucket must not be publicly accessible. Identity documents, certificates, and kinship documents are served only through authenticated API endpoints.

## Useful checks

```bash
php artisan about
php artisan route:list
php artisan test
php artisan edubridge:r2-check
```

After changing environment variables on production, clear Laravel configuration:

```bash
php artisan config:clear
```

## Sensitive upload migration

Dry run:

```bash
php artisan edubridge:migrate-sensitive-uploads
```

Apply:

```bash
php artisan edubridge:migrate-sensitive-uploads --apply
```

Delete legacy public copies only after confirming the migrated files are accessible:

```bash
php artisan edubridge:migrate-sensitive-uploads --apply --delete-public
```

## Noor privacy

`POST /api/assistant/chat` is authenticated and rate-limited. The server removes common direct identifiers such as email addresses and long phone/ID-like numbers before sending the conversation to Groq. API keys remain server-side and must never be embedded in Flutter or committed to Git.

---

# واجهة EduBridge الخلفية

واجهة API مبنية باستخدام Laravel لمنصة EduBridge التعليمية، مع دعم إمكانية الوصول وإدارة الأدوار والبيانات التعليمية.

## بيئة التشغيل

- PHP 8.4
- Laravel 13
- PostgreSQL
- مصادقة JWT
- Cloudflare R2 لتخزين الملفات في الإنتاج
- Groq لتشغيل المساعد التعليمي «نور»

بيئة الإنتاج مستضافة على Oracle Cloud، وعنوان الـAPI العام هو:

```text
https://api.edubridge.win
```

## التشغيل محليًا

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

لتشغيل الاختبارات:

```bash
php artisan test
```

## إعدادات الإنتاج المطلوبة

المصادقة:

```env
JWT_SECRET=
GOOGLE_CLIENT_ID=
```

مساعد نور:

```env
GROQ_API_KEY=
GROQ_MODEL=openai/gpt-oss-20b
```

Cloudflare R2:

```env
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=auto
AWS_ENDPOINT=
AWS_USE_PATH_STYLE_ENDPOINT=true

R2_PRIVATE_BUCKET=edubridge-private
R2_MEDIA_BUCKET=edubridge-media
R2_MEDIA_PUBLIC_URL=https://media.edubridge.win
```

يجب ألا يكون الـprivate bucket متاحًا للعامة. مستندات الهوية والشهادات ومستندات صلة القرابة لا تُعرض إلا عبر مسارات API محمية بالمصادقة.

## فحوصات مفيدة

```bash
php artisan about
php artisan route:list
php artisan test
php artisan edubridge:r2-check
```

بعد تعديل متغيرات البيئة على الإنتاج، امسح إعدادات Laravel المؤقتة:

```bash
php artisan config:clear
```

## ترحيل الملفات الحساسة

فحص بدون تطبيق:

```bash
php artisan edubridge:migrate-sensitive-uploads
```

تطبيق الترحيل:

```bash
php artisan edubridge:migrate-sensitive-uploads --apply
```

احذف النسخ العامة القديمة فقط بعد التأكد من أن الملفات المهاجرة أصبحت متاحة بشكل صحيح:

```bash
php artisan edubridge:migrate-sensitive-uploads --apply --delete-public
```

## خصوصية نور

المسار `POST /api/assistant/chat` يتطلب مصادقة ومحدود بعدد طلبات. يقوم الخادم بإزالة المعرّفات المباشرة الشائعة، مثل عناوين البريد الإلكتروني وأرقام الهاتف أو الهوية الطويلة، قبل إرسال المحادثة إلى Groq. يجب أن تبقى مفاتيح API على الخادم فقط، وألا تُضمَّن داخل تطبيق Flutter أو تُرفع إلى Git.


## Official school account activation — production notes

- School accounts use the school's `official_email`, independently from any director's personal login.
- The one-time setup link is valid for 24 hours for links issued by the updated backend. Previously issued links retain their original expiry. Resend requests are rate-limited (10-minute cooldown).
- The public page is `/school-account/setup`; the mailbox owner chooses a password of at least 12 characters. Never share setup tokens or passwords in logs or tickets.
- Production's `users` table may omit `updated_at`. The activation controller checks the column before inserting a user. Do not add a production column solely to work around this issue.
- After deploying a fix, use an existing unexpired link or request a new one. Check API and web health, then verify school sign-in and its read-only scope. Do not recreate the school or directly insert a user into PostgreSQL.
- Deployment and database migrations are separate operations; back up and review migrations before applying them.
