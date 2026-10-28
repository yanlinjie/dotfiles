-- 在 init.vim 末尾加载：lua require("python_completion")
-- 安装脚本使用 Neovim 原生 opt 包；配色与工程浏览由原配置负责。
if vim.fn.has("nvim-0.11.3") == 0 then
  vim.notify("Python 补全需要 Neovim 0.11.3+，请用 ~/.local/bin/nvim 启动。", vim.log.levels.WARN)
  return
end

vim.cmd("packadd blink.cmp")
vim.cmd("packadd nvim-lspconfig")

require("blink.cmp").setup({
  enabled = function()
    return vim.bo.filetype == "python" and vim.bo.buftype == ""
  end,
  keymap = {
    preset = "default",
    -- 有补全菜单时确认候选项；其余时候保留片段跳转和正常缩进。
    ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
  },
  sources = { default = { "lsp", "path", "buffer" } },
  fuzzy = { implementation = "lua" },
  completion = {
    list = { selection = { preselect = true, auto_insert = false } },
    menu = { draw = { columns = { { "label", "label_description" } } } },
    documentation = { auto_show = true },
  },
  signature = { enabled = true },
  cmdline = { enabled = false },
})

local server = vim.fn.expand("~/.local/share/nvim-python-tools/bin/basedpyright-langserver")
local function project_python(root)
  for _, name in ipairs({ ".venv", "venv" }) do
    local candidate = (root or vim.fn.getcwd()) .. "/" .. name .. "/bin/python"
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end
  return vim.fn.exepath("python3")
end

vim.lsp.config("basedpyright", {
  cmd = { server, "--stdio" },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
  before_init = function(_, config)
    config.settings = config.settings or {}
    config.settings.python = vim.tbl_extend("force", config.settings.python or {}, {
      pythonPath = project_python(config.root_dir),
    })
    local root = config.root_dir
    -- gem5 的 Python 源码位于 src/python，单独加入本机编辑器的搜索路径。
    if root and (vim.uv or vim.loop).fs_stat(root .. "/SConstruct")
      and (vim.uv or vim.loop).fs_stat(root .. "/src/python/m5") then
      local analysis = config.settings.basedpyright.analysis
      analysis.extraPaths = analysis.extraPaths or {}
      local path = root .. "/src/python"
      if not vim.tbl_contains(analysis.extraPaths, path) then
        table.insert(analysis.extraPaths, path)
      end
    end
  end,
  settings = {
    basedpyright = {
      disableOrganizeImports = true,
      analysis = { typeCheckingMode = "standard", diagnosticMode = "openFilesOnly" },
    },
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("python_completion_keys", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "basedpyright" then
      return
    end
    local function map(key, action, description)
      vim.keymap.set("n", key, action, { buffer = args.buf, silent = true, desc = description })
    end
    map("gd", vim.lsp.buf.definition, "跳转到 Python 定义")
    map("gr", vim.lsp.buf.references, "查找 Python 引用")
    map("K", vim.lsp.buf.hover, "查看 Python 文档")
    map("<leader>rn", vim.lsp.buf.rename, "重命名 Python 符号")
    map("<leader>ca", vim.lsp.buf.code_action, "Python 代码修复")
    map("<leader>e", vim.diagnostic.open_float, "查看 Python 诊断详情")
  end,
})

vim.lsp.enable("basedpyright")

vim.api.nvim_create_user_command("PythonInfo", function()
  local client = vim.lsp.get_clients({ name = "basedpyright", bufnr = 0 })[1]
  local python = client and client.config.settings.python
  vim.notify("Python LSP: " .. (client and "basedpyright 已连接" or "当前文件尚未连接")
    .. "\n项目解释器: " .. (python and python.pythonPath or "等待连接")
    .. "\n语言服务器: " .. server)
end, { desc = "查看 Python 补全状态和项目解释器" })
