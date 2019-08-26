#!/bin/env python

import subprocess


cmd = 'mpirun -np 2 pw.x -i test-suite/pw_metal/metal.in'
proc = subprocess.run(cmd.split(), capture_output=True, text=True)

print(proc.stdout)

