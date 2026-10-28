
" ==========================================
" Neovim 基础配置
" 兼容较旧的 Neovim 版本
" ==========================================

" 1. 界面与光标
set number
set relativenumber
set cursorline
set ruler
set showmatch
set laststatus=2
set scrolloff=5

" 2. 搜索
set incsearch
set hlsearch
set ignorecase
set smartcase

" 3. 编辑与缩进
set backspace=indent,eol,start
set autoindent
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

" 4. 文件类型与语法高亮
syntax on
filetype plugin indent on

" 5. 缓冲区与分屏
set hidden
set splitbelow
set splitright

" 6. 命令行补全
set wildmenu
set wildmode=longest:full,full

" 7. 自定义快捷键
let mapleader = " "

" 空格 + w：保存文件
nnoremap <leader>w :write<CR>

" 空格 + h：清除搜索高亮
nnoremap <leader>h :nohlsearch<CR>


set clipboard+=unnamedplus

set clipboard+=unnamedplus

" 工程目录树、搜索与 tmux 导航
lua require("project_browser")

colorscheme vim

" Python 语言服务器和 Tab 补全
lua require("python_completion")

source ~/.config/nvim/completion-colors.vim
lua require("auto_reload")

" Markdown 编辑、终端渲染与表格
lua require("markdown_tools")
