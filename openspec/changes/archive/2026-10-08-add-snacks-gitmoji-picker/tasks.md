# Tasks

## 1. Project scaffolding

- [x] 1.1 Create the plugin skeleton (`lua/snacks-gitmoji/`, `plugin/`,
      `README.md`, `LICENSE`, `.stylua.toml`) and verify `find . -name
      "*.lua"` shows the expected module files with no syntax errors
      (`luac -p` or `stylua --check`)
- [x] 1.2 Add the gitmoji dataset in `lua/snacks-gitmoji/emojis.lua` ported
      from gitmoji.dev / the reference plugin's list, and verify
      `#require("snacks-gitmoji.emojis")` returns the full set (currently
      73 entries) each with non-nil `emoji`, `code`, `description`

## 2. Picker capability (`gitmoji-picker`)

- [x] 2.1 Implement `lua/snacks-gitmoji/picker.lua` building a
      `Snacks.picker` call from the emoji items (`items`, `format`,
      `confirm`) and verify opening it manually in Neovim shows every
      gitmoji entry with emoji, code, and description
- [x] 2.2 Verify fuzzy-filtering works by typing a query (e.g. `bug`) in the
      picker prompt and confirming the list narrows to matching entries
      (`tests/picker_spec.lua` drives this headlessly against the real
      `snacks.nvim` picker: `picker.input:set("fix a bug")` + `picker:find()`
      surfaces the 🐛 entry on top)
- [x] 2.3 Implement `lua/snacks-gitmoji/frecency.lua` (score persisted to
      `stdpath("data")/snacks-gitmoji-data.json`, `record()` /
      `get_scores()`) and verify with a Lua unit test (plenary/busted) that a
      recorded emoji sorts above one never recorded (`tests/frecency_spec.lua`)
- [x] 2.4 Wire frecency scoring into the picker's sort/order (pre-sort
      `items` by frecency for the empty-prompt case; `score_add` blends it
      into fuzzy-match ranking once typing starts — see design.md) and
      verify a just-recorded emoji's score is positive and ranks it first
      among unrecorded entries (`tests/picker_spec.lua`,
      `tests/frecency_spec.lua`)
- [x] 2.5 Verify confirming an entry closes the picker before calling the
      action and records frecency (`tests/picker_spec.lua`:
      "invokes the configured action with the confirmed entry and records
      frecency"); cancelling the picker is Snacks.picker's own built-in
      `cancel`/`<esc>` action, which this plugin does not override, so no
      action runs on cancel by construction

## 3. Default commit-input capability (`gitmoji-commit-input`)

- [x] 3.1 Implement `lua/snacks-gitmoji/actions.lua` default action using
      `Snacks.input()` seeded with the selected emoji in the prompt text,
      and verify confirming a title runs `git commit -m "<emoji> <title>"`
      — verified both headlessly (`tests/actions_spec.lua`) and against a
      real throwaway git repo (`git log -1 --format=%B` ==
      `"✅ real end-to-end commit"`)
- [x] 3.2 Implement the `vim.g.loaded_fugitive` branch (`:G commit` vs a
      shell-free `vim.fn.system({"git","commit",...})`) and verify both
      branches in `tests/actions_spec.lua`
- [x] 3.3 Verify cancelling the title input (nil or blank result) aborts
      without running any commit command (`tests/actions_spec.lua`)
- [x] 3.4 Support a custom `action` override via `setup({ action = ... })`
      and verify the custom function receives the same entry shape as the
      default action and is called instead of it (`tests/picker_spec.lua`
      uses a custom `action` throughout; `config.resolve_action()` picks it
      over both built-ins)

## 4. Scratch commit capability (`gitmoji-scratch-commit`)

- [x] 4.1 Add `use_scratch` to `lua/snacks-gitmoji/config.lua` defaults
      (`false`) and implement the scratch-based action in
      `lua/snacks-gitmoji/actions.lua` opening `Snacks.scratch()` pre-filled
      with `"<emoji> "` on line 1 and a blank line 2
- [x] 4.2 Implement the close/hide handler (`BufHidden`/`BufWipeout`,
      `once = true`) that reads buffer lines, treats line 1 as the title and
      remaining non-empty lines as the body, and verify closing the scratch
      buffer with a title+body runs `git commit -m "<title>" -m "<body>"` —
      verified both headlessly (`tests/actions_spec.lua`) and against a real
      throwaway git repo (`git log -1` subject/body matched exactly)
- [x] 4.3 Verify an emptied title line (or a title line left as just the
      emoji) aborts the commit, and that `vim.g.loaded_fugitive` is honored
      the same way as the default flow (task 3.2) — same `run_commit` helper
      is shared by both actions, covered by `tests/actions_spec.lua`
- [x] 4.4 Verify `setup({ use_scratch = true })` makes
      `config.resolve_action()` return `actions.commit_with_scratch` by
      default, and that an explicit custom `action` still takes precedence
      (unit-asserted in the manual smoke test during development; see
      `lua/snacks-gitmoji/config.lua`'s `resolve_action()`)

## 5. Public API and docs

- [x] 5.1 Implement `lua/snacks-gitmoji/init.lua` (`setup(opts)`,
      `gitmoji()`) and `plugin/snacks-gitmoji.lua` (`:SnacksGitmoji` user
      command, guarded by `vim.g.loaded_snacks_gitmoji`), and verify
      `require("snacks-gitmoji").gitmoji()` opens the picker in a clean
      Neovim instance with the plugin + snacks.nvim on `rtp`
      (`tests/picker_spec.lua`)
- [x] 5.2 Write `README.md` covering installation (lazy.nvim/vim-plug),
      usage, and the full configuration table (`action`, `use_scratch`); all
      Lua snippets were cross-checked against the real, tested API surface
- [x] 5.3 Write `CLAUDE.md` describing the project for future AI-assisted
      sessions, matching the final module layout and public API

## 6. Integration verification

- [x] 6.1 Exercise the end-to-end flow against a real throwaway git
      repository (`git init` + staged file) for both `use_scratch = false`
      and `use_scratch = true`: picker → filter → select → type title (and
      body, for scratch) → real `git commit` runs, and
      `git log -1 --format=%B` matched the expected emoji-prefixed message
      in both cases (`✅ real end-to-end commit`, and
      `✨ add greeting` / `Appends world to file.txt.`)
