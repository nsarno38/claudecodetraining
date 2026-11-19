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

## Run locally

No build step. Open `index.html` in a browser.

## Configuration

Set `FORMSUBMIT_ENDPOINT` near the top of the `<script>` to your own address to receive new-task emails through [FormSubmit](https://formsubmit.co). It sends a one-time activation email on first use, and messages only deliver after you confirm it. Until then the board still works and shows a warning. Don't commit a real address to a public repo.

## Project tooling

- `.claude/commands/publish-github.md`: a custom command that publishes the project (secret check, README, Pages, CI, About).
- `.claude/skills/`: project-level agent skills (`ui-ux-pro-max`, `retro`, `cybersecurity-analyst`). The theme was designed with `ui-ux-pro-max`'s Pixel Art style.
- `.mcp.json`: Playwright MCP server for browser testing.
- `.github/workflows/ci.yml`: CI checks on every push.

## Notes

- Demo data only. Nothing is persisted: no localStorage, cookies or backend.
- Vanilla HTML, CSS and JavaScript, with no dependencies, external fonts or audio files.
- Fictitious demo: not an official system of any organisation.
