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
