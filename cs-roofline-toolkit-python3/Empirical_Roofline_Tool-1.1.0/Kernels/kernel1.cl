/* OpenCL ERT kernel */

#define REP2(S)        S ;        S
#define REP4(S)   REP2(S);   REP2(S)
#define REP8(S)   REP4(S);   REP4(S)
#define REP16(S)  REP8(S);   REP8(S)
#define REP32(S)  REP16(S);  REP16(S)
#define REP64(S)  REP32(S);  REP32(S)
#define REP128(S) REP64(S);  REP64(S)
#define REP256(S) REP128(S); REP128(S)
#define REP512(S) REP256(S); REP256(S)

#define KERNEL1(a,b,c)   ((a) = (b) + (c))
#define KERNEL2(a,b,c)   ((a) = (a)*(b) + (c))

#ifdef FP16
void kernel1(__global half* A, const ulong nsize) {
#elif FP32
void kernel1(__global float* A, const ulong nsize) {
#else
void kernel1(__global double* A, const ulong nsize) {
#endif

  size_t total_thr = get_num_groups(0) * get_local_size(0);
  size_t elem_per_thr = (nsize + (total_thr-1)) / total_thr;	
  size_t blockOffset = get_group_id(0)  * get_local_size(0) ;

  size_t start_idx  = blockOffset + get_local_id(0) ;
  size_t end_idx    = start_idx + elem_per_thr * total_thr;
  size_t stride_idx = total_thr;

  if (start_idx > nsize) {
    start_idx = nsize;
  }

  if (end_idx > nsize) {
    end_idx = nsize;
  }

  // A needs to be initilized to -1 coming in
  // And with alpha=2 and beta=1, A=-1 is preserved upon return
#ifdef FP16
  half alpha = 2.0;
  half beta = 1.0;
#elif FP32
  float alpha = 2.0;
  float beta = 1.0;
#else
  double alpha = 2.0;
  double beta = 1.0;
#endif
  size_t i, j;
    for (i = start_idx; i < end_idx; i += stride_idx) {
      beta = 1.0;
#if (ERT_FLOP & 1) == 1       /* add 1 flop */
      KERNEL1(beta,A[i],alpha);
#endif
#if (ERT_FLOP & 2) == 2       /* add 2 flops */
      KERNEL2(beta,A[i],alpha);
#endif
#if (ERT_FLOP & 4) == 4       /* add 4 flops */
      REP2(KERNEL2(beta,A[i],alpha));
#endif
#if (ERT_FLOP & 8) == 8       /* add 8 flops */
      REP4(KERNEL2(beta,A[i],alpha));
#endif
#if (ERT_FLOP & 16) == 16     /* add 16 flops */
      REP8(KERNEL2(beta,A[i],alpha));
#endif
#if (ERT_FLOP & 32) == 32     /* add 32 flops */
      REP16(KERNEL2(beta,A[i],alpha));
#endif
#if (ERT_FLOP & 64) == 64     /* add 64 flops */
      REP32(KERNEL2(beta,A[i],alpha));
#endif
#if (ERT_FLOP & 128) == 128   /* add 128 flops */
      REP64(KERNEL2(beta,A[i],alpha));
#endif
#if (ERT_FLOP & 256) == 256   /* add 256 flops */
      REP128(KERNEL2(beta,A[i],alpha));
#endif
#if (ERT_FLOP & 512) == 512   /* add 512 flops */
      REP256(KERNEL2(beta,A[i],alpha));
#endif
#if (ERT_FLOP & 1024) == 1024 /* add 1024 flops */
      REP512(KERNEL2(beta,A[i],alpha));
#endif

      A[i] = -beta;
    }
}

__kernel void ocl_kernel(
            const ulong nsize,
	    const ulong trials,
#ifdef FP16
            __global half* A,
#elif FP32
            __global float* A,
#else
            __global double* A,
#endif
	    __global int* params)
{
  for (ulong j=0; j<trials; ++j)
    kernel1(A, nsize);

  params[0] = sizeof(*A);
  params[1] = 2;
}
