# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Two single-file static pages deployed to GitHub Pages: `index.html` is the Northbeam Software landing page (hero, three testimonials, enquiry form, designed with the `ui-ux-pro-max` skill), and `kanban/index.html` is the IT PMO Kanban board for a fictitious bank. Each has inline `<style>`, markup, and `<script>`. There is no build, package manager, linter, or test suite. Run either by opening it directly in a browser (file://); verify changes manually in the browser. Everything below the "Hard constraints" heading describes the Kanban board (`kanban/index.html`); the landing page follows the same no-storage, no-external-resources, `escapeHtml()` rules.

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
