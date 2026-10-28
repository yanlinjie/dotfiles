-- Native optional packages; compatible with the existing Vimscript init.
vim.cmd.packadd("render-markdown.nvim")
vim.g.table_mode_corner = "|"
vim.g.table_mode_disable_mappings = 1
vim.g.table_mode_disable_tableize_mappings = 1
vim.cmd.packadd("vim-table-mode")

require("render-markdown").setup({
  file_types = { "markdown" },
  render_modes = { "n", "c" },
  heading = {
    sign = false,
    icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
  },
  code = { sign = false, language_icon = false },
  bullet = { icons = { "-" } },
  checkbox = {
    unchecked = { icon = "[ ] " },
    checked = { icon = "[x] " },
    custom = { todo = { raw = "[-]", rendered = "[-] ", highlight = "RenderMarkdownTodo" } },
  },
  quote = { icon = ">" },
  dash = { icon = "-" },
  link = { enabled = false },
  latex = { enabled = false },
})

-- Both terminal and RGB colors are specified; leave Normal and the theme alone.
local function colors()
  local headings = {
    { 81, "#5fd7ff" }, { 114, "#87d787" }, { 221, "#ffd75f" },
    { 183, "#d7afff" }, { 216, "#ffaf87" }, { 117, "#87d7ff" },
  }
  for i, color in ipairs(headings) do
    vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i, { fg = color[2], ctermfg = color[1], bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i .. "Bg", { bg = "#303030", ctermbg = 236 })
  end
  for _, group in ipairs({ "RenderMarkdownCode", "RenderMarkdownCodeInline", "RenderMarkdownCodeBorder" }) do
    vim.api.nvim_set_hl(0, group, { bg = "#303030", ctermbg = 236 })
  end
  for group, target in pairs({
    RenderMarkdownTableHead = "Title", RenderMarkdownTableRow = "Normal",
    RenderMarkdownTableFill = "Normal", RenderMarkdownBullet = "Special",
    RenderMarkdownUnchecked = "Todo", RenderMarkdownChecked = "Comment",
    RenderMarkdownTodo = "Todo",
  }) do
    vim.api.nvim_set_hl(0, group, { link = target })
  end
end
colors()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("MarkdownToolsColors", { clear = true }),
  callback = colors,
})
