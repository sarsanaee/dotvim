execute pathogen#infect()
syntax on
filetype plugin indent on
set number
set relativenumber

" map <C-K> :pyf /home/alireza/clang-format.py<cr>
" imap <C-K> <c-o>:pyf /home/alireza/clang-format.py<cr>

map <C-K> :py3f /home/alireza/.vim/clang-format.py<cr>
imap <C-K> <c-o>:py3f /home/alireza/.vim/clang-format.py<cr>

set colorcolumn=80
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#formatter = 'default'
let g:airline_statusline_ontop=1

let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1

set spell
set spelllang=en
set spellfile=$HOME/.vim/en.utf-8.add

set␣listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:␣

set visualbell
