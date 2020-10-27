#include "driver.h"
#include "kernel1.h"

double getTime()
{
  double time;

#ifdef ERT_OPENMP
  time = omp_get_wtime();
#elif ERT_MPI
  time = MPI_Wtime();
#else
  struct timeval tm;
  gettimeofday(&tm, NULL);
  time = tm.tv_sec + (tm.tv_usec / 1000000.0);
#endif
  return time;
}

#ifdef ERT_OCL
inline std::string loadProgram(std::string input)
{
  std::ifstream stream(input.c_str());
  if (!stream.is_open()) {
    std::cout << "Cannot open file: " << input << std::endl;
    exit(1);
  }

  return std::string(std::istreambuf_iterator<char>(stream), (std::istreambuf_iterator<char>()));
}
#endif

template <typename T>
inline void checkBuffer(T *buffer)
{
  if (buffer == nullptr) {
    fprintf(stderr, "Out of memory!\n");
    exit(1);
  }
}

template <typename T>
T *alloc(uint64_t psize)
{
#ifdef ERT_INTEL
  return (T *)_mm_malloc(psize, ERT_ALIGN);
#else
  return (T *)malloc(psize);
#endif
}

#ifdef ERT_GPU
template <typename T>
T *setDeviceData(uint64_t nsize)
{
  T *buf;
  cudaMalloc((void **)&buf, nsize * sizeof(T));
  cudaMemset(buf, 0, nsize * sizeof(T));
  return buf;
}

inline void setGPU(const int id)
{
  int num_gpus = 0;
  int gpu;
  int gpu_id;
  int numSMs;

  cudaGetDeviceCount(&num_gpus);
  if (num_gpus < 1) {
    fprintf(stderr, "No GPU device detected.\n");
    exit(1);
  }

  for (gpu = 0; gpu < num_gpus; gpu++) {
    cudaDeviceProp dprop;
    cudaGetDeviceProperties(&dprop, gpu);
  }

  cudaSetDevice(id % num_gpus);
  cudaGetDevice(&gpu_id);
  cudaDeviceGetAttribute(&numSMs, cudaDevAttrMultiProcessorCount, gpu_id);
}
#endif

#ifdef ERT_OCL
template<typename Kernel>
inline void launchKernel(Kernel&& ocl_kernel, uint64_t n, uint64_t t, cl::CommandQueue queue,
		         cl::Buffer d_buf, cl::Buffer d_params, cl::Event *event)
{
  if ((global_size != 0) && (local_size != 0))
    *event = ocl_kernel(cl::EnqueueArgs(queue, cl::NDRange(global_size), cl::NDRange(local_size)), 
               n, t, d_buf, d_params);
  else if ((global_size == 0) && (local_size != 0))
    *event = ocl_kernel(cl::EnqueueArgs(queue, cl::NDRange(n), cl::NDRange(local_size)), 
               n, t, d_buf, d_params);
  else
    *event = ocl_kernel(cl::EnqueueArgs(queue, cl::NDRange(n)), 
               n, t, d_buf, d_params);
}
#else
template <typename T>
inline void launchKernel(uint64_t n, uint64_t t, uint64_t nid, T *buf, T *d_buf, int *bytes_per_elem_ptr,
                         int *mem_accesses_per_elem_ptr)
{
#if ERT_AVX // AVX intrinsics for Edison(intel xeon)
  avxKernel(n, t, &buf[nid]);
#elif ERT_KNC // KNC intrinsics for Babbage(intel mic)
  kncKernel(n, t, &buf[nid]);
#elif ERT_GPU // GPU code
  gpuKernel<T>(n, t, d_buf, bytes_per_elem_ptr, mem_accesses_per_elem_ptr);
  cudaDeviceSynchronize();
#else         // C-code
  kernel<T>(n, t, &buf[nid], bytes_per_elem_ptr, mem_accesses_per_elem_ptr);
#endif
}
#endif

template <typename T>
void run(uint64_t PSIZE, T *buf, int rank, int nprocs, int *nthreads_ptr)
{
  if (rank == 0) {
    if (std::is_floating_point<T>::value) {
      if (sizeof(T) == 4) {
        printf("fp32\n");
      } else if (sizeof(T) == 8) {
        printf("fp64\n");
      }
    } else if (std::is_same<T, half2>::value) {
      printf("fp16\n");
    } else {
      fprintf(stderr, "Data type not supported.\n");
      exit(1);
    }
  }
  int id = 0;
#ifdef ERT_OPENMP
#pragma omp parallel private(id)
#endif

  {
#ifdef ERT_OPENMP
    id            = omp_get_thread_num();
    *nthreads_ptr = omp_get_num_threads();
#endif

#if ERT_GPU
    setGPU(id);
#elif ERT_OCL
    // Define the Platform and determine the number of devices
    std::vector<cl::Platform> platforms;
    cl::Platform::get(&platforms);
    std::vector<cl::Device> devices;
    int cl_err;
    if ((cl_err = platforms[0].getDevices(DEVICE, &devices)) != CL_SUCCESS) {
      switch (cl_err) {
        case CL_INVALID_DEVICE_TYPE: 
          fprintf(stderr, "ERROR: Invalide OpenCL device type\n");
	  break;
	default:
          fprintf(stderr, "ERROR: Invalide OpenCL device not found\n");
      }
      exit(1);
    }

    // Map the Device to an id, create a Context and queue for it
    int num_devices = devices.size();
    cl::Device device = devices[id % num_devices];
    cl::Context context(device);
    cl::CommandQueue queue(context, CL_QUEUE_PROFILING_ENABLE);
    // Check that maximum working group size isn't exceeded
    size_t max_wg_size = device.getInfo<CL_DEVICE_MAX_WORK_GROUP_SIZE>();
    if (local_size > max_wg_size) {
      fprintf(stderr, "ERROR: Work group size > device maximum %ld\n", max_wg_size);
      exit(1);
    }
 
    // Build the OpenCL kernel
#ifdef ERT_FP16
  #define PRECISION "FP16"
#elif ERT_FP32
  #define PRECISION "FP32"
#else
  #define PRECISION "FP64"
#endif
    char build_args[80];
    sprintf(build_args, "Kernels/%s", ERT_KERNEL);
    cl::Program program(context, loadProgram(build_args), false);
    sprintf(build_args, "-DERT_FLOP=%d -D%s", ERT_FLOP, PRECISION);
    if (program.build(build_args) != CL_SUCCESS) {
      fprintf(stderr, "ERROR: OpenCL kernel failed to build\n");
      exit(-1);
    }
    auto ocl_kernel = cl::make_kernel<ulong, ulong, cl::Buffer, cl::Buffer>(program, "ocl_kernel");
#endif

    int nthreads   = *nthreads_ptr;
    uint64_t nsize = PSIZE / nthreads;
    nsize          = nsize & (~(ERT_ALIGN - 1));
    nsize          = nsize / sizeof(T);
    uint64_t nid   = nsize * id;

#if ERT_GPU
    T *d_buf = setDeviceData<T>(nsize);
    cudaDeviceSynchronize();
#elif ERT_OCL
    int params[2];
    cl::Buffer d_params(context, CL_MEM_READ_WRITE, sizeof(params));
    cl::Buffer d_buf(context, CL_MEM_READ_WRITE, sizeof(T) * nsize);
#else
    T *d_buf = nullptr;
#endif

#if defined (ERT_GPU)
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
#elif ERT_OCL
    cl::Event event;
#else
    double startTime, endTime;
#endif
    uint64_t n, nNew;
    uint64_t t;
    int bytes_per_elem;
    int mem_accesses_per_elem;

    n = ERT_WORKING_SET_MIN;
    while (n <= nsize) { // working set - nsize

      uint64_t ntrials = nsize / n;
      if (ntrials < ERT_TRIALS_MIN)
        ntrials = ERT_TRIALS_MIN;

      // initialize small chunck of buffer within each thread
      double value = -1.0;
      initialize<T>(nsize, &buf[nid], value);

#ifdef ERT_GPU
      cudaMemcpy(d_buf, &buf[nid], n * sizeof(T), cudaMemcpyHostToDevice);
      cudaDeviceSynchronize();
#elif  ERT_OCL
      cl::copy(queue, &buf[nid], &buf[nid] + n, d_buf);
#endif

      for (t = 1; t <= ntrials; t = t * 2) { // working set - ntrials
#ifdef ERT_MPI
#ifdef ERT_OPENMP
#pragma omp master
#endif
        {
          MPI_Barrier(MPI_COMM_WORLD);
        }
#endif // ERT_MPI

#ifdef ERT_OPENMP
#pragma omp barrier
#endif

        if ((id == 0) && (rank == 0)) {
#if defined (ERT_GPU)
          cudaEventRecord(start);
#elif ERT_OCL
#else
          startTime = getTime();
#endif
        }

#ifdef ERT_OCL
        launchKernel(ocl_kernel, n, t, queue, d_buf, d_params, &event);
        queue.finish();
	event.wait();
#else
        launchKernel<T>(n, t, nid, buf, d_buf, &bytes_per_elem, &mem_accesses_per_elem);
#endif

#ifdef ERT_OPENMP
#pragma omp barrier
#endif

#ifdef ERT_MPI
#ifdef ERT_OPENMP
#pragma omp master
#endif
        {
          MPI_Barrier(MPI_COMM_WORLD);
        }
#endif // ERT_MPI

        if ((id == 0) && (rank == 0)) {
#if defined (ERT_GPU)
          cudaEventRecord(stop);
#elif ERT_OCL
#else
          endTime   = getTime();
#endif
        }

#if ERT_GPU
        //cudaMemcpy(&buf[nid], d_buf, n * sizeof(T), cudaMemcpyDeviceToHost);
        cudaDeviceSynchronize();
#elif  ERT_OCL
        cl::copy(queue, d_params, params, params + 2);
        bytes_per_elem = params[0];
        mem_accesses_per_elem = params[1];
	//cl::copy(queue, d_buf, &buf[nid], &buf[nid] + n);
#endif

        if ((id == 0) && (rank == 0)) {
          uint64_t working_set_size = n * nthreads * nprocs;
          uint64_t total_bytes      = t * working_set_size * bytes_per_elem * mem_accesses_per_elem;
          uint64_t total_flops      = t * working_set_size * ERT_FLOP;
          double seconds;

          // nsize; trials; microseconds; bytes; single thread bandwidth; total bandwidth
#if defined (ERT_GPU)
          cudaEventSynchronize(stop);
          float milliseconds = 0.f;
          cudaEventElapsedTime(&milliseconds, start, stop);
          seconds = static_cast<double>(milliseconds) / 1000.;
#elif ERT_OCL
	  seconds = (double)(event.getProfilingInfo<CL_PROFILING_COMMAND_END>() 
	            - event.getProfilingInfo<CL_PROFILING_COMMAND_START>()) * 1e-9;
#else
          endTime   = getTime();
          seconds   = endTime - startTime;
#endif
          printf("%12" PRIu64 " %12" PRIu64 " %15.3lf %12" PRIu64 " %12" PRIu64 "\n", working_set_size * bytes_per_elem,
                 t, seconds * 1000000, total_bytes, total_flops);
        } // print

      } // working set - ntrials

      nNew = ERT_WSS_MULT * n;
      if (nNew == n) {
        nNew = n + 1;
      }

      n = nNew;
    } // working set - nsize

#if ERT_GPU
    cudaFree(d_buf);

    if (cudaGetLastError() != cudaSuccess) {
      printf("Last GPU error: %s\n", cudaGetErrorString(cudaGetLastError()));
    }

    cudaDeviceReset();
#endif
  } // parallel region
}

int main(int argc, char *argv[])
{
#if ERT_GPU
  if (argc != 3) {
    fprintf(stderr, "Usage: %s gpu_blocks gpu_threads\n", argv[0]);
    return -1;
  }

  gpu_blocks  = atoi(argv[1]);
  gpu_threads = atoi(argv[2]);
#elif ERT_OCL
  if (argc == 2) {                   // Usage: driver local_size
    global_size = 0;
    local_size = atoi(argv[1]);
  }
  else if ( argc == 3 ) {            // Usage: driver global_size local_size
    global_size = atoi(argv[1]);
    local_size  = atoi(argv[2]);
  }
  else {                             // No args, let the OpenCL runtime decide
    global_size = 0;
    local_size = 0;
  }
#endif

  int rank     = 0;
  int nprocs   = 1;
  int nthreads = 1;
#ifdef ERT_MPI
  int provided = -1;
  int requested;

#ifdef ERT_OPENMP
  requested = MPI_THREAD_FUNNELED;
  MPI_Init_thread(&argc, &argv, requested, &provided);
#else
  MPI_Init(&argc, &argv);
#endif // ERT_OPENMP

  MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  /* printf("The MPI binding provided thread support of: %d\n", provided); */
#endif // ERT_MPI

  uint64_t TSIZE = ERT_MEMORY_MAX;
  uint64_t PSIZE = TSIZE / nprocs;

#if ERT_GPU && ERT_FP16
  half2 *hlfbuf = alloc<half2>(PSIZE);
  checkBuffer(hlfbuf);
  run<half2>(PSIZE, hlfbuf, rank, nprocs, &nthreads);
  free(hlfbuf);
#endif

#ifdef ERT_FP32
#ifdef ERT_GPU
  float *sglbuf = alloc<float>(PSIZE);
#else
  float *__restrict__ sglbuf = alloc<float>(PSIZE);
#endif
  checkBuffer(sglbuf);
  run<float>(PSIZE, sglbuf, rank, nprocs, &nthreads);
#ifdef ERT_INTEL
  _mm_free(sglbuf);
#else
  free(sglbuf);
#endif
#endif

#ifdef ERT_FP64
#ifdef ERT_GPU
  double *dblbuf = alloc<double>(PSIZE);
#else
  double *__restrict__ dblbuf = alloc<double>(PSIZE);
#endif
  checkBuffer(dblbuf);
  run<double>(PSIZE, dblbuf, rank, nprocs, &nthreads);
#ifdef ERT_INTEL
  _mm_free(dblbuf);
#else
  free(dblbuf);
#endif
#endif

#ifdef ERT_MPI
  MPI_Barrier(MPI_COMM_WORLD);
#endif

  if (rank == 0) {
    printf("\n");
    printf("META_DATA\n");
    printf("FLOPS          %d\n", ERT_FLOP);

#ifdef ERT_MPI
    printf("MPI_PROCS      %d\n", nprocs);
#endif

#ifdef ERT_OPENMP
    printf("OPENMP_THREADS %d\n", nthreads);
#endif

#ifdef ERT_GPU
    printf("GPU_BLOCKS     %d\n", gpu_blocks);
    printf("GPU_THREADS    %d\n", gpu_threads);
#endif

#ifdef ERT_OCL
    printf("GLOBAL_SIZE    %ld\n", global_size);
    printf("LOCAL_SIZE     %ld\n", local_size);
#endif
  }

#ifdef ERT_MPI
  MPI_Finalize();
#endif

  return 0;
}
