#include <mma.h>

using namespace nvcuda;

// Must be multiples of 16 for wmma code to work
#define MATRIX_M 16384
#define MATRIX_N 16384
#define MATRIX_K 16384

// The only dimensions currently supported by WMMA
const uint32_t WMMA_M = 16;
const uint32_t WMMA_N = 16;
const uint32_t WMMA_K = 16;

__global__ void kernel_tensor(half *a, half *b, float *c, uint32_t M, uint32_t N, uint32_t K, float alpha, float beta)
{
  // Leading dimensions. Packed with no transpositions.
  uint32_t lda = M;
  uint32_t ldb = K;
  uint32_t ldc = M;

  // Tile using a 2D grid
  uint32_t warpM = (blockIdx.x * blockDim.x + threadIdx.x) / warpSize;
  uint32_t warpN = (blockIdx.y * blockDim.y + threadIdx.y);

  wmma::fragment<wmma::matrix_a, WMMA_M, WMMA_N, WMMA_K, half, wmma::col_major> a_frag;
  wmma::fragment<wmma::matrix_b, WMMA_M, WMMA_N, WMMA_K, half, wmma::col_major> b_frag;
  wmma::fragment<wmma::accumulator, WMMA_M, WMMA_N, WMMA_K, float> acc_frag;
  wmma::fragment<wmma::accumulator, WMMA_M, WMMA_N, WMMA_K, float> c_frag;

  // Loop over k
  for (int i = 0; i < K; i += WMMA_K) {
    int aRow = warpM * WMMA_M;
    int aCol = i;

    int bRow = i;
    int bCol = warpN * WMMA_N;

    // Bounds checking
    if (aRow < M && aCol < K && bRow < K && bCol < N) {
      // Load the inputs
      wmma::load_matrix_sync(a_frag, a + aRow + aCol * lda, lda);
      wmma::load_matrix_sync(b_frag, b + bRow + bCol * ldb, ldb);

      // Perform the matrix multiplication
      wmma::mma_sync(acc_frag, a_frag, b_frag, acc_frag);
    }
  }

  // Load in the current value of c, scale it by beta, and add this our result scaled by alpha
  int cRow = warpM * WMMA_M;
  int cCol = warpN * WMMA_N;

  if (cRow < M && cCol < N) {
    wmma::load_matrix_sync(c_frag, c + cRow + cCol * ldc, ldc, wmma::mem_col_major);

    for (int i = 0; i < c_frag.num_elements; i++)
      c_frag.x[i] = alpha * acc_frag.x[i] + beta * c_frag.x[i];

    // Store the output
    wmma::store_matrix_sync(c + cRow + cCol * ldc, c_frag, ldc, wmma::mem_col_major);
  }
}
