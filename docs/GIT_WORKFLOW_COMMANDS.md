# EduBridge Git Workflow Commands

هذا الملف يشرح أوامر Git المعتمدة للعمل والنشر في مستودع EduBridge.

## 1. بدء أي شغل عادي

ابدأ دائمًا من أحدث نسخة من `develop`:

```bash
git checkout develop
git pull origin develop
```

## 2. إنشاء branch جديد

ميزة جديدة:

```bash
git checkout -b feature/app-new-feature
```

إصلاح خطأ:

```bash
git checkout -b fix/app-login-error
```

إصلاح Backend:

```bash
git checkout -b fix/api-dashboard-stats
```

ترتيب أو صيانة:

```bash
git checkout -b chore/repository-cleanup
```

إعادة هيكلة:

```bash
git checkout -b refactor/app-screen-cleanup
```

تعديل توثيق:

```bash
git checkout -b docs/update-readme
```

## 3. حفظ ورفع التعديلات

راجع الحالة:

```bash
git status
```

أضف التغييرات:

```bash
git add .
```

أنشئ commit واضحًا:

```bash
git commit -m "fix(app): fix login error"
```

ثم ارفع الفرع:

```bash
git push -u origin fix/app-login-error
```

بعدها افتح Pull Request إلى:

```text
fix/app-login-error
        ↓
     develop
```

لا تدمج الـPR إلا بعد نجاح جميع GitHub Actions المطلوبة.

## 4. نشر إصدار جديد للإنتاج

عندما يصبح `develop` جاهزًا:

```bash
git checkout develop
git pull origin develop
```

افتح Pull Request:

```text
develop
   ↓
 main
```

بعد نجاح جميع الـActions والمراجعة، اعمل Merge.

`main` يمثل نسخة الإنتاج.

## 5. Hotfix لمشكلة عاجلة في الإنتاج

ابدأ من `main`:

```bash
git checkout main
git pull origin main
```

أنشئ فرع hotfix:

```bash
git checkout -b hotfix/api-login-error
```

بعد تنفيذ الإصلاح:

```bash
git add .
git commit -m "hotfix(api): fix production login error"
git push -u origin hotfix/api-login-error
```

افتح Pull Request:

```text
hotfix/api-login-error
          ↓
        main
```

بعد نجاح الـActions اعمل Merge.

ثم أعد مزامنة الإصلاح إلى `develop`:

```text
main
 ↓
develop
```

وذلك حتى لا يختفي الـhotfix في الإصدار القادم.

## القاعدة المختصرة

الشغل الطبيعي:

```text
feature/*
fix/*
chore/*
refactor/*
docs/*
    ↓
 develop
    ↓
  main
```

الإصلاح الطارئ:

```text
hotfix/*
    ↓
  main
    ↓
 develop
```

## ممنوع

```text
feature/* → main
fix/* → main
chore/* → main
refactor/* → main
docs/* → main
push مباشر → main
```

ولا يتم دمج أي Pull Request إذا كان أحد الـActions المطلوبة فاشلًا.
