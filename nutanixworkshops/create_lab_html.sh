#!/bin/bash

set -xe

for i in workshop-calm ; do
    git clone git@github.com:panlm/$i.git html
    cd html
    gsed -i "s/^extensions = \[/extensions = ['sphinxtogithub',/" conf.py
    gsed -i "s/^BUILDDIR.*$/BUILDDIR = ..\/lab\/$i/" Makefile
    make html
    cd ../
    rm -fr html
done

#for i in partnercalmworkshop calm ; do
#    git clone git@github.com:nutanixworkshops/$i.git html
#    cd html
#    gsed -i "s/^extensions = \[/extensions = ['sphinxtogithub',/" conf.py
#    gsed -i "s/^BUILDDIR.*$/BUILDDIR = ..\/lab\/$i/" Makefile
#    make html
#    cd ../
#    rm -fr html
#done
