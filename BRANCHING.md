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
