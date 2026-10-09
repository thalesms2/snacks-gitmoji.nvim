vim.opt.rtp:prepend("/tmp/snacks.nvim")
require("snacks")

local actions = require("snacks-gitmoji.actions")

describe("snacks-gitmoji.actions.commit_with_input", function()
  local orig_system, orig_cmd, orig_input

  before_each(function()
    orig_system = vim.fn.system
    orig_cmd = vim.cmd
    orig_input = Snacks.input
    vim.g.loaded_fugitive = nil
  end)

  after_each(function()
    vim.fn.system = orig_system
    vim.cmd = orig_cmd
    Snacks.input = orig_input
    vim.g.loaded_fugitive = nil
  end)

  it("seeds the input prompt with the selected emoji", function()
    local captured
    Snacks.input = function(opts, on_confirm)
      captured = opts
      on_confirm(nil)
    end
    actions.commit_with_input({ value = { emoji = "🐛", code = ":bug:", description = "Fix a bug." } })
    assert.is_true(captured.prompt:find("🐛", 1, true) ~= nil)
  end)

  it("runs git commit with the emoji-prefixed title (no fugitive)", function()
    local commits = {}
    vim.fn.system = function(cmd)
      table.insert(commits, cmd)
      return ""
    end
    Snacks.input = function(_, on_confirm)
      on_confirm("fix off-by-one")
    end
    actions.commit_with_input({ value = { emoji = "🐛", code = ":bug:", description = "x" } })
    assert.equals(1, #commits)
    assert.same({ "git", "commit", "-m", "🐛 fix off-by-one" }, commits[1])
  end)

  it("aborts without committing when the title is nil", function()
    local commits = {}
    vim.fn.system = function(cmd)
      table.insert(commits, cmd)
      return ""
    end
    Snacks.input = function(_, on_confirm)
      on_confirm(nil)
    end
    actions.commit_with_input({ value = { emoji = "🐛", code = ":bug:", description = "x" } })
    assert.equals(0, #commits)
  end)

  it("aborts without committing when the title is blank", function()
    local commits = {}
    vim.fn.system = function(cmd)
      table.insert(commits, cmd)
      return ""
    end
    Snacks.input = function(_, on_confirm)
      on_confirm("   ")
    end
    actions.commit_with_input({ value = { emoji = "🐛", code = ":bug:", description = "x" } })
    assert.equals(0, #commits)
  end)

  it("seeds the input prompt with no emoji text for the no-emoji entry", function()
    local captured
    Snacks.input = function(opts, on_confirm)
      captured = opts
      on_confirm(nil)
    end
    actions.commit_with_input({ value = { emoji = "", code = "", description = "No emoji" } })
    assert.equals("Commit message: ", captured.prompt)
  end)

  it("runs git commit with no emoji prefix for the no-emoji entry", function()
    local commits = {}
    vim.fn.system = function(cmd)
      table.insert(commits, cmd)
      return ""
    end
    Snacks.input = function(_, on_confirm)
      on_confirm("tidy up CI config")
    end
    actions.commit_with_input({ value = { emoji = "", code = "", description = "No emoji" } })
    assert.equals(1, #commits)
    assert.same({ "git", "commit", "-m", "tidy up CI config" }, commits[1])
  end)

  it("enters insert mode after opening the input prompt", function()
    local cmds_run = {}
    Snacks.input = function(_, on_confirm)
      on_confirm(nil)
    end
    vim.cmd = setmetatable({}, {
      __call = function(_, c)
        table.insert(cmds_run, c)
      end,
      __index = orig_cmd,
    })
    actions.commit_with_input({ value = { emoji = "🐛", code = ":bug:", description = "x" } })
    vim.wait(50)
    local found = false
    for _, c in ipairs(cmds_run) do
      if c == "startinsert!" then
        found = true
      end
    end
    assert.is_true(found)
  end)

  it("uses :G commit when vim-fugitive is loaded", function()
    vim.g.loaded_fugitive = 1
    Snacks.input = function(_, on_confirm)
      on_confirm("add thing")
    end
    local cmds_run = {}
    vim.cmd = setmetatable({}, {
      __call = function(_, c)
        table.insert(cmds_run, c)
      end,
      __index = orig_cmd,
    })
    actions.commit_with_input({ value = { emoji = "✨", code = ":sparkles:", description = "y" } })
    local found = false
    for _, c in ipairs(cmds_run) do
      if c:match("^G commit") then
        found = true
        assert.is_true(c:find("add thing", 1, true) ~= nil)
      end
    end
    assert.is_true(found)
  end)
end)

describe("snacks-gitmoji.actions.commit_with_scratch", function()
  local orig_system

  before_each(function()
    orig_system = vim.fn.system
  end)

  after_each(function()
    vim.fn.system = orig_system
    pcall(vim.cmd, "silent! %bwipeout!")
  end)

  it("commits title and body on close", function()
    local commits = {}
    vim.fn.system = function(cmd)
      table.insert(commits, cmd)
      return ""
    end
    actions.commit_with_scratch({ value = { emoji = "✨", code = ":sparkles:", description = "x" } })
    vim.wait(50)
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "✨ add dark mode toggle", "", "Adds a settings entry." })
    vim.cmd("close")
    vim.wait(50)
    assert.equals(1, #commits)
    assert.same({ "git", "commit", "-m", "✨ add dark mode toggle", "-m", "Adds a settings entry." }, commits[1])
  end)

  it("aborts when the title line is emptied", function()
    local commits = {}
    vim.fn.system = function(cmd)
      table.insert(commits, cmd)
      return ""
    end
    actions.commit_with_scratch({ value = { emoji = "🐛", code = ":bug:", description = "y" } })
    vim.wait(50)
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
    vim.cmd("close")
    vim.wait(50)
    assert.equals(0, #commits)
  end)

  it("aborts when only the emoji is left on the title line", function()
    local commits = {}
    vim.fn.system = function(cmd)
      table.insert(commits, cmd)
      return ""
    end
    actions.commit_with_scratch({ value = { emoji = "🐛", code = ":bug:", description = "y" } })
    vim.wait(50)
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "🐛" })
    vim.cmd("close")
    vim.wait(50)
    assert.equals(0, #commits)
  end)

  it("commits title and body with no emoji prefix for the no-emoji entry", function()
    local commits = {}
    vim.fn.system = function(cmd)
      table.insert(commits, cmd)
      return ""
    end
    actions.commit_with_scratch({ value = { emoji = "", code = "", description = "No emoji" } })
    vim.wait(50)
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "tidy up CI config", "", "Pins the action versions." })
    vim.cmd("close")
    vim.wait(50)
    assert.equals(1, #commits)
    assert.same({ "git", "commit", "-m", "tidy up CI config", "-m", "Pins the action versions." }, commits[1])
  end)
end)
