# IT PMO Kanban Board: "PMO Quest"

A single-page Kanban board for a fictitious bank's internal IT PMO, wrapped in a retro 8-bit platformer theme you can actually play.

**Live demo:** https://nsarno38.github.io/claudecodetraining/

![IT PMO Kanban board with a retro platformer stage, solid brick stairs and wall, "!" blocks, and the four columns](docs/screenshot.png)

## The board

- Four columns (Backlog, In Progress, Blocked, Done) with live count badges and a HUD-style summary
- Task cards with ID, title, project, assignee, priority (colour **and** shape/text), due date, category and an overdue badge
- Drag and drop between columns, plus a keyboard-accessible "Move" menu
- Add Task form with inline validation, optimistic UI and toast notifications
- Filters by project, assignee and priority; inline delete confirmation (no browser dialogs)

## The game

Press **Play** on the stage, then:

| Key | Action |
|---|---|
| ← → or A D | walk (with acceleration and friction) |
| Shift | sprint |
| Space, ↑ or W | jump (hold for a higher jump, tap for a short hop) |
| Esc | stop playing |

Brick stairs, a wall and a floating platform are solid: you can't walk through them, but you can jump over them and stand on top. Bump a **!** block from below to open Add Task with that column pre-selected. The blocks are also real buttons, so everything works without playing. On phones, on-screen buttons appear while you play.

The character and art are original pixel art drawn in code (inline SVG and CSS). No Nintendo characters, sprites or sounds are used.

## IT assistant chatbot

A cute pixel-robot avatar sits at the bottom right. **Click it** to open a text chat and hear a spoken greeting: *"I am your IT assistant, how can I help you?"* (browser speech synthesis; the speaker button in the chat header turns the voice on or off, and the greeting is always shown as text too).

It is a small retrieval-augmented (RAG) bot that runs entirely in the browser:

1. **Retrieve:** every question is matched (BM25 ranking with synonyms) against the live board, one document per task, plus built-in help notes.
2. **Answer:** the reply is composed from what was retrieved: counts, task lists, or help text, with clickable source chips. Clicking a task chip scrolls to and highlights that card.

Try: "What is overdue?", "How many tasks are blocked?", "Show critical tasks", "What is Priya working on?", "How do I play?". There is no AI model and no network call; answers are always written as plain text, so task titles can never inject HTML.

## Meeting announcement

After a visitor has spent **10 seconds** on the page, a dialog pops up once: **"IT meeting next Wed 10am at room 888"**. Time only counts while the tab is visible, it waits if the Add Task dialog is open, and it closes with the OK button, the Esc key or a click outside. It is an accessible in-page dialog (not the browser's alert box), and nothing is stored, so a refresh counts as a new visit. Change the text or delay in `NOTICE` inside `setupNotice()`.

## Run locally

No build step. Open `index.html` in a browser.

## Configuration

Set `FORMSUBMIT_ENDPOINT` near the top of the `<script>` to your own address to receive new-task emails through [FormSubmit](https://formsubmit.co). It sends a one-time activation email on first use, and messages only deliver after you confirm it. Until then the board still works and shows a warning. Don't commit a real address to a public repo.

Because anyone can read the page source, the app limits abuse of that endpoint: it never calls FormSubmit while the placeholder is set, keeps CAPTCHA on (`FORMSUBMIT_CAPTCHA = true`), sends a hidden `_honey` honeypot field, allows at most one email per 15 seconds and 10 per visit (`EMAIL_LIMITS`), and cleans the subject line. Prefer FormSubmit's random "invisible email" alias over your real address in `FORMSUBMIT_ENDPOINT`. These are mitigations, not a guarantee: a client-only page cannot fully prevent someone from posting to the endpoint directly.

## Project tooling

- `.claude/commands/publish-github.md`: a custom command that publishes the project (secret check, README, Pages, CI, About).
- `.claude/hooks/verify-chatbot.ps1` (registered in `.claude/settings.json`): a `PostToolUse` hook that runs after Claude edits `index.html` and checks the chatbot's click-to-speak greeting is still wired up (exact greeting text, speech call, avatar handler, mute button, no `innerHTML` in chat output). It exits with code 2 and a clear message if something is broken.
- `.claude/hooks/verify-meeting-notice.ps1` (also registered in `.claude/settings.json`): a second `PostToolUse` hook that checks the meeting announcement is still correct after any edit to `index.html` (exact message, 10-second delay, `alertdialog` role, OK button, Esc to close, timer counts only while the tab is visible, no `alert()`/`confirm()`, no browser storage).
- `.claude/agents/security-scanner.md`: a read-only security-scanning agent that writes a Word report to `security/`.
- `.claude/skills/`: project-level agent skills (`ui-ux-pro-max`, `retro`, `cybersecurity-analyst`). The theme was designed with `ui-ux-pro-max`'s Pixel Art style.
- `.mcp.json`: Playwright MCP server for browser testing.
- `.github/workflows/ci.yml`: CI checks on every push.

## Notes

- Demo data only. Nothing is persisted: no localStorage, cookies or backend.
- Vanilla HTML, CSS and JavaScript, with no dependencies, external fonts or audio files.
- Fictitious demo: not an official system of any organisation.
