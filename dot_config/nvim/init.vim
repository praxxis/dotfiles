" Neovim configuration based on existing Vimrc

" Use the OS clipboard by default
set clipboard=

" Add the g flag to search/replace by default
set gdefault

" Change mapleader
let mapleader=","

" Centralize backups, swapfiles and undo history using Neovim standard paths
set backupdir=~/.local/share/nvim/backup
set directory=~/.local/share/nvim/swap
set undodir=~/.local/share/nvim/undo
set undofile " Enable persistent undo

" Set modelines depth (modeline itself is default on)
set modelines=4

" Enable per-directory .vimrc files (secure is default on)
set exrc

" Enable line numbers
set number

" Tabs and indenting
set smartindent
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set noshiftround

" Highlight searches
set hlsearch
" Ignore case of searches
set ignorecase
" Highlight dynamically as pattern is typed
set incsearch

" Disable error bells
set noerrorbells
" Don't reset cursor to start of line when moving around.
set nostartofline
" Show the (partial) command as it's being typed
set showcmd
" Start scrolling N lines before the horizontal window border
set scrolloff=3

set mouse=

" Automatic commands
" Enable file type detection (is default on, but keep group for autocmds)
filetype plugin indent on
" Treat .json files as .js
autocmd BufRead,BufNewFile *.json set filetype=jsonc

" Set background for colorschemes
set background=dark

" Toggle diff view on the left, center, or right windows
nmap <silent> <leader>dl :call difftoggle#DiffToggle(1)<cr>
nmap <silent> <leader>dm :call difftoggle#DiffToggle(2)<cr>
nmap <silent> <leader>dr :call difftoggle#DiffToggle(3)<cr>
" Refresh the diff
nmap <silent> <leader>du :diffupdate<cr>
" Toggle ignoring whitespace
nmap <silent> <leader>dw :call iwhitetoggle#IwhiteToggle()<CR>

" Find merge conflict markers
nnoremap <leader>dc /\v^[<=>]{7}( .*\\|$) <cr>

" Fuzzy-find entries in Vim's help files.
nnoremap <silent><leader>fh
    \ :call readfile($VIMRUNTIME .'/doc/tags')
    \ ->util#SysR('fzy') ->matchstr('[^\t]\+')
    \ ->{x -> 'help '. x}() ->execute()<cr>

" Initialize vim-plug
call plug#begin() " Assumes plug.vim is installed in ~/.local/share/nvim/site/autoload/

Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'sheerun/vim-polyglot'
Plug 'sindrets/diffview.nvim' " Keep Neovim-specific plugin

call plug#end()

" Plugin settings
let g:vim_jsx_pretty_disable_tsx = 1 " For vim-polyglot
let g:dracula_italic = 0 " For dracula theme
let g:dracula_colorterm = 0 " For dracula theme

" Apply colorscheme
silent! colorscheme dracula
