# dotvim

My Vim configuration, with a one-command install. Companion to
[dot_tmux](https://github.com/sarsanaee/dot_tmux) — the two are set up to work
together, and to stay out of the way of an agentic editor (Claude Code)
rewriting files underneath an open buffer.

```bash
git clone https://github.com/sarsanaee/dotvim.git ~/dotvim
cd ~/dotvim && ./install.sh
vim
```

That is the whole procedure on a new machine. `install.sh` is idempotent —
re-run it any time — and it backs up anything it replaces into
`~/.dotfiles-backup/<timestamp>/`.

| Flag | Effect |
|------|--------|
| `--dry-run` | Print every action, change nothing |
| `--no-deps` | Don't touch the package manager |
| `--no-plugins` | Skip vim-plug and the plugin downloads |

`./uninstall.sh` removes the symlinks; `--purge` also deletes the plugins.
Your undo history in `~/.vim/undodir` is never touched.

## Layout

```
vimrc                  -> ~/.vimrc                        (symlink)
spell/en.utf-8.add     -> ~/.vim/spell/en.utf-8.add       (symlink)
install.sh             installer
uninstall.sh           reverses the installer
setup.sh               forwards to install.sh (old name)
```

Nothing is copied, so editing `vimrc` in this repo takes effect immediately and
`git status` shows what you changed. Words you add with `zg` land in
`spell/en.utf-8.add` in the repo, so your dictionary follows you to the next
machine. Host-specific settings go in `~/.vimrc.local`, which the vimrc sources
if present and git never sees.

## Working next to Claude Code

The problem: an agent rewrites a file you have open, and Vim keeps showing you
the old contents until you force a reload — or worse, greets you with
`W11: Warning: File has changed since editing started` and makes you choose.

Three settings handle it.

```vim
set noswapfile     " no E325 ATTENTION prompt when a file is touched externally
set autoread       " permission to reload a buffer with no unsaved changes
set undofile       " an agent's rewrite is not a one-way door: `u` still works
```

`autoread` on its own does nothing in a terminal — it is only permission. Vim
still has to be *told* to look, with `checktime`. That happens on three paths:

1. **Switching tmux panes.** dot_tmux sets `focus-events on`; the vimrc asks
   the terminal to report focus (see below). Coming back from the pane running
   Claude Code refreshes the buffer as you arrive.
2. **A one-second timer.** The backstop, and in practice the one that does the
   work — focus events proved unreliable once ALE and clangd were running.
   `checktime` is a `stat()` per loaded buffer, far too cheap to notice.
3. **`<leader>r`**, when you want to force it.

The timer only fires in normal mode, so a buffer is never swapped out from
under you mid-keystroke.

**Your unsaved edits are safe.** `autoread` reloads only buffers with no
unsaved changes. If you have edited the buffer and an agent rewrites the file,
Vim keeps your version and tells you the two have diverged — it will not
silently pick a winner. Verified with a modified buffer and an external
rewrite: the unsaved work survived intact.

### Focus reporting

Ubuntu builds Vim with `+terminfo`, and neither the `xterm-256color` nor the
`tmux-256color` entry carries a focus-reporting capability. So `t_fe` comes up
empty, Vim never sends the "start reporting focus" sequence, and
`FocusGained` / `FocusLost` never fire *at all* — no matter what tmux is
configured to do. The vimrc supplies the missing half:

```vim
let &t_fe = "\<Esc>[?1004h"
let &t_fd = "\<Esc>[?1004l"
execute "set <FocusGained>=\<Esc>[I"   " or the replies arrive as literal "[I"
execute "set <FocusLost>=\<Esc>[O"
```

## How this fits the tmux config

| Concern | Resolution |
|---------|-----------|
| **Leader vs prefix** | Vim's leader is `Space`, tmux's prefix is `Ctrl+Space`. No overlap. |
| **Mouse** | tmux has `mouse on`. `set mouse=a` hands clicks to Vim while it runs: drag selects, wheel scrolls the buffer, dragging a split border resizes it. **Hold Shift** to bypass Vim and get the terminal's own selection for copying — the same escape hatch dot_tmux documents. |
| **Wide panes** | `ttymouse=sgr`. The legacy mouse protocol cannot express a column past 223, so without it clicks on the right of a wide pane land in the wrong place. |
| **Cursor shape** | tmux 3.4 parses DECSCUSR and re-emits it through the outer terminal's `Ss`/`Se`, so the raw `t_SI`/`t_EI` sequences are correct inside and outside tmux. No DCS passthrough wrapper needed. |
| **True colour** | dot_tmux forwards RGB (`terminal-overrides ...:RGB`) and `COLORTERM=truecolor` survives into the pane, so `termguicolors` is switched on when that variable says the terminal can take it. Inside tmux Vim must be handed the RGB escapes by hand (`t_8f`/`t_8b`) — terminfo does not advertise them. |
| **Alternate screen** | dot_tmux's `smcup@:rmcup@` override applies to tmux ↔ the outer terminal, not to Vim ↔ tmux. Vim still restores your shell on `:q`. Checked, not assumed. |
| **`Alt+Up`** | Bound by tmux at the root level for copy mode, so Vim never sees it. Nothing here uses it. |

## What was broken

Six settings in the old vimrc did nothing at all. They are worth listing because
each one failed silently — no error, just no effect.

| Was | Problem |
|-----|---------|
| `if executable('rb')` | Typo for `rg`, so `g:rg_derive_root` was never set and `:Rg` searched from the cwd instead of the repo root. |
| `g:ctrlp_user_commad` | Missing an `n`. CtrlP never saw it. |
| `g:ctrlp_user_cache` | Not an option. The real name is `g:ctrlp_use_caching`. |
| `set smartcase` | Without `set ignorecase`, smartcase has nothing to refine and does nothing. |
| `b:ale_fixers` | Buffer-local in a vimrc, so it applied to at most the first buffer — and it named `prettier` and `eslint`, two JavaScript tools, for C. |
| `highlight ColorColumn` above `plug#end()` | `:colorscheme` resets every highlight group, so the override was wiped before it was ever drawn. |

Two more were actively harmful:

- `autocmd VimEnter * silent !echo -ne "\e[2 q"` spawned a shell on every
  start, forcing a full redraw — and under `dash` (Ubuntu's `/bin/sh`)
  `echo -ne` prints a literal `-ne`. `t_EI` already does the job.
- `setup.sh` ran `rm $HOME/.vimrc` with no backup, then `cp`, so any local
  edits were destroyed on every run. It also passed `curl -k` — certificate
  verification disabled for a script that is downloaded and then executed —
  and never installed **Vim itself**, which is how a machine ends up running
  `vim.tiny` with no `+clipboard` and no plugins.

`.gitmodules` declared six `bundle/*` pathogen submodules. There were no
gitlink entries in the index and no `bundle/` directory: the repo moved to
vim-plug years ago and the file had been dead weight since. Removed.

## Cheat sheet

Leader is `Space`.

### Windows and panes

| Key | Action |
|-----|--------|
| `<leader>` `h` `j` `k` `l` | Move between splits |
| `<leader>` `+` / `-` | Widen / narrow the split |
| `<leader>` `m` | Maximize this split, toggle |
| `<leader>` `pv` | Open the file explorer in a 30-column split |

### Finding things

| Key | Action |
|-----|--------|
| `Ctrl+p` | Fuzzy file finder (CtrlP, backed by ripgrep) |
| `<leader>` `ps` | `:Rg ` — search the repo |
| `<leader>` `tt` | Tagbar, the file's symbol outline |
| `<leader>` `u` | Undo tree |

### Code intelligence (ALE + clangd)

| Key | Action |
|-----|--------|
| `<leader>` `gd` | Go to definition |
| `<leader>` `gr` | Find references |
| `<leader>` `gh` | Hover / type info |
| `<leader>` `gf` | Fix (clang-format, honouring a project `.clang-format`) |
| `[w` / `]w` | Previous / next diagnostic |

These fill the slots the commented-out YouCompleteMe mappings used to hold.
ALE + clangd needs no compile step, unlike YCM.

### Clipboard

Deliberately **not** `set clipboard=unnamedplus`: that routes every delete and
change through the system clipboard too, so `dd` silently destroys whatever you
copied from the browser.

| Key | Action |
|-----|--------|
| `<leader>` `y` | Yank to the system clipboard |
| `<leader>` `Y` | Yank to end of line |
| `<leader>` `v` | Paste from the system clipboard (mirrors tmux's `prefix Ctrl+v`) |

### Other

| Key | Action |
|-----|--------|
| `<leader>` `s` | Toggle spell check in this buffer |
| `<leader>` `r` | Force a re-read of files changed on disk |
| `<leader>` `Space` | Clear search highlight |

## Spelling

Spell check runs on prose only — markdown, text, git commits, LaTeX, mail. It
used to be global, which underlined every identifier in C and C++. `<leader>s`
turns it on anywhere you want it.

## Notes

- **Requires Vim 8.2+.** Check with `vim --version`. `vim.tiny` (what Ubuntu
  gives you as `vi` out of the box) will not do — the installer tests for
  `+clipboard` rather than for the binary, so it catches that case.
- **copilot.vim is skipped when `node` is missing**, guarded with
  `if executable('node')`. Without the guard it raises an error on every
  `InsertEnter`. Install Node and re-run `:PlugInstall` to enable it, then
  `:Copilot setup` to authenticate.

  It needs **Node 20 or newer**; Ubuntu packages 18, which is too old — the
  language server exits with "Node.js too old. Upgrade to 20.x or newer".
  Get the current LTS from
  [NodeSource](https://github.com/nodesource/distributions). The guard tests
  only for the binary, not the version, because reading the version means
  spawning `node` on every single Vim start — measured at 7ms against a 40ms
  startup. `install.sh` does that check instead, since it runs rarely, and a
  too-old Node reports itself clearly anyway.
- **`set nocompatible` is deliberate.** Plain `vim` implies it when a user
  vimrc exists, but `vim -u path/to/vimrc` does not — and tagbar, ctrlp,
  vim-maximizer and vim-ripgrep all begin with `if &cp | finish`, so without it
  they load and silently define none of their commands.
- **netrw's banner is off** (`g:netrw_banner = 0`). It was `2`, which is not a
  valid value for a boolean and just meant "on". Set it to `1` to bring it back.
- `install.sh` finishes by asking the running Vim what it actually ended up
  with — `&autoread`, `&mouse`, whether each plugin defined its commands — and
  re-loads the config a second time under `TERM=tmux-256color`. It reports what
  is true, not what the config file asked for.
