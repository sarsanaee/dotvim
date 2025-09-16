syntax on

set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nu
set nowrap
set smartcase
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set relativenumber
set hlsearch
set spell spelllang=en_us
setlocal spell spelllang=en_us

" Backspace
set backspace=indent,eol,start

set colorcolumn=80
highligh ColorColumn ctermbg=0 guibg=lightgrey

call plug#begin()

Plug 'morhetz/gruvbox'
Plug 'jremmen/vim-ripgrep'
Plug 'tpope/vim-fugitive'
Plug 'leafgarland/typescript-vim'
Plug 'lyuts/vim-rtags'
Plug 'kien/ctrlp.vim'
" Plug 'ycm-core/YouCompleteMe'
Plug 'chazy/cscope_maps'
Plug 'mbbill/undotree'
Plug 'vim-utils/vim-man'
Plug 'github/copilot.vim'
Plug 'preservim/tagbar'
Plug 'editorconfig/editorconfig-vim'
Plug 'dense-analysis/ale'
Plug 'rhysd/vim-clang-format'
Plug 'szw/vim-maximizer'
" Plug 'liuchengxu/vista.vim'

call plug#end()
colorscheme gruvbox
set background=dark
set t_Co=256

if executable('rb')
    let g:rg_derive_root='true'
endif

let g:ctrlp_user_commad = ['.git/', 'git --git-dir=%s/.git ls-files -oc -exclude-standard']
let g:ctrlp_tabpage_position = 'ac'
let mapleader = " "
let g:netrw_browse_split=2
let g:netrw_banner = 2
let g:netrw_winsize = 25

let g:ctrlp_user_cache = 0

nnoremap <leader>h :wincmd h<CR>
nnoremap <leader>j :wincmd j<CR>
nnoremap <leader>k :wincmd k<CR>
nnoremap <leader>l :wincmd l<CR>
nnoremap <leader>u :UndotreeShow<CR>
nnoremap <leader>pv :wincmd v <bar> :Ex <bar> :vertical resize 30<CR>
nnoremap <leader>ps :Rg<Space>
nnoremap <silent> <leader>+ :vertical resize +5<CR>
nnoremap <silent> <leader>- :vertical resize -5<CR>
nnoremap <leader>tt :TagbarToggle<CR>


" YCM
" nnoremap <silent> <leader>gd :YcmCompleter GoTo<CR>
" nnoremap <silent> <leader>gf :YcmCompleter FixIt<CR>

let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" Not sure if this is needed or not
augroup myCmds
au!
autocmd VimEnter * silent !echo -ne "\e[2 q"
augroup END

:highlight ExtraWhitespace ctermbg=red guibg=red
:match ExtraWhitespace /\s\+$/

let g:ale_completion_enabled = 1
let g:ale_c_clangd_executable = 'clangd'
let g:ale_warn_about_trailing_whitespace = 0
let g:ale_sign_column_always = 1
let g:ale_linters = {'c': ['clangd'], 'cpp': ['clangd']}
let g:ale_lint_on_enter = 0        " Don't lint on open
let g:ale_lint_on_text_changed = 'never'  " Don't lint while typing
let g:ale_set_balloons = 1
let g:ale_warn_about_trailing_whitespace = 1
"

let g:ale_c_parse_makefile = 1
let g:ale_virtualtext_cursor = 'current'
let b:ale_fixers = {'c': ['prettier', 'eslint']}
let g:ale_c_parse_compile_commands = 1

if has("autocmd")
      autocmd BufReadPost *
          \ if line("'\"") > 1 && line("'\"") <= line("$") |
          \   execute "normal! g`\"" |
          \ endif
endif


nnoremap <leader>m :MaximizerToggle<CR>


" function! NearestMethodOrFunction() abort
"       return get(b:, 'vista_nearest_method_or_function', '')
" endfunction
" 
" set statusline+=%{NearestMethodOrFunction()}
" 
" " By default vista.vim never run if you don't call it explicitly.
" " "
" " " If you want to show the nearest function in your statusline automatically,
" " " you can add the following line to your vimrc
" autocmd VimEnter * call vista#RunForNearestMethodOrFunction()
