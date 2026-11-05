# EduBridge — Branching Strategy

> Verified: 2026-11-05. Single protected trunk: `main`.

EduBridge is a monorepo containing Laravel API, React web, Flutter, deployment/security configuration and documentation.

## Branches and pull requests

- `main`: the **only permanent integration and production branch**; protected from direct pushes.
- Start every change from the latest `main` in a short-lived `feature/*`, `fix/*`, `chore/*`, `refactor/*`, `docs/*`, `test/*` or `hotfix/*` branch.
- Open the PR directly against `main`; wait for branch guard, required quality/security CI and review.
- Do not merge around failing security checks without a separately approved and recorded emergency exception.
- Merge to `main` before deployment, then delete the short-lived branch once the change and follow-up references are verified.
- `develop` was retired after an ancestry audit found zero commits unique to it relative to `main`. Historical PRs and tags remain in GitHub; do not recreate `develop` for new work.
- A closed PR does **not** prove its branch content is merged. Before deleting old branches, compare against `main` and review squash-merged equivalents.

Recommended branch naming: `feature/web-consultation-form`, `fix/app-notification-navigation`, `chore/deploy-ci-pipeline`, `docs/security-runbook`, `hotfix/security-csp-header`.

## Normal development workflow

```bash
git fetch origin
git switch main
git pull --ff-only origin main
git switch -c feature/web-example
# edit, test, commit
git push -u origin feature/web-example
# Open a PR: feature/web-example -> main
```

## Release workflow

1. Review and merge the approved PR to `main` after required checks and review.
2. Deploy **only from `main`** via the documented Oracle release procedure, with backup and rollback controls.
3. Perform the appropriate production smoke/security checks.
4. Tag the reviewed release if needed.

```bash
git switch main
git pull --ff-only origin main
git tag -a v1.10.0 -m "Release v1.10.0"
git push origin v1.10.0
```

## Hotfixes

Use `hotfix/*` based on the latest `main`. Open a narrowly scoped PR to `main`, pass required security checks (or obtain a documented emergency authorization), merge, deploy and validate. There is no second long-lived integration branch to backport to.

## Production/security configuration

Changes to Cloudflare, DNS, Caddy, trusted proxy/real IP, firewall, authentication/rate limits, request body limits, Docker ports, and backup/restore processes must update relevant documentation in the **same PR**. After deploy run `deploy/security-smoke.sh`; for edge/origin changes run `deploy/cloudflare-proxy-smoke.sh` from outside the VPS.

## Commit messages

Use focused Conventional Commit-style messages, e.g. `fix(api): enforce child ownership` or `docs: refresh production security runbook`.

---

# EduBridge — استراتيجية الفروع

> آخر مراجعة: 2026-11-05

- **`main` هو فرع التطوير والتجميع والإنتاج الوحيد**، وهو محمي ولا يُدفع إليه مباشرة.
- أنشئ فرعًا قصير العمر من أحدث `main` باسم `feature/*` أو `fix/*` أو `chore/*` أو `refactor/*` أو `docs/*` أو `test/*` أو `hotfix/*`.
- افتح طلب الدمج إلى **`main` مباشرة**؛ انتظر المراجعة وفحوص CI المطلوبة.
- فرع `develop` متقاعد؛ لم تكن له Commits إضافية خارج `main` عند التدقيق. لا تُعِد إنشاءه.
- بعد الدمج والتحقق من عدم الحاجة للفرع، احذف الفرع المؤقت. لا تفترض أن إغلاق PR يساوي الدمج.
- قبل النشر افحص النسخ الاحتياطية والتغييرات؛ انشر من `main`، ثم نفّذ فحوص الصحة والأمان. لا تتجاوز فشل فحص أمني دون موافقة طوارئ موثقة.
