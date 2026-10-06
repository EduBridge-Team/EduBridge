# EduBridge — Branching Strategy

> Last verified: 2026-10-05

EduBridge is a monorepo containing Laravel API, React web, Flutter mobile, deployment/security configuration and documentation.

## Long-lived branches

| Branch | Purpose | Rules |
|---|---|---|
| `main` | Production-ready code | Protected. Normal releases come from `develop`; urgent production fixes may come from `hotfix/*`. |
| `develop` | Integration branch | Protected. Normal feature/fix/chore/refactor/docs work targets this branch. |

## Short-lived branches

Use one branch per focused unit of work.

| Prefix | Use | Normal target |
|---|---|---|
| `feature/` | New product functionality | `develop` |
| `fix/` | Non-emergency bug fix | `develop` |
| `chore/` | Tooling, dependencies, config, docs | `develop` |
| `refactor/` | Internal code restructuring | `develop` |
| `docs/` | Documentation-only change | `develop` |
| `hotfix/` | Urgent production/security fix | `main` |

Recommended naming:

```text
<type>/<component>-<short-description>
```

Components commonly include `api`, `web`, `app`, `deploy`, `security`, `docs`.

Examples:

```text
feature/web-consultation-form
fix/app-notification-navigation
chore/deploy-ci-pipeline
docs/security-runbook
hotfix/security-csp-header
```

## Normal workflow

```bash
git checkout develop
git pull --ff-only origin develop
git checkout -b feature/web-example
# work, test, commit
git push -u origin feature/web-example
```

Open the Pull Request into `develop`, wait for CI/review, merge, and delete the short-lived branch.

## Release workflow

When `develop` is ready for production:

1. open `develop -> main`;
2. wait for required CI and review;
3. merge;
4. deploy `main` using the documented Oracle procedure;
5. run production smoke/security checks;
6. tag a release when appropriate.

Example tag:

```bash
git checkout main
git pull --ff-only origin main
git tag -a v1.10.0 -m "Release v1.10.0"
git push origin v1.10.0
```

## Hotfix workflow

Urgent production issues may branch from `main` and target `main` directly:

```bash
git checkout main
git pull --ff-only origin main
git checkout -b hotfix/security-example
# make the smallest safe change
git push -u origin hotfix/security-example
```

A hotfix still requires the relevant CI/security checks. After merge/deploy, reflect the change in `develop` if the branches have diverged.

## Production/security configuration changes

Changes to any of the following should use a narrowly scoped branch and update documentation in the same PR:

- Cloudflare rules/DNS assumptions;
- Caddy configuration;
- trusted proxy/real-IP behavior;
- firewall/origin exposure;
- API authentication or rate limits;
- upload/body limits;
- Docker port publishing;
- production backup/restore behavior.

After deploy, run `deploy/security-smoke.sh`. For edge/origin changes also run `deploy/cloudflare-proxy-smoke.sh` from outside the VPS.

## Commit messages

Use short descriptive messages; Conventional Commit-style prefixes are encouraged:

```text
feat(web): add consultation request form
fix(api): enforce child ownership
chore(deploy): update Caddy template
docs: refresh production security runbook
```

---

# EduBridge — استراتيجية الفروع

> آخر مراجعة: 2026-10-05

- `main`: فرع الإنتاج؛ التغييرات العادية تصل إليه من `develop`، والإصلاحات العاجلة فقط من `hotfix/*`.
- `develop`: فرع دمج التطوير العادي.
- `feature/*` و`fix/*` و`chore/*` و`refactor/*` و`docs/*`: تستهدف `develop`.
- `hotfix/*`: إصلاح إنتاج عاجل ويمكنه استهداف `main` مباشرة.

بعد أي Hotfix أمني/تشغيلي: انتظر CI، ادمج، حدّث الخادم، شغّل فحوصات الـsmoke، ثم أعد نفس الإصلاح إلى `develop` إذا كان الفرعان قد تباعدا.

أي تغيير في Cloudflare أو Caddy أو الجدار الناري أو trusted proxies أو rate limits أو منافذ Docker يجب أن يحدّث التوثيق في نفس Pull Request.
