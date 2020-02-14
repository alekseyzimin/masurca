#!/bin/bash
MASURCA=$1
#first we update Flye in the test install
rm -rf build/inst/Flye
cp -r Flye build/inst/

mkdir -p temp
cd temp
rm -rf $MASURCA Flye
tar xzf ../$MASURCA.tar.gz
cd $MASURCA
rm -rf Flye
mkdir -p Flye
cp -r ../../Flye/* Flye
cd Flye
make clean
cd ..
grep Flye install.sh || echo "(cd Flye && make);" >> install.sh
cd ../
tar czf $MASURCA.tar.gz $MASURCA
mv ../$MASURCA.tar.gz ../$MASURCA.tar.gz.bak
cp $MASURCA.tar.gz ../
rm -rf temp
