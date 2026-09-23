# EduBridge — Branching Strategy

EduBridge is a **monorepo** containing several components:

| Path | Component |
|------|-----------|
| `edubridge-api-laravel` | Backend API (Laravel) |
| `edubridge-web` | Web frontend |
| `edubridge-app` | Mobile / app |
| `deploy` | Deployment configuration |

To keep work organized across these components, we follow a **Git Flow–style**
model: short-lived branches merge into `develop`, and `develop` is merged into
`main` for each release.

## Long-lived branches

| Branch | Purpose | Rules |
|--------|---------|-------|
| `main` | Production — always deployable | Protected. Only updated via a PR from `develop` (or a `hotfix/*` branch). |
| `develop` | Integration branch — where features land before release | Protected. All `feature/*` and `fix/*` PRs target this branch. |

## Short-lived branches

Create one branch per unit of work, branched off the latest `develop`
(`hotfix/*` branches off `main` instead — see [Hotfixes](#hotfixes)), and
delete it after the PR is merged.

### Naming convention

Prefix every branch with its **type** and its **component**, so it is obvious what
the branch touches:

```
<type>/<component>-<short-description>
```

**Types**

| Type | Use for |
|------|---------|
| `feature/` | New functionality |
| `fix/` | Bug fixes |
| `hotfix/` | Urgent production fixes (branched from `main`) |
| `chore/` | Tooling, config, dependencies, docs |
| `refactor/` | Code restructuring with no behavior change |

**Components:** `api`, `web`, `app`, `deploy`

### Examples

```
feature/web-consultation-form
feature/api-verification-endpoint
feature/app-login-screen
fix/web-navbar-mobile
chore/deploy-ci-pipeline
hotfix/api-auth-token-expiry
```

## Workflow

1. **Sync** with the latest `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   ```
2. **Branch** for your work:
   ```bash
   git checkout -b feature/web-consultation-form
   ```
3. **Commit** in small, focused steps with clear messages.
4. **Push** and open a Pull Request into `develop`:
   ```bash
   git push -u origin feature/web-consultation-form
   ```
5. **Review** — at least one approval before merge.
6. **Merge** the PR, then delete the branch.

## Releases (`develop` → `main`)

When `develop` has a stable batch of features ready to ship:

1. Open a PR from `develop` into `main`.
2. Review and merge.
3. Tag the release on `main`, e.g.:
   ```bash
   git checkout main
   git pull origin main
   git tag -a v1.10.0 -m "Release v1.10.0"
   git push origin v1.10.0
   ```

## Hotfixes

For an urgent production issue that can't wait for the next `develop` → `main` release:

```bash
git checkout main
git pull origin main
git checkout -b hotfix/api-auth-token-expiry
# ...fix, commit...
git push -u origin hotfix/api-auth-token-expiry
```

Open a PR into `main`, fast-track the review, and merge. Then merge (or
cherry-pick) the same fix into `develop` so it isn't lost on the next release.

## Commit messages

Keep messages short and descriptive. A conventional prefix is encouraged:

```
feat(web): add consultation request form
fix(api): correct verification token expiry
chore(deploy): update CI cache configuration
```

---

# EduBridge — استراتيجية الفروع

EduBridge هو **مستودع موحّد (Monorepo)** يحتوي على عدة مكونات:

| المسار | المكوّن |
|------|-----------|
| `edubridge-api-laravel` | واجهة الـ API الخلفية (Laravel) |
| `edubridge-web` | واجهة الويب |
| `edubridge-app` | تطبيق الهاتف |
| `deploy` | إعدادات النشر |

للحفاظ على تنظيم العمل بين هذه المكونات، نتبع نموذجًا قريبًا من **Git Flow**:
يتم دمج الفروع قصيرة العمر في `develop`، ثم يتم دمج `develop` في `main` عند كل إصدار.

## الفروع طويلة العمر

| الفرع | الغرض | القواعد |
|--------|---------|-------|
| `main` | الإنتاج — يجب أن يكون قابلًا للنشر دائمًا | محمي. يتم تحديثه فقط عبر Pull Request من `develop` أو من فرع `hotfix/*`. |
| `develop` | فرع الدمج — تصل إليه الميزات قبل الإصدار | محمي. جميع Pull Requests من `feature/*` و`fix/*` تتجه إلى هذا الفرع. |

## الفروع قصيرة العمر

أنشئ فرعًا واحدًا لكل وحدة عمل، انطلاقًا من أحدث نسخة من `develop`.
أما فروع `hotfix/*` فتنطلق من `main` بدلًا من ذلك — راجع قسم [الإصلاحات العاجلة](#الإصلاحات-العاجلة) — ثم احذف الفرع بعد دمج الـ Pull Request.

### أسلوب تسمية الفروع

ابدأ اسم كل فرع بـ **نوع العمل** ثم **المكوّن**، حتى يكون واضحًا مباشرة ما الذي يخصه الفرع:

```
<type>/<component>-<short-description>
```

**الأنواع**

| النوع | يُستخدم من أجل |
|------|---------|
| `feature/` | إضافة وظائف أو ميزات جديدة |
| `fix/` | إصلاح الأخطاء |
| `hotfix/` | إصلاحات إنتاج عاجلة، وتُنشأ من `main` |
| `chore/` | الأدوات والإعدادات والاعتماديات والتوثيق |
| `refactor/` | إعادة هيكلة الكود بدون تغيير السلوك |

**المكونات:** `api`، `web`، `app`، `deploy`

### أمثلة

```
feature/web-consultation-form
feature/api-verification-endpoint
feature/app-login-screen
fix/web-navbar-mobile
chore/deploy-ci-pipeline
hotfix/api-auth-token-expiry
```

## سير العمل

1. **زامن** نسختك مع أحدث `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   ```
2. **أنشئ فرعًا** للعمل:
   ```bash
   git checkout -b feature/web-consultation-form
   ```
3. **أنشئ commits** صغيرة ومركزة برسائل واضحة.
4. **ادفع الفرع** وافتح Pull Request إلى `develop`:
   ```bash
   git push -u origin feature/web-consultation-form
   ```
5. **المراجعة** — يلزم موافقة واحدة على الأقل قبل الدمج.
6. **ادمج** الـ Pull Request ثم احذف الفرع.

## الإصدارات (`develop` → `main`)

عندما يحتوي `develop` على مجموعة مستقرة من الميزات الجاهزة للنشر:

1. افتح Pull Request من `develop` إلى `main`.
2. راجع التغييرات ثم ادمجها.
3. أضف وسمًا للإصدار على `main`، مثلًا:
   ```bash
   git checkout main
   git pull origin main
   git tag -a v1.10.0 -m "Release v1.10.0"
   git push origin v1.10.0
   ```

## الإصلاحات العاجلة

عند وجود مشكلة عاجلة في الإنتاج لا يمكنها انتظار إصدار `develop` → `main` التالي:

```bash
git checkout main
git pull origin main
git checkout -b hotfix/api-auth-token-expiry
# ...fix, commit...
git push -u origin hotfix/api-auth-token-expiry
```

افتح Pull Request مباشرة إلى `main`، وأعطِ المراجعة أولوية، ثم ادمج التغيير.
بعد ذلك، ادمج نفس الإصلاح في `develop` أو استخدم `cherry-pick` حتى لا يضيع الإصلاح في الإصدار التالي.

## رسائل الـ Commit

حافظ على الرسائل قصيرة وواضحة. ويُفضّل استخدام بادئة اصطلاحية:

```
feat(web): add consultation request form
fix(api): correct verification token expiry
chore(deploy): update CI cache configuration
```
