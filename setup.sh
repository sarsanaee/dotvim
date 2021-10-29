#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo $DIR

sudo apt -y install clang clang-format

git submodule init
git submodule update

cd ..

# I need to come with something here, I'm sure it is a wrong way.
mv $DIR .vim
rm ~/.vimrc
ln -s ~/.vim/vimrc ~/.vimrc


