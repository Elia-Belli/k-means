#!/usr/bin/bash
make all
make compare

condor_submit job.sub -append 'executable = single_lib_tests.sh' -append 'requirements = (Machine != "node126.di.rm1")'