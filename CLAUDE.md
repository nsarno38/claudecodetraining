# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-file IT PMO Kanban board for a fictitious bank, themed as an 8-bit platformer ("PMO Quest"), deployed to GitHub Pages: everything lives in `index.html` (inline `<style>`, markup, and `<script>`). There is no build, package manager, linter, or test suite. Run it by opening `index.html` directly in a browser (file://); verify changes in the browser (Playwright works well: the game exposes `window.__stage` for tests). The theme comes from the `ui-ux-pro-max` skill's Pixel Art style; art is original (no Nintendo characters or assets).

## Hard constraints (from the original spec)

- Vanilla HTML/CSS/JS only. No frameworks, no external resources (fonts, CDNs, images); the only permitted URL is the FormSubmit endpoint.
- No persistence of any kind: no `localStorage`, `sessionStorage`, `IndexedDB`, or cookies. The board intentionally reseeds on every load, and the UI says so.
- No `!important`, no `alert()`/`confirm()` (use inline validation, inline "Delete? Yes / No", and toasts).
- No real UOB logo or branding. The UI uses a neutral "IT PMO" wordmark. Task IDs deliberately keep the specified `UOB-ITPM-####` format (`formatId()`), while the email subject in `notifyNewTask()` is the neutral `[IT PMO]`.
- All user-supplied strings must go through `escapeHtml()` before being put in HTML.

## Architecture

The `<script>` is organised in commented sections: CONFIG, STATE, HELPERS, SEED, FILTERING, RENDERING, ACTIONS, TOASTS, FORMSUBMIT, FORM, EVENTS, INIT.

- **Single source of truth:** the `state` object (`tasks`, `filters`, `ui`, `counter`). Transient UI state (`ui.confirmDeleteId`, `ui.moveOpenId`, `ui.dragId`, `ui.submitting`) lives in state too, so rendering is state-driven.
- **Render flow:** actions (`addTask`, `moveTask`, `deleteTask`) mutate `state`, then call `renderBoard()`, which rebuilds all columns from `applyFilters()` output via `renderCard()` and refreshes counts and the summary strip. Because the DOM is rebuilt, `restoreFocus()` / `focusCard()` re-focus the relevant control after a render.
- **Events:** the board uses delegation (`handleBoardClick`, `setupDragAndDrop`). Native HTML5 DnD (dragstart/dragover/dragleave/drop/dragend) calls `moveTask()`. The "Move ▸" menu on each card is the keyboard-accessible alternative and must keep working alongside DnD.
- **Add Task form:** `validateForm()` writes inline errors per field, `handleSubmit()` adds the card optimistically, then awaits `notifyNewTask()` while the button shows "Sending…". A failed notification only produces a warning toast and must never break or roll back the board.
- **FormSubmit:** `FORMSUBMIT_ENDPOINT` (top of the script, line ~413) is the one place the notification email address goes. It needs one-time activation: the first submission triggers a confirmation email to that address. Until the placeholder is replaced and activated, the warning toast is expected.
- **Seed data:** `seedTasks()` computes dates relative to today via `isoDate(offset)`, so some tasks are always overdue. `state.counter` continues from the seeds, so the first new ID is `UOB-ITPM-0009`.
- **Layout:** four-column grid on desktop, two columns between 768px and ~1100px, stacked below 768px.
- **Playable stage (`setupStage()` IIFE at the end of the script):** a Play button starts a keyboard-driven runner (walk/sprint with acceleration and friction, variable-height jump). Bricks and the four "!" blocks are entries in a `solids` list used for AABB collision (y measured up from the ground). Bumping a "!" block from below calls `openForm(status)` for that column. Keys are only captured while playing and the stage is focused (never hijack typing or Tab); Esc stops. The "!" blocks are real buttons so every action also works without playing. Keep the world responsive: fewer/lower bricks when the stage is under 700px wide.
- **Dialog:** `handleSubmit()` adds the card optimistically, then closes the dialog in `finally` after the (8s-timeout) FormSubmit call settles.
