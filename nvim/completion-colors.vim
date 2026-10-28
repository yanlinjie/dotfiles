" 适用于当前 colorscheme vim、关闭 termguicolors 的 256 色终端。
" ctermfg 是文字颜色；ctermbg 是背景颜色。这里不设置 Normal 高亮组。
function! s:CompletionColors() abort
  " 菜单：浅色文字、深灰背景；选中项：白字、蓝色背景
  highlight BlinkCmpMenu cterm=NONE ctermfg=252 ctermbg=235
  highlight BlinkCmpMenuSelection cterm=bold ctermfg=255 ctermbg=31
  highlight BlinkCmpMenuBorder cterm=NONE ctermfg=75 ctermbg=235

  " 候选文字与补充说明（不单独设置背景，以便沿用选中项背景）
  highlight BlinkCmpLabel cterm=NONE ctermfg=252
  highlight BlinkCmpLabelDetail cterm=NONE ctermfg=245
  highlight BlinkCmpLabelDescription cterm=NONE ctermfg=245

  " 文档说明窗口
  highlight BlinkCmpDoc cterm=NONE ctermfg=252 ctermbg=235
  highlight BlinkCmpDocBorder cterm=NONE ctermfg=75 ctermbg=235
  highlight BlinkCmpDocSeparator cterm=NONE ctermfg=240 ctermbg=235

  " 函数参数提示：当前参数使用黄色
  highlight BlinkCmpSignatureHelp cterm=NONE ctermfg=252 ctermbg=235
  highlight BlinkCmpSignatureHelpBorder cterm=NONE ctermfg=75 ctermbg=235
  highlight BlinkCmpSignatureHelpActiveParameter cterm=bold ctermfg=220

  " 滚动条
  highlight BlinkCmpScrollBarThumb cterm=NONE ctermbg=245
  highlight BlinkCmpScrollBarGutter cterm=NONE ctermbg=236
endfunction

augroup PythonCompletionColors
  autocmd!
  autocmd ColorScheme * call s:CompletionColors()
augroup END
call s:CompletionColors()
