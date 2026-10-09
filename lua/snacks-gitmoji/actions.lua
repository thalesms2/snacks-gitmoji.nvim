local M = {}

---Run `git commit` with the given `-m` argument list, preferring
---vim-fugitive's `:G` when it's loaded and falling back to a plain
---(shell-free) `git commit` invocation otherwise.
---@param message_args string[] alternating `-m "..."` pairs, already built
local function run_commit(message_args)
  if vim.g.loaded_fugitive then
    local parts = { "G", "commit" }
    for _, arg in ipairs(message_args) do
      parts[#parts + 1] = arg == "-m" and arg or vim.fn.shellescape(arg)
    end
    vim.cmd(table.concat(parts, " "))
    return
  end

  local cmd = { "git", "commit" }
  vim.list_extend(cmd, message_args)
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("snacks-gitmoji: git commit failed\n" .. output, vim.log.levels.ERROR)
  else
    vim.notify("snacks-gitmoji: " .. vim.trim(output), vim.log.levels.INFO)
  end
end

---@param entry snacks.picker.Item
---@return SnacksGitmoji.Emoji
local function emoji_of(entry)
  return entry.value or entry
end

---Default action: prompt for a one-line commit title with `Snacks.input()`,
---pre-seeded with the selected emoji (or no emoji, when none was selected),
---then commit `<emoji> <title>` (or just `<title>` with no emoji).
---@param entry snacks.picker.Item
function M.commit_with_input(entry)
  local item = emoji_of(entry)
  local has_emoji = item.emoji ~= ""
  Snacks.input({
    prompt = has_emoji and ("Commit message: " .. item.emoji .. " ") or "Commit message: ",
  }, function(title)
    if not title or vim.trim(title) == "" then
      return
    end
    run_commit({ "-m", has_emoji and string.format("%s %s", item.emoji, title) or title })
  end)
  vim.schedule(function()
    vim.cmd("startinsert!")
  end)
end

---Default action when `use_scratch = true`: open a `Snacks.scratch()`
---buffer pre-filled with the emoji on line 1 (or an empty line 1, when no
---emoji was selected) so the user can compose both the commit title (line 1)
---and an optional multi-line body (line 3+). The commit runs when the
---scratch buffer is hidden/closed.
---@param entry snacks.picker.Item
function M.commit_with_scratch(entry)
  local item = emoji_of(entry)
  local has_emoji = item.emoji ~= ""
  local title_prefix = has_emoji and (item.emoji .. " ") or ""
  local scratch_file = vim.fn.tempname() .. "-snacks-gitmoji.gitcommit"

  local win = Snacks.scratch.open({
    name = "SnacksGitmojiCommit",
    ft = "gitcommit",
    file = scratch_file,
    template = title_prefix .. "\n\n",
    autowrite = false,
    win = {
      title = has_emoji and (" New commit " .. item.emoji .. " ") or " New commit ",
      height = 10,
    },
  })

  if not win or not win.buf then
    return
  end

  local buf = win.buf
  local committed = false

  local function finish()
    if committed then
      return
    end
    committed = true

    local lines = vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_lines(buf, 0, -1, false) or {}
    local title = vim.trim(lines[1] or "")

    local body_lines = {}
    for i = 2, #lines do
      if lines[i] ~= "" or #body_lines > 0 then
        body_lines[#body_lines + 1] = lines[i]
      end
    end
    while #body_lines > 0 and body_lines[#body_lines] == "" do
      body_lines[#body_lines] = nil
    end
    local body = vim.trim(table.concat(body_lines, "\n"))

    pcall(os.remove, scratch_file)
    pcall(os.remove, scratch_file .. ".meta")

    if title == "" or title == vim.trim(item.emoji) then
      return
    end

    local message_args = { "-m", title }
    if body ~= "" then
      message_args[#message_args + 1] = "-m"
      message_args[#message_args + 1] = body
    end
    run_commit(message_args)
  end

  vim.api.nvim_create_autocmd({ "BufHidden", "BufWipeout" }, {
    group = vim.api.nvim_create_augroup("snacks_gitmoji_scratch_" .. buf, { clear = true }),
    buffer = buf,
    once = true,
    callback = finish,
  })

  vim.schedule(function()
    if win.win and vim.api.nvim_win_is_valid(win.win) then
      vim.api.nvim_win_set_cursor(win.win, { 1, #title_prefix })
    end
    vim.cmd("startinsert!")
  end)
end

return M
