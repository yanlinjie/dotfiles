-- Follow same-file Markdown heading links; no external plugin required.
local M = {}

local function slug(text)
  text = vim.fn.tolower(vim.trim(text))
  -- Keep UTF-8 text, underscores and hyphens; remove ASCII punctuation.
  text = text:gsub("%p", function(char)
    return (char == "_" or char == "-") and char or ""
  end)
  return text:gsub("%s", "-")
end

function M.follow()
  local parser = vim.treesitter.get_parser(0, "markdown")
  local trees = parser:parse(true)
  local node = vim.treesitter.get_node({ ignore_injections = false })
  while node and node:type() ~= "inline_link" do
    node = node:parent()
  end
  if not node then return false end
  local target
  for child in node:iter_children() do
    if child:type() == "link_destination" then
      target = vim.treesitter.get_node_text(child, 0)
      break
    end
  end
  if not target then return false end
  target = target:gsub("^<(.*)>$", "%1")
  if target:sub(1, 1) ~= "#" then return false end
  target = vim.fn.tolower(vim.uri_decode(target:sub(2)))
  local query = vim.treesitter.query.parse("markdown", [[
    (atx_heading heading_content: (_) @title)
    (setext_heading heading_content: (_) @title)
  ]])
  local used = {}
  for _, title in query:iter_captures(trees[1]:root(), 0) do
    local base = slug(vim.treesitter.get_node_text(title, 0))
    local anchor, suffix = base, 0
    while used[anchor] do
      suffix = suffix + 1
      anchor = base .. "-" .. suffix
    end
    used[anchor] = true
    if anchor == target then
      local row, col = title:start()
      vim.cmd("normal! m'")
      vim.api.nvim_win_set_cursor(0, { row + 1, col })
      vim.cmd("normal! zvzz")
      return true
    end
  end
  vim.notify("未找到章节标题：#" .. target, vim.log.levels.WARN)
  return true
end

function M.setup()
  vim.keymap.set("n", "<CR>", function()
    if not M.follow() then
      vim.cmd.normal({ vim.keycode("<CR>"), bang = true })
    end
  end, { buffer = true, silent = true, desc = "Follow Markdown heading link" })
  local undo = "silent! execute 'nunmap <buffer> <CR>'"
  vim.b.undo_ftplugin = (vim.b.undo_ftplugin and (vim.b.undo_ftplugin .. " | ") or "") .. undo
end

return M
