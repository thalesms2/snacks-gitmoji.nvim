# Proposal

## Why

Three small UX gaps keep the picker from feeling as fast as it should: there
is no way to commit without a gitmoji prefix (every commit flow assumes an
emoji was picked), the single-line title prompt opens in normal mode so the
user has to press `i` before typing, and the picker always renders alongside
a preview panel that adds visual noise for a list that is just emoji + code +
description. The README also never shows a full `use_scratch = true`
`setup()` example, only a fragment.

## What Changes

- Add a "No emoji" entry pinned to the top of the picker list (above the
  frecency-sorted gitmoji entries) so pressing `<CR>` on the picker's default
  highlight — i.e. opening the picker and confirming immediately — proceeds
  straight to the commit-message flow with no emoji selected or recorded in
  frecency.
- When no emoji was selected, `commit_with_input` and `commit_with_scratch`
  SHALL NOT prefix the commit title (or scratch buffer template) with an
  emoji, and SHALL commit using the title as typed.
- `commit_with_input`'s `Snacks.input()` prompt SHALL enter insert mode
  automatically when it opens, matching the scratch flow's existing
  `startinsert` behavior, so the user can type the title immediately.
- The picker SHALL open without a preview panel — only the emoji/code/
  description list is shown, no split preview pane.
- Update `README.md` with a complete `setup({ use_scratch = true })` example
  (the existing "Scratch action" section currently only shows the one-line
  `setup()` call, not what the resulting buffer/config looks like end to
  end) and document the new no-emoji entry and insert-mode input behavior.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `gitmoji-picker`: add a "No emoji" entry pinned above the frecency-sorted
  list, and the picker opens with no preview panel.
- `gitmoji-commit-input`: the input prompt starts in insert mode, and the
  commit message is unprefixed when no emoji was selected.
- `gitmoji-scratch-commit`: the scratch buffer template is unprefixed (no
  leading emoji line) when no emoji was selected.

## Impact

- `lua/snacks-gitmoji/picker.lua`: inject the "No emoji" sentinel item ahead
  of `build_items()`'s frecency sort, set `preview = false` (or equivalent)
  on the `Snacks.picker()` call, and don't record frecency for the sentinel.
- `lua/snacks-gitmoji/actions.lua`: branch on whether `entry.value.emoji` is
  empty/absent in both `commit_with_input` and `commit_with_scratch`, and add
  `vim.cmd("startinsert")` (scheduled, like the scratch flow already does)
  after opening `Snacks.input()`.
- `lua/snacks-gitmoji/emojis.lua` or `picker.lua`: define the sentinel
  "no emoji" record shape (likely `{ emoji = "", code = "", description =
  "No emoji" }`) consumed by `actions.lua`.
- `README.md`: expand the scratch configuration example and document the
  no-emoji entry and insert-mode behavior.
- `tests/frecency_spec.lua` or a new spec: verify the sentinel item is never
  scored/recorded by frecency.
