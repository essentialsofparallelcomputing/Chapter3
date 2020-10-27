#!/usr/bin/env python

import os,sys
from util import PRECISION

max_gflops_value = 0.0
max_weight = 0.0

key = 0

files = dict()

data = []

max_flop = []
max_band = []

save_flop_meta = False
save_band_meta = False

prevLine = ""

for line in sys.stdin:
  parts = line.split()
  if len(parts) == 3 and parts[2] == "GFLOPs":
    if len(prevLine.split()) != 3:
      files[key] = data
      data = []
      key = key + 1
  data.append(line)
  prevLine = line
files[key] = data

# Get reference index
tmp_file = files[len(files) - 1]
ref_index = 0
for i in xrange(0,len(tmp_file)):
  m = tmp_file[i].split()
  for j in xrange(0, 4):
    if len(m) == 3 and m[1] == PRECISION(j).name.upper() and m[2] == "GFLOPs":
      ref_index = j

for key in sorted(files.iterkeys()):
  info = files[key]
  index = 0
  for i in xrange(0,len(info)):
    m = info[i].split()
    if len(m) == 3 and m[1] == PRECISION(ref_index).name.upper() and m[2] == "GFLOPs":
      flops_value = float(m[0])
      if flops_value > max_gflops_value:
        max_gflops_value = flops_value
        max_flop  = []
        temp_list = []
        for j in xrange(0,i+1):
          temp_list.append(info[j].strip() + " EMP\n")
        max_flop.append(temp_list)
        save_flop_meta = True
    if len(m) == 2 and m[1] == "Weight":
      weight = float(m[0])
      if weight > max_weight:
        max_weight = weight
        max_band = []
        index = i+2
        save_band_meta = True
    if len(m) == 1 and m[0] == "META_DATA":
      if save_flop_meta:
        max_flop.append(info[i:])
      if save_band_meta:
        temp_list = []
        for j in xrange(index,i-1):
          temp_list.append(info[j].strip() + " EMP\n")
        max_band.append(temp_list)
        max_band.append(info[i:])
  save_flop_meta = False
  save_band_meta = False
        
for m in max_flop:
  for l in m:
    print l,
print ""

for m in max_band:
  for l in m:
    print l,
