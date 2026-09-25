# Contributing to EduBridge

Thank you for contributing to EduBridge. This repository uses a protected two-branch workflow so changes stay reviewable and production remains stable.

## Branch model

- `main` — production-ready code.
- `develop` — integration branch for normal development.
- `feature/*` — new features. Open pull requests into `develop`.
- `fix/*` — bug fixes. Open pull requests into `develop`.
- `chore/*` — maintenance and repository work. Open pull requests into `develop`.
- `refactor/*` — internal refactors. Open pull requests into `develop`.
- `docs/*` — documentation-only changes. Open pull requests into `develop`.
- `hotfix/*` — urgent production fixes. These may target `main` directly.

Normal release flow:

```text
feature/*  ─┐
fix/*      ─┤
chore/*    ─┼──> develop ──> main
refactor/* ─┤
docs/*     ─┘

hotfix/* ────────────────> main
```

## Pull requests

Direct pushes to `main` and `develop` are restricted by repository Rulesets. Use a pull request for every change.

Before opening a pull request:

1. Start from the latest target branch.
2. Use the appropriate branch prefix.
3. Keep commits focused and descriptive.
4. Run the relevant local tests and linters.
5. Describe what changed and how it was verified.

All review conversations must be resolved before merging.

## Required checks

Pull requests into protected branches are validated by GitHub Actions. Depending on the target branch, required checks include:

- React production build
- PHP syntax
- Laravel tests
- Flutter ↔ Laravel API contract

Do not merge around failing checks unless an authorized emergency bypass is intentionally being used.

## Releasing to production

Normal changes are merged into `develop` first. When `develop` is ready for production, open a pull request from:

```text
develop -> main
```

The Branch Guard workflow rejects normal feature/fix/chore/refactor/docs branches that target `main` directly.

## Hotfixes

For an urgent production issue:

1. Branch from the current `main` using `hotfix/<short-name>`.
2. Make the smallest safe fix.
3. Open the pull request directly into `main`.
4. Let required CI checks finish before merging.
5. Make sure the hotfix is also reflected in `develop` afterward if the branches have diverged.

## Merge strategy

Use the merge method that best preserves a clear history. Squash merge is preferred for small feature/fix branches with noisy commit history; merge commits are appropriate when preserving branch history is useful.

## Security

Do not commit secrets, production credentials, private keys, service-account files, signing keys, or user data. Use repository/environment secrets and the approved deployment configuration instead.

---

# المساهمة في EduBridge

شكرًا لمساهمتك في EduBridge. يستخدم هذا المستودع سير عمل محميًا يعتمد على فرعين رئيسيين حتى تبقى التغييرات قابلة للمراجعة ويظل كود الإنتاج مستقرًا.

## نموذج الفروع

- `main` — الكود الجاهز للإنتاج.
- `develop` — فرع الدمج الخاص بالتطوير المعتاد.
- `feature/*` — الميزات الجديدة. افتح Pull Request إلى `develop`.
- `fix/*` — إصلاحات الأخطاء. افتح Pull Request إلى `develop`.
- `chore/*` — أعمال الصيانة وترتيب المستودع. افتح Pull Request إلى `develop`.
- `refactor/*` — إعادة هيكلة داخلية للكود. افتح Pull Request إلى `develop`.
- `docs/*` — تغييرات التوثيق فقط. افتح Pull Request إلى `develop`.
- `hotfix/*` — إصلاحات إنتاج عاجلة. يمكن أن تستهدف `main` مباشرة.

مسار الإصدار المعتاد:

```text
feature/*  ─┐
fix/*      ─┤
chore/*    ─┼──> develop ──> main
refactor/* ─┤
docs/*     ─┘

hotfix/* ────────────────> main
```

## طلبات الدمج Pull Requests

عمليات الدفع المباشر إلى `main` و`develop` مقيّدة بواسطة قواعد المستودع Rulesets. استخدم Pull Request لكل تغيير.

قبل فتح Pull Request:

1. ابدأ من أحدث نسخة من الفرع المستهدف.
2. استخدم بادئة الفرع المناسبة.
3. اجعل الـ commits مركزة ووصفية.
4. شغّل الاختبارات وأدوات الفحص المحلية ذات الصلة.
5. اشرح ما الذي تغير وكيف تم التحقق منه.

يجب حل جميع محادثات وملاحظات المراجعة قبل الدمج.

## الفحوصات المطلوبة

يتم التحقق من Pull Requests الموجهة إلى الفروع المحمية بواسطة GitHub Actions. وبحسب الفرع المستهدف، تشمل الفحوصات المطلوبة:

- بناء React للإنتاج
- فحص صياغة PHP
- اختبارات Laravel
- عقد التكامل بين Flutter وLaravel API

لا تتجاوز الفحوصات الفاشلة عند الدمج إلا إذا تم استخدام صلاحية تجاوز طارئة ومصرح بها بشكل مقصود.

## النشر إلى الإنتاج

يتم دمج التغييرات العادية في `develop` أولًا. وعندما يصبح `develop` جاهزًا للإنتاج، افتح Pull Request من:

```text
develop -> main
```

سير عمل Branch Guard يرفض فروع `feature` و`fix` و`chore` و`refactor` و`docs` العادية إذا حاولت استهداف `main` مباشرة.

## الإصلاحات العاجلة

عند وجود مشكلة عاجلة في الإنتاج:

1. أنشئ فرعًا من `main` الحالي باستخدام `hotfix/<short-name>`.
2. نفّذ أصغر إصلاح آمن ممكن.
3. افتح Pull Request مباشرة إلى `main`.
4. انتظر اكتمال فحوصات CI المطلوبة قبل الدمج.
5. تأكد بعد ذلك من أن نفس الإصلاح موجود أيضًا في `develop` إذا كان الفرعان قد تباعدا.

## استراتيجية الدمج

استخدم طريقة الدمج التي تحافظ على سجل واضح بأفضل شكل. يُفضّل استخدام Squash Merge لفروع الميزات والإصلاحات الصغيرة التي تحتوي على سجل commits مزدحم، بينما تكون Merge Commits مناسبة عندما يكون الحفاظ على تاريخ الفرع مفيدًا.

## الأمان

لا تقم بإضافة الأسرار أو بيانات اعتماد الإنتاج أو المفاتيح الخاصة أو ملفات حسابات الخدمة أو مفاتيح توقيع التطبيقات أو بيانات المستخدمين إلى المستودع. استخدم أسرار المستودع أو البيئة وإعدادات النشر المعتمدة بدلًا من ذلك.
