local tmp_data_dir = vim.fn.tempname()

local real_stdpath = vim.fn.stdpath
vim.fn.stdpath = function(what)
  if what == "data" then
    return tmp_data_dir
  end
  return real_stdpath(what)
end
vim.fn.mkdir(tmp_data_dir, "p")

local frecency = require("snacks-gitmoji.frecency")

describe("snacks-gitmoji.frecency", function()
  before_each(function()
    pcall(os.remove, tmp_data_dir .. "/snacks-gitmoji-data.json")
    package.loaded["snacks-gitmoji.frecency"] = nil
    frecency = require("snacks-gitmoji.frecency")
  end)

  it("gives an unrecorded emoji no score", function()
    local scores = frecency.get_scores()
    assert.is_nil(scores["🐛"])
    assert.equals(-1, frecency.score_for("🐛"))
  end)

  it("ranks a recorded emoji above an unrecorded one", function()
    frecency.record("🐛")
    local scores = frecency.get_scores()
    assert.is_true(scores["🐛"] > 0)
    assert.is_nil(scores["💄"])
  end)

  it("increases score with repeated recent use", function()
    frecency.record("✨")
    local once = frecency.score_for("✨")
    frecency.record("✨")
    local twice = frecency.score_for("✨")
    assert.is_true(twice > once)
  end)
end)
