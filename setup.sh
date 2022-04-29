#!/bin/bash

# required packages
sudo apt update
sudo apt install clang cmake
sudo apt install ripgrep

# install plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# setup undodir.
mkdir -p $HOME/.vim/undodir

# copy the vimrc
rm $HOME/.vimrc
cp vimrc $HOME/.vimrc

# installing packages
vim -c :PlugInstall -c :q

# setup YCM
pushd $HOME/.vim/plugged/YouCompleteMe
./install.py --clang-completer
popd
