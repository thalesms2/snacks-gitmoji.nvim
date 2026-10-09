# CLAUDE.md

Guidance for Claude Code (or any AI agent) working in this repository.

## What this project is

`snacks-gitmoji.nvim` — a Neovim plugin that opens a
[`Snacks.picker`](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md)
listing the full [gitmoji](https://gitmoji.dev/) set, lets the user pick one,
then prompts for a commit title (via `Snacks.input`) or, if configured, a
full title+body via a `Snacks.scratch` buffer, and runs `git commit`.

It is a from-scratch, Snacks-native reimplementation of
[`olacin/telescope-gitmoji.nvim`](https://github.com/olacin/telescope-gitmoji.nvim)
(MIT), which does the same thing on top of `telescope.nvim` instead of
`snacks.nvim`. The gitmoji dataset and the frecency (usage-based ranking)
algorithm are ported from that project; the picker/input/scratch wiring is
new.

## Tech stack

- Pure Lua, Neovim plugin (no build step).
- Target: Neovim >= 0.9.
- Hard runtime dependency: `folke/snacks.nvim` (`picker`, `input`, `scratch`
  modules — all enabled by Snacks' defaults).
- Optional soft dependency: `tpope/vim-fugitive` (detected via
  `vim.g.loaded_fugitive`; commits run through `:G commit` when present,
  otherwise through `vim.fn.system({"git", "commit", ...})`, no shell).
- Tests: `tests/*_spec.lua`, run with `plenary.nvim`'s busted-style runner
  (`PlenaryBustedDirectory`). No CI is wired up yet.
- Formatting: `stylua` (config in `.stylua.toml`, 2-space indent).

## Layout

```
lua/snacks-gitmoji/
  init.lua      -- public API: setup(opts), gitmoji()
  config.lua    -- default config, setup() merge, resolve_action()
  picker.lua    -- builds the Snacks.picker call (items, format, confirm)
  actions.lua   -- default commit flows: single-line input vs. scratch buffer
  emojis.lua    -- static gitmoji dataset (emoji, code, description)
  frecency.lua  -- usage-based scoring, persisted to stdpath("data")
plugin/
  snacks-gitmoji.lua -- :SnacksGitmoji user command (guarded, loads once)
tests/
  frecency_spec.lua  -- plenary/busted unit tests for frecency.lua
openspec/
  changes/add-snacks-gitmoji-picker/ -- proposal, specs, design, tasks for
                                         this plugin's initial build
```

## Public API

```lua
require("snacks-gitmoji").setup({
  action = nil,        -- fun(entry: snacks.picker.Item) — overrides everything below
  use_scratch = false, -- true => compose title+body in a Snacks.scratch() buffer
})

require("snacks-gitmoji").gitmoji(opts) -- opts forwarded to Snacks.picker()
```

`:SnacksGitmoji` is a thin wrapper around `gitmoji()`.

Precedence: an explicit `action` always wins; otherwise `use_scratch`
chooses between `actions.commit_with_input` (default) and
`actions.commit_with_scratch`.

## Conventions / things to know before editing

- **Picker item shape**: each `snacks.picker.Item` built in `picker.lua` has
  `value = { emoji, code, description }` (the gitmoji record) and
  `text = "<code> <description>"` (what the fuzzy matcher filters against).
  Actions receive the full item and read `entry.value.emoji` etc.
- **Why `score_add`, not `score`**: `Snacks.picker`'s matcher skips sorting
  entirely while the search prompt is empty (`matcher.sort_empty = false`
  by default), so frecency ranking for the *empty-prompt* case is done by
  pre-sorting the `items` array in `picker.lua` before it's ever handed to
  the picker. `score_add` is only there to blend frecency into the
  *fuzzy-match* ranking once the user starts typing — see
  `openspec/changes/add-snacks-gitmoji-picker/design.md` (Decisions) for the
  full reasoning. Don't "simplify" this to a plain `sort.fields` config
  without re-reading that section first; it was tried and doesn't rank
  correctly on open.
- **Scratch commit flow has no dedicated "on close" event**: `Snacks.scratch`
  only exposes a `BufHidden` autowrite autocmd. `actions.commit_with_scratch`
  attaches its own `once = true` autocmd on `{"BufHidden", "BufWipeout"}`
  scoped to that buffer to read the lines and fire the commit exactly once,
  then deletes the temp scratch file/meta pair it created. If you change how
  the scratch buffer is opened, make sure this still fires exactly once.
- **Git execution is shell-free on the non-fugitive path**: the fallback
  commit uses `vim.fn.system({"git", "commit", "-m", ...})` (argv list, no
  shell), not a `:!git ...` Ex command — this avoids shell-quoting bugs and
  injection from commit titles/bodies containing quotes or special
  characters. Keep it that way; don't switch back to `vim.cmd(":!git ...")`
  for the non-fugitive branch.
- **Frecency data file**: `stdpath("data")/snacks-gitmoji-data.json`. This
  is a different file from `telescope-gitmoji.nvim`'s own
  `gitmoji-data.json` — they do not share history, by design (this plugin
  doesn't assume Telescope is even installed).
- **Dataset refresh**: `lua/snacks-gitmoji/emojis.lua` should track
  upstream gitmoji.dev. When refreshing it, diff against
  https://github.com/carloscuesta/gitmoji/blob/master/packages/gitmojis/src/gitmojis.json
  and keep the `emoji` / `code` / `description` field names (don't reuse the
  reference plugin's `value` / `text` names — those were renamed here for
  clarity against `snacks.picker.Item.value`/`.text`).

## Planning workflow (OpenSpec)

This repo uses [OpenSpec](https://github.com/Fission-AI/OpenSpec) for
spec-driven changes (`openspec/` directory, `openspec` CLI installed
globally). `openspec/config.yaml` carries project context used when
authoring new proposals.

- `openspec/changes/add-snacks-gitmoji-picker/` is the change that produced
  this plugin's initial version (proposal → specs → design → tasks, all
  validated with `openspec validate --strict`).
- For the next change: either run `openspec new change "<name>"` directly,
  or use the `/opsx:propose`, `/opsx:apply`, `/opsx:archive` slash commands
  / `openspec-*` skills that `openspec init` installed under `.claude/`.
- Once a change's implementation lands and is verified, archive it with
  `openspec archive <change-name>` so `openspec/specs/` becomes the
  source of truth for current behavior.

## Testing

```bash
# syntax-only sanity check (no nvim needed)
for f in lua/snacks-gitmoji/*.lua plugin/*.lua; do
  luajit -e "assert(loadfile('$f'))" || echo "FAIL: $f"
done

# unit tests (requires plenary.nvim on the runtimepath)
nvim --headless --noplugin -u NONE \
  -c "set rtp+=.,<path-to-plenary.nvim>" \
  -c "runtime plugin/plenary.vim" \
  -c "PlenaryBustedDirectory tests/ { minimal_init = '' }"
```

There is no automated picker/UI test — verifying `picker.lua` and
`actions.lua`'s scratch/input flows end-to-end requires manually driving a
real Neovim + `snacks.nvim` instance (see
`openspec/changes/add-snacks-gitmoji-picker/tasks.md`, section 6).
