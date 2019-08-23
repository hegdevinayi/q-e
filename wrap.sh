#!/bin/bash

#mpirun -np `nproc` $*

cd /home/qe/test-suite/
make run-custom-test-parallel testdir=pw_vc-relax
