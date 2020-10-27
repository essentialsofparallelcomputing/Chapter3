#!/usr/bin/env python

import enum

class PRECISION(enum.Enum):
  null   = 0
  fp16   = 1
  fp32   = 2
  fp64   = 3
  tensor = 4
  
class INPUT:
  size = 5

  wkey  = 0
  tkey  = 1
  msec  = 2
  bytes = 3
  flops = 4

class STATS:
  size = 5

  msec_min = 0
  msec_med = 1
  msec_max = 2
  bytes    = 3
  flops    = 4

MEGA =      1000*1000
GIGA = 1000*1000*1000
