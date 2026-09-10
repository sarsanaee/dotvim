#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  Install this Vim configuration on a fresh machine.
#
#    ./install.sh              install everything
#    ./install.sh --no-deps    skip installing system packages
#    ./install.sh --no-plugins skip downloading vim-plug and plugins
#    ./install.sh --dry-run    print what would happen, change nothing
#
#  Safe to run repeatedly: it is idempotent, and any real file it would
#  replace is backed up to ~/.dotfiles-backup/<timestamp>/ first.
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
DRY_RUN=0
NO_DEPS=0
NO_PLUGINS=0

for arg in "$@"; do
    case "$arg" in
        --dry-run)    DRY_RUN=1 ;;
        --no-deps)    NO_DEPS=1 ;;
        --no-plugins) NO_PLUGINS=1 ;;
        -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

if [ -t 1 ]; then
    B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; N=$'\e[0m'
else
    B=""; G=""; Y=""; R=""; N=""
fi
info() { printf '%s==>%s %s\n' "$B" "$N" "$*"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
err()  { printf '  %s✗%s %s\n' "$R" "$N" "$*" >&2; }
run()  { if [ "$DRY_RUN" = 1 ]; then printf '  [dry-run] %s\n' "$*"; else "$@"; fi; }

# ── 1. System dependencies ─────────────────────────────────────────
# The old setup.sh never installed Vim itself, which is how a machine ends
# up running vim.tiny — no +clipboard, no +termguicolors, no plugins.
install_deps() {
    info "Checking system dependencies"

    local want=()

    # vim.tiny answers to `vim` but is useless here, so test a feature
    # rather than the binary's presence.
    if ! vim --version 2>/dev/null | grep -q '+clipboard'; then
        want+=(vim-gtk3)          # the Ubuntu build that carries +clipboard
    fi
    command -v git          >/dev/null 2>&1 || want+=(git)
    command -v curl         >/dev/null 2>&1 || want+=(curl)
    command -v rg           >/dev/null 2>&1 || want+=(ripgrep)
    command -v clangd       >/dev/null 2>&1 || want+=(clangd)
    command -v clang-format >/dev/null 2>&1 || want+=(clang-format)
    command -v cmake        >/dev/null 2>&1 || want+=(cmake)
    command -v ctags        >/dev/null 2>&1 || want+=(universal-ctags)

    if [ ${#want[@]} -eq 0 ]; then ok "all dependencies present"; return 0; fi

    info "Installing: ${want[*]}"
    if command -v brew >/dev/null 2>&1; then
        # Homebrew names a few of these differently.
        local brewpkgs=()
        for p in "${want[@]}"; do
            case "$p" in
                vim-gtk3)        brewpkgs+=(vim) ;;
                clangd|clang-format) brewpkgs+=(llvm) ;;
                universal-ctags) brewpkgs+=(universal-ctags) ;;
                *)               brewpkgs+=("$p") ;;
            esac
        done
        run brew install "${brewpkgs[@]}"
    elif command -v apt-get >/dev/null 2>&1; then
        run sudo apt-get update -qq
        run sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${want[@]}"
    elif command -v dnf    >/dev/null 2>&1; then run sudo dnf install -y "${want[@]}"
    elif command -v pacman >/dev/null 2>&1; then run sudo pacman -S --needed --noconfirm "${want[@]}"
    elif command -v zypper >/dev/null 2>&1; then run sudo zypper install -y "${want[@]}"
    else
        err "no known package manager; install manually: ${want[*]}"
        return 1
    fi
    ok "dependencies installed"
}

# ── 2. Symlink a dotfile, backing up whatever is there now ─────────
link() {
    local src="$1" dst="$2"

    if [ ! -e "$src" ]; then err "missing source: $src"; return 1; fi

    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        ok "$(basename "$dst") already linked"
        return 0
    fi

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        run mkdir -p "$BACKUP"
        run mv "$dst" "$BACKUP/"
        warn "backed up existing $(basename "$dst") -> $BACKUP/"
    fi

    run mkdir -p "$(dirname "$dst")"
    run ln -s "$src" "$dst"
    ok "linked $dst -> $src"
}

# ── 3. Directories Vim expects to already exist ────────────────────
make_dirs() {
    info "Creating Vim directories"
    # undofile writes here on every save; Vim will not create it itself.
    run mkdir -p "$HOME/.vim/undodir"
    run mkdir -p "$HOME/.vim/spell"
    run mkdir -p "$HOME/.vim/autoload"
    ok "~/.vim/{undodir,spell,autoload}"
}

# ── Ask the running Vim what it actually ended up with, rather than
#    assuming the file we just wrote had the effect we intended ────
probe() {
    local out
    out="$(mktemp)"
    vim -es -N -u "$HOME/.vimrc" -i NONE \
        -c "call writefile([''.($1)], '$out')" -c 'qa!' </dev/null >/dev/null 2>&1 || true
    cat "$out" 2>/dev/null
    rm -f "$out"
}

# ── 4. vim-plug and the plugins ────────────────────────────────────
install_plugins() {
    info "Installing vim-plug and plugins"
    local plug="$HOME/.vim/autoload/plug.vim"

    if [ -s "$plug" ]; then
        ok "vim-plug already present"
    else
        # The old setup.sh passed `curl -k`, which turns off certificate
        # verification for a script that is downloaded and then executed.
        run curl -fLsS --proto '=https' --tlsv1.2 --create-dirs -o "$plug" "$PLUG_URL"
        [ "$DRY_RUN" = 1 ] || ok "vim-plug downloaded"
    fi

    if [ "$DRY_RUN" = 1 ]; then
        printf '  [dry-run] vim +PlugInstall +qa\n'
        return 0
    fi

    # --sync makes PlugInstall block instead of returning to a UI nobody
    # is looking at. -i NONE keeps it away from the real viminfo.
    vim -es -N -u "$HOME/.vimrc" -i NONE \
        -c 'PlugInstall --sync' -c 'qa!' </dev/null >/dev/null 2>&1 || true

    # Trust the filesystem, not the exit status. Ask vim-plug itself which
    # plugins are registered rather than grepping the vimrc: g:plugs reflects
    # any conditional Plug lines, so a guarded-out plugin is never reported
    # as missing.
    local missing=() name
    for name in $(probe "join(sort(keys(g:plugs)), ' ')"); do
        [ -d "$HOME/.vim/plugged/$name" ] || missing+=("$name")
    done

    if [ ${#missing[@]} -eq 0 ]; then
        ok "all plugins installed ($(ls -1 "$HOME/.vim/plugged" 2>/dev/null | wc -l) in ~/.vim/plugged)"
    else
        warn "not installed: ${missing[*]} — run :PlugInstall inside Vim"
    fi
}

# ── 5. Verify the result ───────────────────────────────────────────
check() {  # check <label> <expected> <vimscript expression>
    local got; got="$(probe "$3")"
    if [ "$got" = "$2" ]; then ok "$1"; return 0
    else err "$1 (expected $2, got ${got:-<vim produced nothing>})"; return 1; fi
}

verify() {
    info "Verifying"
    [ "$DRY_RUN" = 1 ] && { warn "dry run, nothing to verify"; return 0; }

    local fail=0

    # Does Vim load the config without throwing?
    local startup
    startup="$(vim -es -N -u "$HOME/.vimrc" -i NONE -c 'qa!' </dev/null 2>&1 || true)"
    if [ -z "$startup" ]; then ok "vimrc loads with no errors"
    else err "vimrc produced errors on startup:"; printf '%s\n' "$startup" | sed 's/^/      /'; fail=1; fi

    vim --version 2>/dev/null | grep -q '+clipboard' \
        && ok "vim has +clipboard" || { err "vim lacks +clipboard (vim.tiny?)"; fail=1; }

    # The Claude Code half: a buffer must refresh when the file changes.
    check "autoread is on"          "1"      '&autoread'        || fail=1
    check "swapfile is off"         "0"      '&swapfile'        || fail=1
    check "undofile is on"          "1"      '&undofile'        || fail=1
    # The tmux half.
    check "mouse=a"                 "a"      '&mouse'           || fail=1
    check "ttymouse=sgr"            "sgr"    '&ttymouse'        || fail=1
    check "ignorecase (smartcase)"  "1"      '&ignorecase'      || fail=1

    # Plugins actually defined their commands?
    local cmd
    for cmd in ALEFix TagbarToggle UndotreeShow MaximizerToggle Rg CtrlP Git ClangFormat; do
        if [ "$(probe "exists(':$cmd')")" = "2" ]; then ok ":$cmd available"
        else err ":$cmd missing — plugin did not load"; fail=1; fi
    done

    [ "$(probe "get(g:, 'colors_name', '')")" = "gruvbox" ] \
        && ok "colorscheme gruvbox active" || { err "gruvbox not active"; fail=1; }

    [ -w "$HOME/.vim/undodir" ] && ok "undodir writable" \
        || { err "~/.vim/undodir missing or read-only"; fail=1; }

    for t in clangd clang-format ctags rg; do
        command -v "$t" >/dev/null 2>&1 && ok "$t present" || warn "$t missing (ALE/Tagbar will be limited)"
    done

    # And the same config under tmux's TERM, which is what you actually use.
    if command -v tmux >/dev/null 2>&1; then
        local tout
        tout="$(TERM=tmux-256color vim -es -N -u "$HOME/.vimrc" -i NONE -c 'qa!' </dev/null 2>&1 || true)"
        [ -z "$tout" ] && ok "loads clean under TERM=tmux-256color" \
            || { err "errors under tmux TERM:"; printf '%s\n' "$tout" | sed 's/^/      /'; fail=1; }
    fi

    return $fail
}

main() {
    printf '%sInstalling Vim config from %s%s\n\n' "$B" "$REPO" "$N"
    [ "$DRY_RUN" = 1 ] && warn "DRY RUN — no changes will be made"

    [ "$NO_DEPS" = 1 ] && info "Skipping dependencies (--no-deps)" || install_deps

    make_dirs

    info "Linking dotfiles"
    link "$REPO/vimrc" "$HOME/.vimrc"
    link "$REPO/spell/en.utf-8.add" "$HOME/.vim/spell/en.utf-8.add"

    [ "$NO_PLUGINS" = 1 ] && info "Skipping plugins (--no-plugins)" || install_plugins

    verify || { printf '\n%sInstall finished with problems.%s\n' "$R" "$N"; exit 1; }

    printf '\n%sDone.%s  Run: vim\n' "$G" "$N"
    if [ -d "$BACKUP" ]; then
        printf 'Replaced files were saved in %s\n' "$BACKUP"
    fi
    return 0
}

main "$@"
