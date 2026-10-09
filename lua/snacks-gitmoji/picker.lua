local emojis = require("snacks-gitmoji.emojis")
local frecency = require("snacks-gitmoji.frecency")
local config = require("snacks-gitmoji.config")

local M = {}

---Sentinel entry for "skip the emoji": always pinned above the
---frecency-sorted list and never recorded/scored by frecency.
---@type SnacksGitmoji.Emoji
M.NO_EMOJI = { emoji = "", code = "", description = "No emoji" }

---@return snacks.picker.finder.Item[]
local function build_items()
  local scores = frecency.get_scores()
  local items = {}
  for idx, entry in ipairs(emojis) do
    items[idx] = {
      value = entry,
      text = entry.code .. " " .. entry.description,
      -- additive bonus so frecency composes with the fuzzy match score
      -- once the user types a query (see openspec design.md - Decisions)
      score_add = scores[entry.emoji] or 0,
      _original_idx = idx,
    }
  end

  -- Snacks.picker skips sorting entirely while the prompt is empty
  -- (`matcher.sort_empty = false`), so pre-sort by frecency here: this is
  -- what ranks a recently/frequently used emoji first before any typing.
  -- Ties keep gitmoji.dev's own ordering via the `_original_idx` tiebreaker
  -- (table.sort is not stable).
  table.sort(items, function(a, b)
    if a.score_add ~= b.score_add then
      return a.score_add > b.score_add
    end
    return a._original_idx < b._original_idx
  end)

  -- Prepended after the sort so it's always first for the empty-prompt
  -- case, without ever participating in frecency comparison (see
  -- openspec design.md - Decisions).
  table.insert(items, 1, {
    value = M.NO_EMOJI,
    text = M.NO_EMOJI.description,
  })

  return items
end

---Open the gitmoji picker.
---@param opts? snacks.picker.Config
function M.open(opts)
  opts = opts or {}

  Snacks.picker(vim.tbl_deep_extend("force", {
    source = "gitmoji",
    title = "Gitmoji",
    items = build_items(),
    -- only the emoji/code/description list is shown, no preview split
    -- (see openspec design.md - Decisions)
    layout = { preview = false },
    format = function(item)
      if item.value.emoji == "" then
        return { { item.value.description, "SnacksPickerDesc" } }
      end
      return {
        { item.value.emoji .. " ", "SnacksPickerLabel" },
        { item.value.description, "SnacksPickerDesc" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      if item.value.emoji ~= "" then
        frecency.record(item.value.emoji)
      end
      config.resolve_action()(item)
    end,
  }, opts))
end

return M
