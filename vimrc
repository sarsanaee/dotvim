" ═══════════════════════════════════════════════════════════════════
"  vimrc — https://github.com/sarsanaee/dotvim
"  Installed by ./install.sh  (symlinked to ~/.vimrc)
"
"  Companion to https://github.com/sarsanaee/dot_tmux. The terminal
"  settings below are chosen to match that tmux config, and to survive
"  agentic editors (Claude Code) rewriting files under an open buffer.
"
"  Requires Vim 8.2+ for the terminal features. Check with :version
" ═══════════════════════════════════════════════════════════════════

" Plain `vim` implies this when a user vimrc exists, but `vim -u path/vimrc`
" does not — and tagbar, ctrlp, vim-maximizer and vim-ripgrep all begin with
" `if &cp | finish`, so without it they load and silently define nothing.
set nocompatible

let mapleader = " "               " must precede every <leader> mapping

" ═══════════════════════════════════════════════════════════════════
"  EDITING
" ═══════════════════════════════════════════════════════════════════
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nowrap
set backspace=indent,eol,start    " backspace over autoindent, EOL, start

" ── Search ─────────────────────────────────────────────────────────
set incsearch
set hlsearch
set ignorecase                    " 'smartcase' is a no-op on its own: it
set smartcase                     " only refines an already case-insensitive
                                  " search. Lowercase pattern => any case,
                                  " any capital => exact. (ignorecase was
                                  " missing before, so smartcase did nothing.)
nnoremap <silent> <leader><Space> :nohlsearch<CR>

" ── Gutter and margins ─────────────────────────────────────────────
set number
set relativenumber
set colorcolumn=80
set signcolumn=yes                " reserve the sign column permanently so
                                  " text does not jump sideways when ALE
                                  " adds or removes a diagnostic marker

" ── Quiet ──────────────────────────────────────────────────────────
set noerrorbells
set belloff=all                   " noerrorbells alone still leaves the
                                  " visual bell and every non-error beep

" ═══════════════════════════════════════════════════════════════════
"  FILES, UNDO, AND EXTERNAL CHANGES
"
"  This block is what makes Vim behave when something else edits a file
"  you have open — Claude Code, a formatter, git checkout, a rebase.
" ═══════════════════════════════════════════════════════════════════
" No swap file: without this you get the E325 ATTENTION prompt every time
" you reopen a file another process touched while Vim had it open.
set noswapfile
set nobackup

set undofile
set undodir=~/.vim/undodir
set undolevels=1000
if !isdirectory(expand(&undodir))
    call mkdir(expand(&undodir), 'p', 0700)
endif

" Persistent undo means an agent's rewrite is not a one-way door: reload,
" then `u` walks back through its edits and yours alike.

" autoread is only permission to reload; on its own it does nothing in a
" terminal. Something has to ask Vim to look at the file, and `checktime`
" is that ask. It runs on three paths: on FocusGained (dot_tmux sets
" `focus-events on`, so returning to the Vim pane from the pane running
" Claude Code triggers it), on CursorHold, and on the timer below.
set autoread
set updatetime=300                " also governs how quickly CursorHold fires

augroup reload_on_external_change
    autocmd!
    " Deliberately no CursorHoldI: never swap a buffer out from under you
    " in the middle of typing.
    autocmd FocusGained,BufEnter,CursorHold * silent! checktime
    autocmd FileChangedShellPost *
        \ echohl WarningMsg
        \ | echom 'Buffer reloaded — changed on disk'
        \ | echohl None
augroup END

" Focus events turned out to be delivered unreliably in practice (measured:
" they fired on 2 of 6 pane switches here, against 6 of 6 for a bare config —
" ALE and clangd starting up appear to swallow some). A one-second timer is
" the backstop: `checktime` is a stat() per loaded buffer, far too cheap to
" notice, and it makes the refresh independent of terminal quirks entirely.
" Guarded to normal mode so a buffer is never swapped out mid-keystroke or
" while the command-line window is open.
if has('timers')
    function! s:CheckExternalChange(_) abort
        if mode() ==# 'n' && empty(getcmdwintype())
            silent! checktime
        endif
    endfunction
    call timer_start(1000, function('s:CheckExternalChange'), {'repeat': -1})
endif

" Force the check by hand when you want it.
nnoremap <silent> <leader>r :checktime<CR>

" ── Reopen a file where you left it ────────────────────────────────
augroup restore_cursor
    autocmd!
    autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$")
        \     && &filetype !~# 'commit\|rebase'
        \ |   execute "normal! g`\""
        \ | endif
augroup END

" ═══════════════════════════════════════════════════════════════════
"  TERMINAL INTEGRATION  (the tmux-facing half)
" ═══════════════════════════════════════════════════════════════════
" ── Cursor shape: bar in insert, block otherwise ───────────────────
" tmux 3.4 parses DECSCUSR and re-emits it through the outer terminal's
" Ss/Se capability (both xterm-256color and tmux-256color carry it here),
" so the raw sequence is correct inside and outside tmux — no DCS wrapper.
"
" The previous `autocmd VimEnter * silent !echo -ne "\e[2 q"` is gone: it
" spawned a shell on every start, forcing a full redraw, and under dash
" `echo -ne` prints a literal "-ne". t_EI already covers it.
let &t_SI = "\<Esc>[6 q"          " insert  -> bar
let &t_SR = "\<Esc>[4 q"          " replace -> underline
let &t_EI = "\<Esc>[2 q"          " normal  -> block

" ── Focus reporting ────────────────────────────────────────────────
" This is the load-bearing line for the reload-on-switch behaviour above.
" Ubuntu builds Vim with +terminfo, and neither the xterm-256color nor the
" tmux-256color entry carries a focus-reporting capability — so t_fe comes
" up empty, Vim never sends the "start reporting focus" sequence, and
" FocusGained/FocusLost never fire at all. dot_tmux already sets
" `focus-events on`; this is the other half of the handshake.
"
" Measured: with these four lines, switching tmux panes delivers
" FocusLost/FocusGained to Vim. Without them, nothing arrives and the
" buffer only refreshes on the CursorHold path.
if !has('gui_running') && empty(&t_fe)
    let &t_fe = "\<Esc>[?1004h"      " start reporting focus
    let &t_fd = "\<Esc>[?1004l"      " stop reporting on exit
    " Vim also has to recognise the two sequences the terminal sends back,
    " otherwise they arrive as a literal "[I" / "[O" typed into the buffer.
    execute "set <FocusGained>=\<Esc>[I"
    execute "set <FocusLost>=\<Esc>[O"
endif

" ── Mouse ──────────────────────────────────────────────────────────
" tmux has `mouse on`, so without this tmux owns every click and drag.
" mouse=a hands them to Vim while it runs: drag selects, click moves the
" cursor, the wheel scrolls the buffer, and dragging a split border
" resizes it. Hold SHIFT to bypass Vim and get the terminal's own
" selection back — the same escape hatch dot_tmux documents for tmux.
if has('mouse')
    set mouse=a
    " SGR encoding. The legacy protocol cannot express a column past 223,
    " so on a wide tmux pane clicks on the right-hand side land in the
    " wrong place without this.
    if exists('&ttymouse')
        if has('mouse_sgr')
            set ttymouse=sgr
        else
            set ttymouse=xterm2
        endif
    endif
endif

" ── Clipboard ──────────────────────────────────────────────────────
" Deliberately NOT `set clipboard=unnamedplus`: that routes every delete
" and change through the system clipboard too, so `dd` silently destroys
" whatever you copied from the browser. Explicit mappings instead.
" <leader>v mirrors tmux's `prefix + C-v` paste, and avoids the timeout
" that mapping <leader>p would impose on the existing <leader>pv/<leader>ps.
if has('clipboard')
    nnoremap <leader>y "+y
    xnoremap <leader>y "+y
    nnoremap <leader>Y "+y$
    nnoremap <leader>v "+p
    nnoremap <leader>V "+P
    xnoremap <leader>v "+p
endif

" ═══════════════════════════════════════════════════════════════════
"  PLUGINS  (vim-plug)
" ═══════════════════════════════════════════════════════════════════
call plug#begin('~/.vim/plugged')

Plug 'morhetz/gruvbox'
Plug 'jremmen/vim-ripgrep'
Plug 'tpope/vim-fugitive'
Plug 'leafgarland/typescript-vim'
Plug 'lyuts/vim-rtags'
Plug 'ctrlpvim/ctrlp.vim'         " maintained fork; kien/ctrlp.vim is dead
Plug 'chazy/cscope_maps'
Plug 'mbbill/undotree'
Plug 'vim-utils/vim-man'
Plug 'preservim/tagbar'
Plug 'editorconfig/editorconfig-vim'
Plug 'dense-analysis/ale'
Plug 'rhysd/vim-clang-format'
Plug 'szw/vim-maximizer'

" copilot.vim raises an error on every InsertEnter when node is missing.
" Guarded so a machine without node still starts clean.
if executable('node')
    Plug 'github/copilot.vim'
endif

" Plug 'ycm-core/YouCompleteMe'   " superseded by ALE + clangd below
" Plug 'liuchengxu/vista.vim'

call plug#end()
" plug#end() runs `filetype plugin indent on` and `syntax enable` itself.

" ═══════════════════════════════════════════════════════════════════
"  COLOURS
"
"  Everything here must come AFTER plug#end(): `:colorscheme` resets every
"  highlight group, so the old ColorColumn override — which sat above the
"  plugin block — was wiped before it was ever drawn.
" ═══════════════════════════════════════════════════════════════════
set t_Co=256

" True colour. dot_tmux forwards it (`terminal-overrides ...:RGB`), but
" inside tmux/screen Vim must be told the RGB escape sequences by hand:
" the terminfo entry does not advertise them.
if has('termguicolors') && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif

set background=dark               " before :colorscheme — gruvbox picks its
                                  " variant when it is sourced, not after
silent! colorscheme gruvbox       " silent! so a fresh clone still starts
                                  " before :PlugInstall has run

" gruvbox-toned column marker. The old guibg=lightgrey was invisible while
" termguicolors was off; with true colour on it would be a glaring white bar.
highlight ColorColumn ctermbg=0 guibg=#3c3836

" ── Trailing whitespace ────────────────────────────────────────────
" `:match` is window-local, so the old top-level call stopped applying the
" moment you opened a split. Re-apply per window, and re-assert the colour
" after any colorscheme change.
highlight ExtraWhitespace ctermbg=red guibg=#fb4934
augroup trailing_whitespace
    autocmd!
    autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=#fb4934
    autocmd BufWinEnter * if &buftype ==# '' | match ExtraWhitespace /\s\+$/ | endif
augroup END

" ═══════════════════════════════════════════════════════════════════
"  PLUGIN SETTINGS
" ═══════════════════════════════════════════════════════════════════
" ── ripgrep ────────────────────────────────────────────────────────
" was `if executable('rb')` — a typo for 'rg', so root detection never
" switched on and :Rg always searched from the cwd instead of the repo root.
if executable('rg')
    let g:rg_derive_root = 1
endif

" ── ctrlp ──────────────────────────────────────────────────────────
" was g:ctrlp_user_commad (missing an 'n') and g:ctrlp_user_cache (not an
" option at all — the real name is g:ctrlp_use_caching). Both were inert.
if executable('rg')
    let g:ctrlp_user_command = 'rg --files --hidden --glob "!.git/*" %s'
    let g:ctrlp_use_caching = 0    " rg is fast enough to not need the cache
endif
let g:ctrlp_tabpage_position = 'ac'
let g:ctrlp_working_path_mode = 'ra'

" ── netrw ──────────────────────────────────────────────────────────
let g:netrw_browse_split = 2
let g:netrw_banner = 0            " was 2; the option is a boolean, so 2 just
                                  " meant "on". Set to 1 to bring it back.
let g:netrw_winsize = 25
let g:netrw_liststyle = 3

" ── ALE ────────────────────────────────────────────────────────────
let g:ale_completion_enabled = 1
let g:ale_linters = {'c': ['clangd'], 'cpp': ['clangd']}
let g:ale_c_clangd_executable = 'clangd'
let g:ale_c_parse_makefile = 1
let g:ale_c_parse_compile_commands = 1
let g:ale_lint_on_enter = 0             " don't lint on open
let g:ale_lint_on_text_changed = 'never'  " don't lint while typing
let g:ale_lint_on_save = 1
let g:ale_virtualtext_cursor = 'current'
let g:ale_set_balloons = 1
let g:ale_warn_about_trailing_whitespace = 1   " was set twice, to 0 then 1

" was `let b:ale_fixers = {'c': ['prettier', 'eslint']}` — buffer-local, so
" it applied to at most the first buffer, and it named two JavaScript tools
" for C. clang-format honours a project's .clang-format file.
let g:ale_fixers = {
    \ '*':   ['remove_trailing_lines', 'trim_whitespace'],
    \ 'c':   ['clang-format'],
    \ 'cpp': ['clang-format'],
    \ }

" ── clang-format ───────────────────────────────────────────────────
let g:clang_format#detect_style_file = 1   " honour a project .clang-format

" ═══════════════════════════════════════════════════════════════════
"  SPELLING
"
"  Prose only. Globally-on spell underlined every identifier in C and C++.
"  Added words go to spell/en.utf-8.add in this repo, so `zg` follows you
"  to the next machine.
" ═══════════════════════════════════════════════════════════════════
set spelllang=en_us
set spellfile=~/.vim/spell/en.utf-8.add
augroup spell_for_prose
    autocmd!
    autocmd FileType markdown,text,gitcommit,rst,tex,mail setlocal spell
augroup END
nnoremap <leader>s :setlocal spell!<CR>:setlocal spell?<CR>

" ═══════════════════════════════════════════════════════════════════
"  MAPPINGS
" ═══════════════════════════════════════════════════════════════════
" ── Windows ────────────────────────────────────────────────────────
nnoremap <leader>h :wincmd h<CR>
nnoremap <leader>j :wincmd j<CR>
nnoremap <leader>k :wincmd k<CR>
nnoremap <leader>l :wincmd l<CR>
nnoremap <silent> <leader>+ :vertical resize +5<CR>
nnoremap <silent> <leader>- :vertical resize -5<CR>
nnoremap <leader>m :MaximizerToggle<CR>

" ── Files and navigation ───────────────────────────────────────────
nnoremap <leader>pv :wincmd v <bar> :Ex <bar> :vertical resize 30<CR>
nnoremap <leader>ps :Rg<Space>
nnoremap <leader>u  :UndotreeShow<CR>
nnoremap <leader>tt :TagbarToggle<CR>

" ── Code intelligence (ALE + clangd) ───────────────────────────────
" These fill the slots the commented-out YouCompleteMe mappings held.
nnoremap <silent> <leader>gd :ALEGoToDefinition<CR>
nnoremap <silent> <leader>gr :ALEFindReferences<CR>
nnoremap <silent> <leader>gh :ALEHover<CR>
nnoremap <silent> <leader>gf :ALEFix<CR>
nnoremap <silent> [w :ALEPreviousWrap<CR>
nnoremap <silent> ]w :ALENextWrap<CR>

" ── Host-specific overrides, never committed ───────────────────────
if filereadable(expand('~/.vimrc.local'))
    source ~/.vimrc.local
endif
