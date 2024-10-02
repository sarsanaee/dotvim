#!/bin/bash
if [[ "$(uname)" == "Darwin" ]]; then
    echo "Running on macOS"
    brew install ripgrep clang cmake
# Check if the OS is Ubuntu
elif [[ "$(lsb_release -is)" == "Ubuntu" ]]; then
    echo "Running on Ubuntu"
    sudo apt update
    sudo apt install clang cmake ripgrep
else
    echo "This script is intended to run on macOS and Ubuntu only."
fi

# install plug
curl -fLo ~/.vim/autoload/plug.vim -k --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# setup undodir.
mkdir -p $HOME/.vim/undodir

# copy the vimrc
rm $HOME/.vimrc
cp vimrc $HOME/.vimrc

# installing packages
vim -c :PlugInstall -c :qa

# setup YCM
# pushd $HOME/.vim/plugged/YouCompleteMe
# ./install.py --system-libclang --clang-completer
# popd
