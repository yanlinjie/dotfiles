-- Installed as after/ftplugin/markdown.lua: settings and mappings are local.
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.textwidth = 0
vim.opt_local.formatoptions:remove({ "t", "a" })

vim.keymap.set("n", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { buffer = true, expr = true, silent = true, desc = "Next visual line" })
vim.keymap.set("n", "k", function()
  return vim.v.count == 0 and "gk" or "k"
end, { buffer = true, expr = true, silent = true, desc = "Previous visual line" })
vim.keymap.set("n", "<leader>mp", "<cmd>RenderMarkdown buf_toggle<CR>",
  { buffer = true, silent = true, desc = "Toggle Markdown rendering" })
vim.keymap.set("n", "<leader>mt", "<cmd>TableModeToggle<CR>",
  { buffer = true, silent = true, desc = "Toggle Markdown table editing" })
vim.keymap.set("i", "|", function()
  return vim.fn["tablemode#IsActive"]() == 1 and "<Plug>(table-mode-tableize)" or "|"
end, { buffer = true, expr = true, remap = true, desc = "Align table when table mode is enabled" })

local undo = "setlocal wrap< linebreak< breakindent< textwidth< formatoptions<"
for _, lhs in ipairs({ "j", "k", "<leader>mp", "<leader>mt" }) do
  undo = undo .. " | silent! execute 'nunmap <buffer> " .. lhs .. "'"
end
undo = undo .. " | silent! execute 'iunmap <buffer> <Bar>'"
vim.b.undo_ftplugin = (vim.b.undo_ftplugin and (vim.b.undo_ftplugin .. " | ") or "") .. undo

require("markdown_jump").setup()
