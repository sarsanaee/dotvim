#!/usr/bin/env bash
# Remove the symlinks created by install.sh.
# Backups in ~/.dotfiles-backup/ are left alone; restore from there by hand.
# Plugins in ~/.vim/plugged and your undo history in ~/.vim/undodir are kept
# unless you pass --purge.
set -euo pipefail

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

for f in "$HOME/.vimrc" "$HOME/.vim/spell/en.utf-8.add"; do
    if [ -L "$f" ]; then rm "$f"; echo "removed symlink $f"
    elif [ -e "$f" ]; then echo "left alone (not a symlink): $f"
    fi
done

if [ "$PURGE" = 1 ]; then
    rm -rf "$HOME/.vim/plugged" "$HOME/.vim/autoload/plug.vim"
    echo "purged ~/.vim/plugged and vim-plug"
    echo "kept ~/.vim/undodir — delete it by hand if you really mean it"
else
    echo "Done. ~/.vim/plugged and ~/.vim/undodir were left in place (--purge removes plugins)."
fi
