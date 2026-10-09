local config = require("snacks-gitmoji.config")

local M = {}

---Configure snacks-gitmoji.
---@param opts? SnacksGitmoji.Config
---@field opts.action? fun(entry: snacks.picker.Item) override the default commit flow
---@field opts.use_scratch? boolean use a Snacks.scratch() buffer for title + body
function M.setup(opts)
  config.setup(opts)
end

---Open the gitmoji picker.
---@param opts? snacks.picker.Config forwarded to `Snacks.picker()`
function M.gitmoji(opts)
  if not package.loaded["snacks"] then
    local ok = pcall(require, "snacks")
    if not ok then
      error("snacks-gitmoji.nvim requires folke/snacks.nvim - https://github.com/folke/snacks.nvim")
    end
  end
  require("snacks-gitmoji.picker").open(opts)
end

return M
