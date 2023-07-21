#!/bin/bash -e

source python-2.7.11

export source_dir=Processing_CM_pools_30_Jan_19/SW_run_directory

#script = SlidingWindows...
#scaffold details file (provides scaffold names and sizes to allow it to identify input files)
#populations files (gives numbers of individuals per pop)
#prefix for output files
#low coverage (i.e. below this sites not called)
#high coverage
#minimum number of allele counts
#number of populations you require site to be present in 

inChr=$1

python $source_dir/SlidingWindows_v1.10.py $source_dir/${inChr}_details_V4.txt $source_dir/20pool_pop.txt ${inChr}.V4.50kb 15 500 2 2 50000 25000 1 0 0 0

