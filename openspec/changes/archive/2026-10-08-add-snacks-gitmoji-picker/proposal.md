# Proposal

## Why

There is no gitmoji picker for Neovim users who have standardized on
`folke/snacks.nvim` instead of `telescope.nvim`. `olacin/telescope-gitmoji.nvim`
provides this workflow (pick a gitmoji, type a commit message, run the
commit) but hard-depends on Telescope. Users who already pull in
`snacks.nvim` for its picker, input, and scratch UI should get the same
workflow without adding Telescope as a second fuzzy-finder dependency.

## What Changes

- Add a new standalone Neovim plugin (`snacks-gitmoji.nvim`) that opens a
  `Snacks.picker` listing the full gitmoji set (emoji, `:code:`, description),
  mirroring the data bundled in `olacin/telescope-gitmoji.nvim`.
- Selecting an emoji in the picker opens a `Snacks.input()` prompt pre-seeded
  with the emoji so the user types only the commit title, then runs
  `git commit -m "<emoji> <title>"` (using `vim-fugitive`'s `:G` when loaded,
  falling back to `:!git`).
- Add a `setup()` configuration option (`use_scratch = true`) that, when
  enabled, replaces the single-line input step with a `Snacks.scratch()`
  buffer pre-filled with an emoji-prefixed title line and a blank body, so the
  user can edit both the commit title and the full commit message body before
  committing (`git commit -m "<title>" -m "<body>"`).
- Expose `require("snacks-gitmoji").gitmoji()` as the Lua entrypoint and a
  `:SnacksGitmoji` user command, plus a `setup(opts)` function for
  configuration (custom `action`, `use_scratch`, keymaps are left to the
  consumer's own config).
- Port frecency-based sorting (most/recently used emoji float to the top) as
  an internal implementation detail of the picker's item ordering, consistent
  with the reference plugin's behavior.

## Capabilities

### New Capabilities
- `gitmoji-picker`: Snacks.picker UI that lists gitmoji entries (emoji, code,
  description), fuzzy-filterable, frecency-sorted, and on selection hands the
  chosen emoji to a configurable commit action.
- `gitmoji-commit-input`: default commit action that opens a `Snacks.input()`
  single-line prompt for the commit title and runs `git commit -m` with the
  emoji prefix, auto-detecting vim-fugitive.
- `gitmoji-scratch-commit`: opt-in configuration (`use_scratch`) that swaps
  the single-line input for a `Snacks.scratch()` buffer where the user edits
  both the commit title (first line) and commit message body (remaining
  lines) before the commit runs.

### Modified Capabilities
(none — this is a greenfield project)

## Impact

- New repo content only; no existing code is touched (empty working
  directory at `/Users/thales.sato/gh/okinawa_higashi`).
- Adds a hard runtime dependency on `folke/snacks.nvim` (picker, input, and
  scratch modules) and an optional soft dependency on `vim-fugitive` for the
  `:G commit` integration.
- No breaking changes.
