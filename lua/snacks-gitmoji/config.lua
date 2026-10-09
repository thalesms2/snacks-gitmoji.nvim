local actions = require("snacks-gitmoji.actions")

local M = {}

---@class SnacksGitmoji.Config
---@field action? fun(entry: snacks.picker.Item) overrides the default commit flow entirely
---@field use_scratch? boolean use a `Snacks.scratch()` buffer for title+body instead of a single-line input
local defaults = {
  action = nil,
  use_scratch = false,
}

---@type SnacksGitmoji.Config
M.options = vim.deepcopy(defaults)

---Resolve the action to invoke on selection: an explicit `action` always
---wins; otherwise `use_scratch` picks between the two built-in flows.
---@return fun(entry: snacks.picker.Item)
function M.resolve_action()
  if M.options.action then
    return M.options.action
  end
  if M.options.use_scratch then
    return actions.commit_with_scratch
  end
  return actions.commit_with_input
end

---@param opts? SnacksGitmoji.Config
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

return M
