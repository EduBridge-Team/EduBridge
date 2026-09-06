# EduBridge — Branching Strategy

EduBridge is a **monorepo** containing several components:

| Path | Component |
|------|-----------|
| `edubridge-api-laravel` | Backend API (Laravel) |
| `edubridge-web` | Web frontend |
| `edubridge-app` | Mobile / app |
| `deploy` | Deployment configuration |

To keep work organized across these components, we follow a lightweight
**GitHub Flow** based on short-lived branches merged into `main` via Pull Requests.

## Long-lived branches

| Branch | Purpose | Rules |
|--------|---------|-------|
| `main` | Production — always deployable | Protected. Changes land only through reviewed PRs. |

> **Optional:** teams that want a staging buffer before production can add a
> `develop` branch. Feature branches then merge into `develop`, and `develop`
> is merged into `main` for each release. Start without it and add it only if
> the team needs an integration stage.

## Short-lived branches

Create one branch per unit of work, branched off the latest `main`, and delete it
after the PR is merged.

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

1. **Sync** with the latest `main`:
   ```bash
   git checkout main
   git pull origin main
   ```
2. **Branch** for your work:
   ```bash
   git checkout -b feature/web-consultation-form
   ```
3. **Commit** in small, focused steps with clear messages.
4. **Push** and open a Pull Request into `main`:
   ```bash
   git push -u origin feature/web-consultation-form
   ```
5. **Review** — at least one approval before merge.
6. **Merge** the PR, then delete the branch.

## Hotfixes

For an urgent production issue:

```bash
git checkout main
git pull origin main
git checkout -b hotfix/api-auth-token-expiry
# ...fix, commit...
git push -u origin hotfix/api-auth-token-expiry
```

Open a PR into `main`, fast-track the review, and merge.
(If you use a `develop` branch, merge the hotfix back into `develop` too.)

## Commit messages

Keep messages short and descriptive. A conventional prefix is encouraged:

```
feat(web): add consultation request form
fix(api): correct verification token expiry
chore(deploy): update CI cache configuration
```
