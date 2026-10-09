vim.opt.rtp:prepend("/tmp/snacks.nvim")
require("snacks")

local tmp_data_dir = vim.fn.tempname()
vim.fn.mkdir(tmp_data_dir, "p")
local real_stdpath = vim.fn.stdpath
vim.fn.stdpath = function(what)
  if what == "data" then
    return tmp_data_dir
  end
  return real_stdpath(what)
end

local gitmoji = require("snacks-gitmoji")
local config = require("snacks-gitmoji.config")

describe("snacks-gitmoji picker", function()
  after_each(function()
    pcall(function()
      Snacks.picker.get({ source = "gitmoji" })[1]:close()
    end)
    config.setup({})
  end)

  it("lists every bundled gitmoji entry plus the no-emoji entry", function()
    config.setup({ action = function() end })
    gitmoji.gitmoji()
    local picker = Snacks.picker.get({ source = "gitmoji" })[1]
    assert.is_not_nil(picker)
    vim.wait(500, function()
      return picker:count() > 0
    end)
    assert.equals(#require("snacks-gitmoji.emojis") + 1, picker:count())
  end)

  it("fuzzy-filters by description", function()
    config.setup({ action = function() end })
    gitmoji.gitmoji()
    local picker = Snacks.picker.get({ source = "gitmoji" })[1]
    vim.wait(500, function()
      return picker:count() > 0
    end)
    picker.input:set("fix a bug")
    picker:find()
    vim.wait(300)
    local items = picker:items()
    assert.is_true(#items >= 1)
    assert.equals("🐛", items[1].value.emoji)
  end)

  it("invokes the configured action with the confirmed entry and records frecency", function()
    local received
    config.setup({
      action = function(entry)
        received = entry
      end,
    })
    gitmoji.gitmoji()
    local picker = Snacks.picker.get({ source = "gitmoji" })[1]
    vim.wait(500, function()
      return picker:count() > 0
    end)
    picker.input:set("fix a bug")
    picker:find()
    vim.wait(300)
    picker.list:view(1)
    picker:action("confirm")
    vim.wait(100)

    assert.is_not_nil(received)
    assert.equals("🐛", received.value.emoji)

    local frecency = require("snacks-gitmoji.frecency")
    assert.is_true(frecency.score_for("🐛") > 0)
  end)

  it("pins a 'No emoji' entry above every gitmoji entry", function()
    config.setup({ action = function() end })
    gitmoji.gitmoji()
    local picker = Snacks.picker.get({ source = "gitmoji" })[1]
    vim.wait(500, function()
      return picker:count() > 0
    end)
    assert.equals(#require("snacks-gitmoji.emojis") + 1, picker:count())
    local items = picker:items()
    assert.equals("", items[1].value.emoji)
    assert.equals("No emoji", items[1].value.description)
  end)

  it("confirming the no-emoji entry skips frecency recording", function()
    local received
    config.setup({
      action = function(entry)
        received = entry
      end,
    })
    gitmoji.gitmoji()
    local picker = Snacks.picker.get({ source = "gitmoji" })[1]
    vim.wait(500, function()
      return picker:count() > 0
    end)
    picker.list:view(1)
    picker:action("confirm")
    vim.wait(100)

    assert.is_not_nil(received)
    assert.equals("", received.value.emoji)

    local frecency = require("snacks-gitmoji.frecency")
    assert.equals(-1, frecency.score_for(""))
  end)
end)
