# Contributing to EduBridge

> Last verified: 2026-10-05

Thank you for contributing to EduBridge. This repository uses protected branches and CI to keep `main` deployable and production-safe.

## Branch model

- `main` — production-ready code.
- `develop` — integration branch for normal development.
- `feature/*` — new functionality -> `develop`.
- `fix/*` — non-emergency bug fixes -> `develop`.
- `chore/*` — maintenance/tooling/configuration -> `develop`.
- `refactor/*` — internal refactors -> `develop`.
- `docs/*` — documentation-only work -> `develop`.
- `hotfix/*` — urgent production fixes; may target `main` directly.

Normal flow:

```text
feature/*  ─┐
fix/*      ─┤
chore/*    ─┼──> develop ──> main
refactor/* ─┤
docs/*     ─┘

hotfix/* ────────────────> main
```

## Pull requests

Use a Pull Request for protected branches. Before opening one:

1. Start from the latest target branch.
2. Use the correct branch prefix.
3. Keep commits focused.
4. Run relevant tests/linters locally.
5. Explain what changed and how it was verified.
6. Update documentation in the same PR when architecture, deployment, security, roles, schema or operational behavior changes.
7. Resolve review conversations before merge.

## CI checks

Checks vary by changed area and target branch. Current workflows include:

- Branch Guard
- Dependency security audit
- Detect changed areas
- React production build
- PHP syntax
- Laravel tests
- Flutter ↔ Laravel API contract
- Fresh PostgreSQL migration
- Production API container build/runtime verification
- Deployment/config syntax checks when relevant

Do not merge around a failing security or production-runtime check unless an authorized emergency bypass is explicitly required and documented.

## Production changes

Any change that affects Cloudflare, Caddy, firewall assumptions, Laravel trusted proxies, auth throttling, request limits or production Docker bindings must update the relevant docs and run the security smoke tests.

Minimum post-change verification:

```bash
./deploy/security-smoke.sh
```

For Cloudflare/origin changes, run from an external machine:

```bash
EDUBRIDGE_ORIGIN_IP=<ORACLE_PUBLIC_IP> ./deploy/cloudflare-proxy-smoke.sh
```

## Documentation

Start from `docs/README.md`.

When implementation and documentation disagree, code/configuration in `main` is authoritative; fix the documentation immediately rather than preserving a known-stale statement.

Do not include secrets, private keys, JWTs, real user data, database passwords or production API tokens in documentation, issues, PRs or screenshots.

## Hotfixes

For an urgent production issue:

1. branch from current `main` using `hotfix/<short-name>`;
2. implement the smallest safe fix;
3. open the PR directly to `main`;
4. wait for required CI checks;
5. merge after review/validation;
6. deploy and run the relevant smoke tests;
7. reflect the hotfix back into `develop` if the branches have diverged.

## Merge strategy

Use the merge method that preserves a clear history. Squash merge is useful for small/noisy branches; merge commits are appropriate when preserving branch history adds value.

## Security

Never commit `.env` files, signing keys, certificates/private keys, service-account credentials, Cloudflare API tokens, R2 credentials, database passwords or production user data. Use GitHub/environment secrets and the approved server-side configuration.

---

# المساهمة في EduBridge

> آخر مراجعة: 2026-10-05

يستخدم المشروع فروعًا محمية وCI للحفاظ على `main` جاهزًا للإنتاج.

- التطوير العادي (`feature/*` و`fix/*` و`chore/*` و`refactor/*` و`docs/*`) يتجه إلى `develop`.
- الإصلاحات العاجلة فقط تستخدم `hotfix/*` ويمكنها استهداف `main` مباشرة.
- أي تغيير في البنية، النشر، Cloudflare، Caddy، الجدار الناري، الصلاحيات، قاعدة البيانات أو الأمن يجب أن يحدّث التوثيق في نفس الـPR.
- شغّل الاختبارات المناسبة وانتظر CI قبل الدمج.
- بعد تغييرات الأمان/النشر شغّل `deploy/security-smoke.sh`، ومع تغييرات Cloudflare/origin شغّل أيضًا `deploy/cloudflare-proxy-smoke.sh` من جهاز خارج الخادم.
- لا تضع أسرارًا أو مفاتيح أو بيانات مستخدمين حقيقية داخل المستودع أو التوثيق.

راجع `docs/README.md` لخريطة التوثيق الحالية و`BRANCHING.md` لتفاصيل استراتيجية الفروع.
