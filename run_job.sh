#!/usr/bin/bash
condor_submit job.sub -append 'executable = k-means/CI_test.sh' -append 'requirements = (Machine != "node126.di.rm1")'