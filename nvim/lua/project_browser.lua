-- 从 init.vim 加载：lua require("project_browser")
-- 插件由 install.sh 安装到 Neovim 原生 opt 包目录。
if vim.fn.has("nvim-0.11.7") == 0 then
  vim.notify("工程浏览配置需要 Neovim 0.11.7+。", vim.log.levels.ERROR)
  return
end

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

for _, name in ipairs({
  "plenary.nvim", "nvim-tree.lua", "telescope.nvim", "vim-tmux-navigator",
}) do
  vim.cmd("packadd " .. name)
end

require("nvim-tree").setup({
  -- netrw 已在上方关闭，无需再清理它未创建的 FileExplorer 自动命令组。
  -- 默认 hijack_netrw 的 silent! 清理会留下 E216，影响严格的启动检查。
  hijack_netrw = false,
  view = { width = 32 },
  sync_root_with_cwd = true,
  update_focused_file = { enable = true, update_root = false },
  on_attach = function(bufnr)
    local api = require("nvim-tree.api")
    api.map.on_attach.default(bufnr)
    -- 把原本的 Ctrl+k 信息弹窗改为 gK，统一四个方向的切换键。
    local opts = { buffer = bufnr, silent = true }
    vim.keymap.set("n", "gK", api.node.show_info_popup, opts)
    for key, command in pairs({
      ["<C-h>"] = "TmuxNavigateLeft", ["<C-j>"] = "TmuxNavigateDown",
      ["<C-k>"] = "TmuxNavigateUp", ["<C-l>"] = "TmuxNavigateRight",
    }) do
      vim.keymap.set("n", key, "<cmd>" .. command .. "<CR>", opts)
    end
  end,
  -- gem5 工程较大，先使用手动刷新，避免监视大量生成文件。
  filesystem_watchers = { enable = false },
  renderer = {
    group_empty = true,
    icons = {
      show = { file = false, folder = false, folder_arrow = true, git = false },
      glyphs = { folder = { arrow_closed = "+", arrow_open = "-" } },
    },
  },
  filters = {
    enable = false,
    dotfiles = false,
    git_ignored = false,
    custom = {},
  },
})

require("telescope").setup({
  defaults = {
    sorting_strategy = "ascending",
    layout_strategy = "flex",
    path_display = { "truncate" },
    file_ignore_patterns = { "^build/", "^m5out/", "^%.git/", "__pycache__/" },
  },
  pickers = {
    find_files = { hidden = true },
    live_grep = {
      additional_args = function()
        return { "--glob", "!build/**", "--glob", "!m5out/**", "--glob", "!.git/**" }
      end,
    },
  },
})

local function map(key, action, description)
  vim.keymap.set("n", key, action, { silent = true, desc = description })
end
local tree = require("nvim-tree.api")
local telescope = require("telescope.builtin")
-- 使用空格+t，保留空格+e 给可能存在的 Python 诊断快捷键。
map("<leader>t", tree.tree.toggle, "打开或关闭工程目录树")
map("<leader>E", function()
  tree.tree.find_file({ open = true, focus = true })
end, "在目录树中定位当前文件")
map("<leader>ff", telescope.find_files, "按文件名查找工程文件")
map("<leader>fg", telescope.live_grep, "搜索工程中的文本")
map("<leader>fb", telescope.buffers, "切换已打开的文件")
