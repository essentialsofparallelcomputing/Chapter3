#!/usr/bin/env python

import os,sys,math
from util import PRECISION

def smooth(x,y):
  xs = x[:]
  ys = y[:]

  d = 0

  for i in xrange(0,len(ys)):
    num = min(len(ys),i+d+1) - max(0,i-d)
    total = sum(ys[max(0,i-d):min(len(ys),i+d+1)])
    ys[i] = total/float(num)

  return xs,ys

lines = os.sys.stdin.readlines()

begin = 0
end   = 0

data = dict()

for i in xrange(0,len(lines)):
  m = lines[i].split()
  if (len(m) == 1 and m[0] in PRECISION.__members__) or len(m) == 0:
    end = i
    if end > begin:
      pkey = int(precision.value)
      if not data.has_key(pkey):
        data[pkey] = lines[begin:end]
    if len(m):
      precision = PRECISION[m[0]]
    begin = i+1

  if lines[i] == "META_DATA\n":
    break

meta_lines = lines[i:]

for pkey in sorted(data.iterkeys()):
  temp_lines = data[pkey]
  if pkey == PRECISION.fp64.value or PRECISION.fp32.value or PRECISION.fp16.value:
    lines = temp_lines
  gflops = [float(line.split()[9]) for line in temp_lines]
  maxgflops = max(gflops)
  print "  %7.2f" % maxgflops,
  init = PRECISION(pkey).name.upper()
  print init,
  print "GFLOPs"
print

x      = [float(line.split()[0]) for line in lines]
band   = [float(line.split()[6]) for line in lines]

weight = 0.0
for i in xrange(0,len(x)-1):
  x1 = math.log(x[i])
  y1 = band[i]

  x2 = math.log(x[i+1])
  y2 = band[i+1]

  weight += (y1+y2)/2.0 * (x2-x1)

maxband = max(band)
start = band.index(maxband)

x = x[start:]
band = band[start:]

minband = min(band)
maxband = max(band)

fraction = 1.05

samples = 10000
dband = maxband/float(samples - 1)

counts = samples*[0]
totals = samples*[0.0]

x,band = smooth(x,band)

for i in xrange(0,samples):
  cband = i*dband

  for v in band:
    if v >= cband/fraction and v <= cband*fraction:
      totals[i] += v
      counts[i] += 1

band_list = [[1000*maxband,1000]]

maxc = -1
maxi = -1
for i in xrange(samples-3,1,-1):
  if counts[i] > 6:
    if counts[i] > maxc:
      maxc = counts[i]
      maxi = i
  else:
    if maxc > 1:
      value = float(totals[maxi])/max(1,counts[maxi])
      if 1.15*value < float(band_list[-1][0])/band_list[-1][1]:
        band_list.append([totals[maxi],counts[maxi]])
      else:
        band_list[-1][0] += totals[maxi]
        band_list[-1][1] += counts[maxi]
    maxc = -1
    maxi = -1

print "  %7.2f Weight" % weight
print

band_name_list = ["DRAM"]
cache_num = len(band_list)-1

for cache in xrange(1,cache_num+1):
  band_name_list = ["L%d" % (cache_num+1 - cache)] + band_name_list


for (band,band_name) in zip(band_list,band_name_list):
  print "  %7.2f %s" % (float(band[0])/band[1],band_name)

print
for m in meta_lines:
  print m,
