-- 在 init.vim 末尾加载：lua require("auto_reload")
vim.opt.autoread = true

local function check_external_changes()
  -- 输入文字、选择文本或命令行操作时，推迟刷新。
  if vim.fn.mode() ~= "n" or vim.fn.getcmdwintype() ~= "" then
    return
  end
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr)
      and vim.bo[bufnr].buftype == ""
      and not vim.bo[bufnr].modified then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= "" and vim.fn.filereadable(name) == 1 then
        -- 指定缓冲区编号，避免检查其他已有未保存修改的缓冲区。
        vim.cmd("silent! " .. bufnr .. "checktime")
      end
    end
  end
end

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("ExternalFileAutoReload", { clear = true }),
  callback = check_external_changes,
})

-- 定时器让未获得焦点的 tmux 窗格也能检测；重复加载时先停止旧定时器。
if vim.g.external_file_reload_timer then
  vim.fn.timer_stop(vim.g.external_file_reload_timer)
end
vim.g.external_file_reload_timer = vim.fn.timer_start(1000, check_external_changes, { ["repeat"] = -1 })
