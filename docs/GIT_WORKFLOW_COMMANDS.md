# EduBridge Git Workflow Commands

> آخر مراجعة: 2026-10-05

هذا الملف يختصر أوامر Git المعتمدة للعمل والنشر في EduBridge.

## شغل عادي

ابدأ من `develop`:

```bash
git checkout develop
git pull --ff-only origin develop
```

أنشئ فرعًا مناسبًا:

```bash
git checkout -b feature/web-new-feature
# أو
git checkout -b fix/api-example
# أو
git checkout -b chore/deploy-example
# أو
git checkout -b refactor/app-example
# أو
git checkout -b docs/update-runbook
```

بعد التعديل:

```bash
git status
git add .
git commit -m "fix(api): describe the change"
git push -u origin <branch-name>
```

افتح Pull Request إلى `develop` وانتظر نجاح الـCI والمراجعة.

## Release إلى الإنتاج

افتح Pull Request:

```text
develop -> main
```

بعد الدمج، على خادم Oracle:

```bash
cd ~/EduBridge
git checkout main
git pull --ff-only origin main
bash deploy/oracle-deploy.sh
```

ثم:

```bash
curl -I https://edubridge.win
curl -I https://api.edubridge.win/api/health
./deploy/security-smoke.sh
```

## Hotfix عاجل

ابدأ من `main`:

```bash
git checkout main
git pull --ff-only origin main
git checkout -b hotfix/security-example
```

بعد الإصلاح:

```bash
git add .
git commit -m "fix(security): describe production fix"
git push -u origin hotfix/security-example
```

افتح Pull Request مباشرة إلى `main`، انتظر CI، ادمج، ثم انشر واختبر.

إذا كان التغيير يمس Cloudflare/Caddy/origin firewall، شغّل أيضًا من جهاز خارج الخادم:

```bash
EDUBRIDGE_ORIGIN_IP=<ORACLE_PUBLIC_IP> ./deploy/cloudflare-proxy-smoke.sh
```

بعد ذلك أعد نفس الإصلاح إلى `develop` إذا كان الفرعان قد تباعدا.

## التعامل مع تعديلات محلية على خادم الإنتاج

إذا رفض `git pull` بسبب ملف معدل محليًا، لا تستخدم `reset --hard` مباشرة. افحص التغيير أولًا:

```bash
git status
git diff -- <file>
```

إذا كان التعديل المحلي مؤقتًا ويمكن حفظه:

```bash
git stash push -m "server-local-before-update" -- <file>
git pull --ff-only origin main
```

لا تعمل `git stash pop` تلقائيًا إذا كانت نسخة المستودع الجديدة تستبدل التعديل القديم.

## القاعدة المختصرة

```text
feature/*  ─┐
fix/*      ─┤
chore/*    ─┼──> develop ──> main
refactor/* ─┤
docs/*     ─┘

hotfix/* ────────────────> main
```

ممنوع الدفع المباشر إلى `main`، ولا يتم تجاوز CI الفاشل بدون إجراء طارئ مصرح ومبرر.
