if vim.g.loaded_snacks_gitmoji then
  return
end
vim.g.loaded_snacks_gitmoji = true

vim.api.nvim_create_user_command("SnacksGitmoji", function()
  require("snacks-gitmoji").gitmoji()
end, { desc = "Open the Snacks gitmoji picker" })
