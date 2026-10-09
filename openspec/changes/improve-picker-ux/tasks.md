# Tasks

## 1. No-emoji sentinel entry in the picker

- [x] 1.1 Define the "no emoji" sentinel record (`emoji = ""`, `code = ""`,
      `description = "No emoji"`) in `lua/snacks-gitmoji/picker.lua` (or
      `emojis.lua`, whichever keeps the dataset/sentinel separation
      cleanest) and verify it's a plain table matching the shape of
      `SnacksGitmoji.Emoji`
- [x] 1.2 Prepend the sentinel item to the `items` array returned by
      `build_items()`, after the existing frecency `table.sort`, and verify
      with a manual picker open that "No emoji" is always the first row
      regardless of frecency history
- [x] 1.3 In `picker.lua`'s `confirm` callback, skip `frecency.record(...)`
      when the confirmed item is the sentinel (`item.value.emoji == ""`),
      and add/extend a test in `tests/frecency_spec.lua` (or a new
      `tests/picker_spec.lua`) asserting the sentinel is never recorded or
      scored
- [x] 1.4 Verify via `luajit -e "assert(loadfile('lua/snacks-gitmoji/picker.lua'))"`
      and the plenary test run that existing frecency behavior for real
      gitmoji entries is unchanged

## 2. No-emoji handling in the commit actions

- [x] 2.1 In `lua/snacks-gitmoji/actions.lua`, compute
      `local has_emoji = item.emoji ~= ""` in both `commit_with_input` and
      `commit_with_scratch`, and use it to build the `Snacks.input()` prompt
      text / scratch `template` without a leading emoji when `has_emoji` is
      false; verify by manually opening each flow for the sentinel entry and
      confirming no stray emoji or leading space appears
- [x] 2.2 Update the commit message construction in both functions so the
      no-emoji case commits `title` as typed (no `"%s %s"` prefix format),
      and verify by running each flow for the sentinel entry with
      `vim.g.loaded_fugitive` unset and checking the `git log -1` subject
      has no emoji prefix
- [x] 2.3 Verify the existing emoji-prefixed scenarios (`commit_with_input`
      and `commit_with_scratch` for a real entry like "bug") still produce
      `"<emoji> <title>"` commit messages, via manual test or an added
      plenary spec

## 3. Insert mode for the single-line input prompt

- [x] 3.1 In `commit_with_input`, schedule `vim.cmd("startinsert")` after
      `Snacks.input()` opens (mirroring the `vim.schedule(...)` pattern
      already used in `commit_with_scratch`), and verify manually that the
      prompt is immediately editable without pressing `i`

## 4. Remove the picker preview panel

- [x] 4.1 Add the config field that disables `Snacks.picker()`'s preview
      pane (e.g. `preview = false`) to the base config table in
      `picker.lua`'s `M.open()`, and verify manually that opening the
      picker shows no preview split for any highlighted entry
- [x] 4.2 Confirm a caller-supplied `opts.preview` (or equivalent) passed to
      `gitmoji(opts)` still overrides the new default, per
      `vim.tbl_deep_extend("force", ...)` precedence, and note this in the
      README (task 5.2)

## 5. Documentation

- [x] 5.1 Update `README.md`'s "Usage"/"Configuration" sections to document
      the "No emoji" entry (what selecting it does in both the input and
      scratch flows) and the input prompt's new insert-mode-on-open
      behavior
- [x] 5.2 Replace the README's "Scratch action (title + body)" section with
      a complete `setup({ use_scratch = true })` example showing the full
      `require("snacks-gitmoji").setup({...})` call, what the resulting
      scratch buffer looks like (emoji-prefixed and no-emoji cases), and the
      preview-panel-disabled-by-default note from task 4.2; verify by
      reading the rendered section back and confirming every code block is
      copy-pasteable as-is

## 6. Final verification

- [x] 6.1 Run `stylua lua/ plugin/ tests/ --check` and fix any formatting
      drift
- [x] 6.2 Run the full plenary test suite
      (`nvim --headless --noplugin -u NONE -c "set rtp+=.,<path-to-plenary.nvim>" -c "runtime plugin/plenary.vim" -c "PlenaryBustedDirectory tests/ { minimal_init = '' }"`)
      and confirm all specs pass
- [x] 6.3 Manually drive `:SnacksGitmoji` end to end for all four scenarios:
      default input flow with an emoji, default input flow via the no-emoji
      entry, scratch flow with an emoji, scratch flow via the no-emoji
      entry — confirming correct commit messages and no preview panel in
      each case
