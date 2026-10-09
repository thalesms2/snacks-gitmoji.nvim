# snacks-gitmoji.nvim

A [Snacks.picker](https://github.com/folke/snacks.nvim) integration of
[gitmoji](https://gitmoji.dev/), for people who use `snacks.nvim` instead of
Telescope. Inspired by
[olacin/telescope-gitmoji.nvim](https://github.com/olacin/telescope-gitmoji.nvim).

Pick a gitmoji → type the commit title → commit. Optionally, open a
[Snacks.scratch](https://github.com/folke/snacks.nvim/blob/main/docs/scratch.md)
buffer instead, to compose both the title and a multi-line commit body. A
"No emoji" entry is always pinned at the top of the list, so pressing `<CR>`
without picking anything goes straight to the commit-message flow with no
emoji prefix.

## Requirements

- Neovim >= 0.9
- [folke/snacks.nvim](https://github.com/folke/snacks.nvim) with the
  `picker`, `input`, and `scratch` modules enabled (the defaults)
- Optional: [tpope/vim-fugitive](https://github.com/tpope/vim-fugitive) —
  when loaded, commits run through `:G commit` instead of a plain `git
  commit`

## Installation

```lua
-- lazy.nvim
{
  "your-name/snacks-gitmoji.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {},
}
```

```vim
" vim-plug
Plug 'folke/snacks.nvim'
Plug 'your-name/snacks-gitmoji.nvim'
```

## Usage

```
" As a command
:SnacksGitmoji

-- As a Lua function
require("snacks-gitmoji").gitmoji()
```

Bind it to a key, e.g.:

```lua
vim.keymap.set("n", "<leader>gm", function()
  require("snacks-gitmoji").gitmoji()
end, { desc = "Gitmoji commit" })
```

The picker shows only the emoji, its `:code:`, and its description — there
is no preview panel. The first entry is always "No emoji": confirming it
(e.g. pressing `<CR>` right after opening the picker, before typing or
moving the selection) skips the emoji entirely and goes straight to the
commit-message flow, and it is never recorded in the frecency history below.

## Configuration

```lua
require("snacks-gitmoji").setup({
  -- Replace the default commit flow entirely. Receives the picker entry:
  --   entry.value = { emoji = "🐛", code = ":bug:", description = "Fix a bug." }
  -- entry.value.emoji is "" when the user picked the "No emoji" entry.
  action = nil,

  -- When true, opens a Snacks.scratch() buffer (pre-filled with the emoji
  -- on line 1) to compose the commit title *and* a multi-line body,
  -- instead of the default single-line Snacks.input() prompt.
  use_scratch = false,
})
```

An explicit `action` always takes precedence over `use_scratch`.

The picker itself opens with no preview panel by default
(`layout = { preview = false }`). Pass your own `layout` through
`gitmoji(opts)` (e.g. `gitmoji({ layout = { preview = true } })`) if you want
it back — any key you set in `opts` overrides the plugin's default.

### Default action (single-line input)

```lua
require("snacks-gitmoji").setup({
  action = function(entry)
    local emoji = entry.value.emoji -- "" when the "No emoji" entry was picked
    local prompt = emoji ~= "" and ("Commit message: " .. emoji .. " ") or "Commit message: "
    Snacks.input({ prompt = prompt }, function(title)
      if not title or vim.trim(title) == "" then
        return
      end
      local message = emoji ~= "" and string.format("%s %s", emoji, title) or title
      local git_tool = vim.g.loaded_fugitive and "G" or "!git"
      vim.cmd(string.format('%s commit -m "%s"', git_tool, message))
    end)
  end,
})
```

This is (a simplified version of) the built-in default: the
`Snacks.input()` prompt always opens in insert mode, so you can start typing
the title immediately — no need to press `i` first.

### Scratch action (title + body)

```lua
require("snacks-gitmoji").setup({ use_scratch = true })
```

Opens a scratch buffer (filetype `gitcommit`) seeded with `"<emoji> "` on
line 1 — or an empty line 1 when the "No emoji" entry was picked. Line 1
becomes the commit title; any remaining non-empty lines become the commit
body. The cursor starts in insert mode at the end of the pre-filled prefix
(or at the very start of the line, for "No emoji"), ready to type. Closing/
hiding the buffer (e.g. `q` or leaving the window) runs the commit. Leaving
the title empty aborts without committing.

For example, selecting the "sparkles" entry opens a buffer whose first line
reads `✨ ` with the cursor right after the space, ready to type the title;
selecting "No emoji" opens the same buffer with an empty first line and the
cursor at its start. Typing a title and an optional body, then closing the
buffer, runs `git commit -m "<title>" -m "<body>"` (with the emoji prefixed
onto `<title>` only when one was selected).

## How ranking works

Gitmoji you select are tracked (count + recency) in
`stdpath("data")/snacks-gitmoji-data.json`, scored like
`telescope-gitmoji.nvim`'s frecency algorithm. With an empty prompt the list
is pre-sorted by that score; once you start typing, the score is blended
additively into `Snacks.picker`'s own fuzzy-match ranking.

## Development

```bash
stylua lua/ plugin/ tests/ --check
nvim --headless --noplugin -u NONE \
  -c "set rtp+=.,<path-to-plenary.nvim>" \
  -c "runtime plugin/plenary.vim" \
  -c "PlenaryBustedDirectory tests/ { minimal_init = '' }"
```

See `openspec/changes/add-snacks-gitmoji-picker/` for the proposal, spec
deltas, design notes, and task breakdown this plugin was built from.

## License

MIT, see [LICENSE](./LICENSE).
