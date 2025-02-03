#!/usr/bin/bash
make all
make compare

condor_submit job.job