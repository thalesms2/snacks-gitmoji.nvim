# Design

## Context

See proposal.md - Why. The picker list is built by `picker.lua`'s
`build_items()`, which turns `emojis.lua`'s static dataset into
`snacks.picker.Item`s, blends in frecency (`frecency.lua`), and pre-sorts for
the empty-prompt case (see the existing "Why `score_add`, not `score`"
convention in CLAUDE.md — that sort/score mechanism is unchanged by this
design). `actions.lua` holds the two built-in post-selection flows
(`commit_with_input`, `commit_with_scratch`), both of which currently assume
`item.emoji` is always a non-empty string.

## Goals / Non-Goals

**Goals:**
- Let a user skip the emoji entirely via a predictable, always-at-the-top
  picker entry, without touching the fuzzy-match/frecency sort logic for
  real gitmoji entries.
- Make the single-line input flow start in insert mode, matching the scratch
  flow's existing behavior.
- Drop the picker's preview panel.
- Give the README a complete scratch-mode example.

**Non-Goals:**
- Changing frecency scoring/sorting for actual gitmoji entries.
- Adding a way to toggle the preview panel back on via config — this change
  removes it outright, per the request.
- Changing the custom `action` override path — consumers with their own
  `action` are unaffected by all four changes except insofar as the picker
  item shape gains an always-present "no emoji" sentinel entry.

## Decisions

### Represent "no emoji" as a sentinel picker item, not a separate code path
Model it as a regular `snacks.picker.Item` with
`value = { emoji = "", code = "", description = "No emoji" }`, prepended to
the `items` array after `build_items()` sorts the real entries, rather than
special-casing "nil selection" in `picker.lua`'s `confirm` callback.

- **Alternative considered**: treat `confirm(picker, nil)` (no highlighted
  item) as "no emoji". Rejected — `Snacks.picker` always has a highlighted
  item once the list is non-empty, so `item` is realistically never `nil` on
  confirm; building a dedicated code path for a case that doesn't occur in
  practice would be dead logic, and a real item is also easier to keep
  visible to the user as a reminder that "no emoji" is intentionally
  selectable, not a fallback.
- **Alternative considered**: filter the sentinel out of `frecency.record()`
  by emoji key. Rejected in favor of simply never calling `frecency.record`
  for it in `picker.lua`'s `confirm` — simpler and keeps `frecency.lua`
  unaware of the sentinel's existence at all.
- The sentinel is prepended *after* `build_items()`'s `table.sort`, so it
  never participates in frecency comparison and is always first regardless
  of query (for the empty-prompt case). When the user types a query, Snacks'
  own fuzzy matcher will rank/filter the sentinel's `text` (e.g. `"No
  emoji"`) like any other entry's text — consistent with the "No emoji entry
  is unaffected by filtering" scenario in the `gitmoji-picker` spec delta.

### `actions.lua` branches on `item.emoji == ""`
Both `commit_with_input` and `commit_with_scratch` already compute
`item.emoji` once up front; add a single `local has_emoji = item.emoji ~= ""`
and use it to:
- build the `Snacks.input()` prompt text (`"Commit message: "` vs.
  `"Commit message: <emoji> "`),
- build the scratch `template` (`""` vs. `item.emoji .. " "`),
- build the final commit title (`title` vs. `string.format("%s %s",
  item.emoji, title)`).

No new parameter or config flag is needed — the sentinel's empty-string
emoji is itself the signal.

### Insert mode for `commit_with_input`
Reuse the same pattern `commit_with_scratch` already uses: schedule
`vim.cmd("startinsert")` after `Snacks.input()` opens. `Snacks.input()`
returns before its window/buffer is guaranteed ready in the same tick (same
reasoning as the existing scratch flow's `vim.schedule(...)` wrapper), so the
`startinsert` call is scheduled the same way for consistency, not because
`Snacks.input()` requires it for a different reason.

### Preview panel removed via `Snacks.picker()` config, not per-item
Pass whatever `Snacks.picker()`'s config exposes for disabling the preview
split (e.g. a `preview = false` / layout override field) in the base config
table in `picker.lua`'s `M.open()`, merged the same way `opts` already is.
This stays a one-line config change; it does not require a custom `format`
or layout definition.

## Risks / Trade-offs

- [Risk] A consumer's custom `opts` passed to `gitmoji(opts)` could already
  set a preview-related field, and `vim.tbl_deep_extend("force", base, opts)`
  means `opts` wins — so a consumer could still turn the preview back on
  intentionally. → Acceptable: this mirrors how every other default in
  `picker.lua` is already overridable via `opts`, and the proposal only
  asks for a new *default*, not a hard lock.
- [Risk] A consumer's custom `action` function assumes `entry.value.emoji`
  is always non-empty (e.g. indexes into gitmoji metadata by emoji). →
  Mitigation: document the sentinel's shape (`emoji = ""`) in the README
  next to the `action` override example, so custom actions can check for it
  the same way the built-in ones now do.
- [Risk] Confirming the sentinel still calls `config.resolve_action()`,
  which could be a fully custom `action` — that custom action now
  occasionally receives an empty-emoji entry it wasn't written to expect. →
  Mitigation: same as above (README note); this is a documentation fix, not
  a code guard, since the plugin cannot know what an arbitrary custom
  `action` expects.
