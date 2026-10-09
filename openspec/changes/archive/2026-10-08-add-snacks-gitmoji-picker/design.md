# Design

## Context

Greenfield plugin, no existing code. See `proposal.md` for motivation. The
reference implementation (`olacin/telescope-gitmoji.nvim`) splits concerns
into `picker.lua` (Telescope picker wiring), `actions.lua` (default commit
action), `emojis.lua` (static data), and `frecency.lua` (usage-based
re-ranking persisted to a JSON file under `stdpath("data")`). This design
keeps that separation but swaps the Telescope picker/sorter/finder calls for
a single `Snacks.picker(...)` call.

## Goals / Non-Goals

**Goals:**
- Match the reference plugin's UX (list → fuzzy filter → select → type
  title → commit) using `Snacks.picker` + `Snacks.input` instead of
  Telescope.
- Add the scratch-buffer commit flow as an opt-in alternative to the
  single-line input, using `Snacks.scratch`.
- Keep the gitmoji dataset easy to refresh from gitmoji.dev, mirroring the
  reference plugin's `scripts/update.py` approach.

**Non-Goals:**
- No Telescope compatibility shim or dual-backend support — this plugin only
  targets `snacks.nvim`.
- No change to the on-disk frecency data format from the reference plugin
  beyond what's needed to work standalone (it is not shared with
  `telescope-gitmoji.nvim`; this plugin uses its own data file).
- No support for amending existing commits or other git operations beyond a
  plain `commit`.

## Decisions

- **Module layout**: `lua/snacks-gitmoji/{init,config,emojis,picker,actions,frecency}.lua`,
  mirroring the reference plugin's file boundaries so the port stays easy to
  diff against upstream gitmoji data updates. `init.lua` holds `setup()` and
  `gitmoji()`; `config.lua` holds the merged default config table.
- **Picker construction**: use `Snacks.picker({ source = "gitmoji", items = {...},
  format = function(item) ... end, confirm = function(picker, item) ... end })`
  rather than a dynamic finder — the gitmoji list is small and static per
  session (only its sort order changes), so a plain `items` table is simpler
  than wiring a custom finder, and `Snacks.picker`'s own matcher provides the
  fuzzy filtering for free. Each item's `text` field is the string used for
  matching/sorting (built as `"<code> <description>"`); `item.value` carries
  the full gitmoji record (`emoji`, `code`, `description`) for the action.
- **Frecency as `sort`**: rather than re-sorting the static `emojis` table in
  place (as the reference plugin does), expose the frecency scores through
  the picker's `sort` config so re-ranking composes with the picker's own
  fuzzy-match scoring instead of fighting it. Frecency persistence reuses the
  reference plugin's algorithm (bucketed recency weights × count, JSON file
  under `vim.fn.stdpath("data")`), isolated in `frecency.lua` so it can be
  unit-tested without a picker instance.
- **Commit execution**: keep the reference plugin's fugitive-detection
  one-liner (`vim.g.loaded_fugitive` truthy → `:G commit`, else `:!git
  commit`) unchanged — it's a small, well-understood compatibility shim and
  changing it isn't in scope.
- **Scratch flow parsing**: read the scratch buffer's lines with
  `vim.api.nvim_buf_get_lines` on the scratch window's hide/close autocmd
  (`Snacks.scratch` already autowrites/hides on leave); line 1 is the title,
  lines 2+ joined (skipping a single leading blank separator line) are the
  body. Empty title (after trimming) aborts without committing. This keeps
  the body optional: a title-only buffer still commits with just `-m
  "<title>"`.
- **Config surface**: `setup(opts)` merges into defaults via
  `vim.tbl_deep_extend("force", defaults, opts or {})`; recognized keys are
  `action` (function) and `use_scratch` (boolean, default `false`). When
  `use_scratch = true`, the internal default action is swapped for the
  scratch-based one unless the consumer also supplied a custom `action`, in
  which case the custom action always wins (same precedence as the
  reference plugin's `action` override).

## Risks / Trade-offs

- [`Snacks.scratch()` autowrites/hides rather than exposing a dedicated
  "on close" event] → Mitigate by hooking the scratch window's buffer
  `BufHidden`/`BufWipeout` autocmd (or the `win_by_ft`/`keys` close handler
  Snacks exposes) scoped to that one scratch buffer handle, verified in a
  manual test, so the commit fires exactly once and not on every autowrite.
- [Static `items` list can't show a live-updating frecency reorder while the
  picker is open without re-running the picker] → Acceptable: order is
  computed once at open time, matching the reference plugin's own behavior
  (it also sorts once before `:find()`).
- [No automated Neovim integration test harness in this change] → Mitigate
  by keeping `frecency.lua`'s scoring function pure (no picker/UI
  dependency) so it can be unit-tested with plain Lua/busted; picker/action
  wiring is verified manually per `tasks.md`.

## Open Questions

(none — scope, approach, and task breakdown are resolved above)
