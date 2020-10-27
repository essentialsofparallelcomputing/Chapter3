#ifndef ERT_DRIVER_H
#define ERT_DRIVER_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/time.h>
#include <inttypes.h>
#include <iostream>

#ifdef ERT_OPENMP
#include <omp.h>
#endif

#ifdef ERT_MPI
#include <mpi.h>
#endif

#ifdef ERT_BGQM
#include "bgq.util.h"
#endif

#ifdef ERT_QPX
#include "kernel.qpx.h"
#endif

#if defined(ERT_SSE) || defined(ERT_AVX) || defined(ERT_KNC)
#include "kernel.avx.h"
#endif

#define GBUNIT (1024 * 1024 * 1024)

#ifdef ERT_HIP
  #define cudaMalloc hipMalloc
  #define cudaMemset hipMemset
  #define cudaGetDeviceCount hipGetDeviceCount
  #define cudaDeviceProp hipDeviceProp_t
  #define cudaGetDeviceProperties hipGetDeviceProperties
  #define cudaSetDevice hipSetDevice
  #define cudaGetDevice hipGetDevice
  #define cudaDeviceGetAttribute hipDeviceGetAttribute
  #define cudaDevAttrMultiProcessorCount hipDeviceAttributeMultiprocessorCount
  #define cudaDeviceSynchronize hipDeviceSynchronize
  #define cudaMemcpy hipMemcpy
  #define cudaMemcpyHostToDevice hipMemcpyHostToDevice
  #define cudaMemcpyDeviceToHost hipMemcpyDeviceToHost
  #define cudaFree hipFree
  #define cudaGetLastError hipGetLastError
  #define cudaDeviceReset hipDeviceReset
  #define cudaSuccess hipSuccess
  #define cudaGetErrorString hipGetErrorString
  #define cudaEvent_t hipEvent_t
  #define cudaEventCreate hipEventCreate
  #define cudaEventRecord hipEventRecord
  #define cudaEventSynchronize hipEventSynchronize
  #define cudaEventElapsedTime hipEventElapsedTime
#endif

#ifdef ERT_OCL
  #include <CL/cl.hpp>
  #include <iostream>
  #include <fstream>
  #include <string>
  #include <cstdlib>
  #include <vector>

  #ifndef DEVICE
  //#define DEVICE CL_DEVICE_TYPE_ACCELERATOR
  #define DEVICE CL_DEVICE_TYPE_GPU
  #endif

  size_t            global_size;
  size_t            local_size;
  //cl::Context       context;
  //cl::CommandQueue  queue;
  //cl::Program       program;
#endif 

#endif  // ERT_DRIVER_H
