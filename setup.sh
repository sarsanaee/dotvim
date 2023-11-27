#!/bin/bash

# required packages
sudo apt update
sudo apt -y install clang cmake ripgrep

# install plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# setup undodir.
mkdir -p $HOME/.vim/undodir

# copy the vimrc
rm $HOME/.vimrc
cp vimrc $HOME/.vimrc

# installing packages
vim -c :PlugInstall -c :qa

# setup YCM
pushd $HOME/.vim/plugged/YouCompleteMe
./install.py --system-libclang --clang-completer
popd
