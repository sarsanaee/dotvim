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

set colorcolumn=80
highligh ColorColumn ctermbg=0 guibg=lightgrey

call plug#begin()

Plug 'morhetz/gruvbox'
Plug 'jremmen/vim-ripgrep'
Plug 'tpope/vim-fugitive'
Plug 'leafgarland/typescript-vim'
Plug 'lyuts/vim-rtags'
Plug 'kien/ctrlp.vim'
Plug 'ycm-core/YouCompleteMe'
Plug 'mbbill/undotree'
Plug 'vim-utils/vim-man'

call plug#end()

colorscheme gruvbox
set background=dark

if executable('rb')
    let g:rg_derive_root='true'
endif

let g:ctrlp_user_commad = ['.git/', 'git --git-dir=%s/.git ls-files -oc -exclude-standard']
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

" YCM
nnoremap <silent> <leader>gd :YcmCompleter GoTo<CR>
nnoremap <silent> <leader>gf :YcmCompleter FixIt<CR>

let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" Not sure if this is needed or not
augroup myCmds
au!
autocmd VimEnter * silent !echo -ne "\e[2 q"
augroup END
