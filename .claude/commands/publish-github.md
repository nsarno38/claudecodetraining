---
description: Publish the project to a GitHub repo (push, README, About, Pages, CI/CD, secrets check)
argument-hint: <github repo URL or owner/repo>
allowed-tools: Read, Write, Edit, Glob, Grep, PowerShell
---

Publish this project to the GitHub repo given in: $ARGUMENTS

If no repo was given, ask for it (URL or `owner/repo`) and stop until you have it. Work through the steps in order. Report each step's real outcome; if a step could not be done, say so and give the manual fix instead of claiming success.

## 0. Preflight
- Windows: if `git` or `gh` is not recognised, prepend `C:\Program Files\Git\cmd` and `C:\Program Files\GitHub CLI` to `$env:Path` for the session. If still missing, tell the user and offer `winget install --id Git.Git -e --source winget` (and `GitHub.cli`); install only after they agree.
- Run `gh auth status`. The shell cannot show sign-in prompts, so if not authenticated, ask the user to run `gh auth login` (or `git push` once) in their own terminal, then continue.
- Parse `$ARGUMENTS` into `owner/repo`. Confirm the repo with `gh repo view` or `git ls-remote`.

## 1. Sensitive-data check (BEFORE any commit or push)
Never push until this passes. Search every file that would be committed (and git history if the repo already exists):
- Files: `.env*`, `*.pem`, `*.key`, `id_rsa*`, `credentials*`, `*.pfx`, `secrets*`, `.claude/settings.local.json`.
- Content (Grep, case-insensitive): `api[_-]?key`, `secret`, `token`, `password`, `passwd`, `bearer `, `AKIA[0-9A-Z]{16}`, `ghp_[A-Za-z0-9]{20,}`, `sk-[A-Za-z0-9]{20,}`, `-----BEGIN .*PRIVATE KEY`.
- Personal data: real email addresses, phone numbers, internal hostnames or IPs, and endpoints that embed an email (e.g. `formsubmit.co/ajax/<real email>`). Placeholders such as `YOUR_EMAIL@example.com` are fine; a real address is not, so tell the user to keep it out of the repo (e.g. leave the placeholder in the committed file).
- Git identity: use the GitHub no-reply address for commits (`<username>@users.noreply.github.com`) via repo-local `git config user.name/user.email`. Never commit with the user's real email unless they ask.
- Add a `.gitignore` covering `.env*`, key files, `node_modules/`, OS junk, and `.claude/settings.local.json`.
- If anything sensitive is found: stop, list file and line (mask the value), and ask the user how to proceed. Do not push.

## 2. README
Create or update `README.md` from the actual project (read the code; do not invent features): title, one-line description, features, how to run locally, configuration (any constants the user must change), tech stack, live-demo link (filled in at step 6), and license note if one exists. If a README already exists, edit it rather than replacing user-written content.

## 3. Commit and push
- `git init` if needed; set `main` as the branch; add `origin` (fix it if it points elsewhere).
- Stage files explicitly (not blindly `git add .`), review `git status`, commit with a clear message, `git push -u origin main`.
- Do not force-push. If the remote has unrelated history, stop and ask.

## 4. GitHub Pages
- Static sites: enable Pages from branch `main`, path `/` (or `/docs` if that is where the site lives):
  `gh api -X POST repos/OWNER/REPO/pages -f "source[branch]=main" -f "source[path]=/"` (use PUT if Pages already exists).
- The repo must be public for Pages on free accounts; if it is private, tell the user rather than changing visibility yourself.
- Ensure the entry point is `index.html` at the published root.
- Expected URL: `https://OWNER.github.io/REPO/`. Poll `gh api repos/OWNER/REPO/pages` and then fetch the URL until it returns 200 (allow a few minutes). Report the real status.
- If `gh` is unavailable, give the manual path: Settings → Pages → Deploy from a branch → `main` / root.

## 5. CI/CD with GitHub Actions
Create `.github/workflows/` files suited to the project:
- Always: a `pages.yml` deploying to Pages on push to `main` (`actions/checkout`, `actions/configure-pages`, `actions/upload-pages-artifact`, `actions/deploy-pages`; permissions `contents: read`, `pages: write`, `id-token: write`; concurrency group `pages`). If using this, set the Pages source to "GitHub Actions" (`build_type=workflow`) instead of branch in step 4.
- Add a lightweight `ci.yml` on push and pull_request: for a static site, validate that `index.html` exists, run an HTML check if tooling is configured, and grep-guard against forbidden patterns the project defines (see CLAUDE.md, e.g. storage APIs or external URLs). For projects with a package manager, run install, lint and test.
- Pin actions to major versions, use least-privilege `permissions`, and never put secrets in workflow files (use `${{ secrets.NAME }}`).
- After pushing, check the run with `gh run list --limit 3` / `gh run watch` and report pass or fail with the failing log if any.

## 6. Repo "About" and Pages link
- Set the description, homepage (the Pages URL) and topics:
  `gh repo edit OWNER/REPO --description "<short description>" --homepage "https://OWNER.github.io/REPO/" --add-topic <t1> --add-topic <t2>`
- Add the live link to the README, commit and push the update.
- If `gh` is unavailable, tell the user to click the gear next to "About" on the repo page and paste the description and URL.

## 7. Final report
Give: repo URL, live Pages URL and whether it returned 200, Actions run status, the sensitive-data check result (what was scanned, what was found), and anything the user still has to do manually.
