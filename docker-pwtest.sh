#!/bin/bash

# this is the default pseudo dir for pw.x
PSDIR="/home/qe/espresso/pseudo"

# create the default pseudo dir and get the psp for pw_metal/metal.in
mkdir -p $PSDIR
cd $PSDIR
wget "https://www.quantum-espresso.org/upf_files/Al.pz-vbc.UPF"

# run a single test from the pw_metal suite
cd /home/qe/test-suite/pw_metal
mpirun -np `nproc` pw.x -i metal.in | tee metal.out

