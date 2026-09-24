# EduBridge Web

React web application for the EduBridge education and accessibility platform.

The web frontend provides role-based dashboards and workflows for parents, teachers, specialists, administrators, ministry users, and institutions.

## Tech stack

- React
- Vite
- React Router
- REST API integration with Laravel
- Role-based UI and routing
- Arabic-first RTL design
- Accessibility-oriented components and controls

## Local setup

Install dependencies:

```bash
npm install
```

Start the development server:

```bash
npm run dev
```

Create a production build:

```bash
npm run build
```

## API configuration

The web application communicates with the Laravel API.

For production, the public API is:

```text
https://api.edubridge.win
```

Environment-specific API configuration should be provided through Vite environment variables and deployment configuration rather than hard-coded secrets.

## Main capabilities

The web application includes:

- Authentication and account management
- Role-based dashboards
- Parent and child management
- Lessons, homework, progress, and evaluations
- Educational support and specialist workflows
- Ministry review flows
- Verification and administration tools
- Notifications and conversations
- Accessibility controls
- Noor educational assistant
- Search and reporting interfaces

## Production

The production website is:

```text
https://edubridge.win
```

Production is built and deployed on Oracle through `deploy/oracle-deploy.sh` and `deploy/oracle-web.Dockerfile`.

---

# واجهة EduBridge للويب

واجهة React الخاصة بمنصة EduBridge التعليمية، وتوفر لوحات ومسارات عمل مختلفة لولي الأمر، المعلّم، الأخصائي، الأدمن، الوزارة، والمؤسسة.

## التقنيات

- React
- Vite
- React Router
- تكامل REST API مع Laravel
- واجهة ومسارات حسب الدور
- تصميم عربي RTL
- مكونات وإعدادات موجهة لإمكانية الوصول

## التشغيل محليًا

تثبيت الاعتماديات:

```bash
npm install
```

تشغيل خادم التطوير:

```bash
npm run dev
```

إنشاء نسخة الإنتاج:

```bash
npm run build
```

## إعداد الـAPI

تتصل واجهة الويب بواجهة Laravel API.

عنوان الإنتاج الحالي:

```text
https://api.edubridge.win
```

يجب ضبط عنوان الـAPI حسب البيئة من خلال متغيرات Vite وإعدادات النشر، وعدم تضمين أي أسرار مباشرة في الكود.

## الوظائف الرئيسية

تتضمن واجهة الويب:

- تسجيل الدخول وإدارة الحساب
- لوحات تحكم حسب الدور
- إدارة أولياء الأمور والأطفال
- الدروس والواجبات والتقدم والتقييمات
- الدعم التعليمي ومسارات الأخصائي
- مراجعات الوزارة
- أدوات التوثيق والإدارة
- الإشعارات والمحادثات
- إعدادات إمكانية الوصول
- المساعد التعليمي نور
- البحث والتقارير

## الإنتاج

عنوان الموقع الحالي:

```text
https://edubridge.win
```

يتم بناء ونشر نسخة الإنتاج على Oracle من خلال `deploy/oracle-deploy.sh` و `deploy/oracle-web.Dockerfile`.
