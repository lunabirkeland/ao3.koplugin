#!/bin/sh
rm -rf build
mkdir build
mkdir build/ao3.koplugin
cp -r ./*.lua resources LICENSE build/ao3.koplugin
cd build || exit
tar -c ao3.koplugin | gzip --best >ao3.koplugin.tar.gz
