#include <stdlib.h>
#include <iostream>
#include <stdio.h>
#include <cstring>
#include <FreeImage.h>

#define MAX_MASK_WIDTH 15
#define TILE_W 16 

//Constant Memory (Reserving space for the worst case)
__constant__ int d_mask[MAX_MASK_WIDTH * MAX_MASK_WIDTH];

// --- KERNEL ---
__global__ void convolutionKernel(BYTE *d_in, BYTE *d_out, int width, int height, int maskWidth) 
{   
    // Shared dyanmic memory 
    //unsigned char = 1 byte
    extern __shared__ unsigned char smem[];

    int maskRadius = maskWidth / 2;
    // Tile width in shared memory (Tile + 2*Radio)
    int smem_w = TILE_W + 2 * maskRadius;

    // Linear indexing
    int tid = threadIdx.y * blockDim.x + threadIdx.x;
    int blockSize = blockDim.x * blockDim.y;
    int sharedSize = smem_w * smem_w;
    
    int tile_global_x = blockIdx.x * TILE_W;
    int tile_global_y = blockIdx.y * TILE_W;

    // --- LOADING ---
    for (int i = tid; i < sharedSize; i += blockSize) {
        int s_y = i / smem_w;
        int s_x = i % smem_w;
        
        int g_y = tile_global_y + s_y - maskRadius;
        int g_x = tile_global_x + s_x - maskRadius;

        // smem access as a 1D array
        if (g_y >= 0 && g_y < height && g_x >= 0 && g_x < width) {
            smem[s_y * smem_w + s_x] = d_in[g_y * width + g_x];
        } else {
            smem[s_y * smem_w + s_x] = 0;
        }
    }
    __syncthreads();

    // --- Mask application ---
    int g_out_x = tile_global_x + threadIdx.x;
    int g_out_y = tile_global_y + threadIdx.y;

    if (g_out_x < width && g_out_y < height) {
        int sum = 0;
        
        for (int ky = -maskRadius; ky <= maskRadius; ky++) {
            for (int kx = -maskRadius; kx <= maskRadius; kx++) {
                
                int s_read_y = threadIdx.y + maskRadius + ky;
                int s_read_x = threadIdx.x + maskRadius + kx;
                
                // smem access as 1D array
                int val = smem[s_read_y * smem_w + s_read_x];
                
                // Access to constant mask 
                // Mask index: (ky + radius) * width + (kx + radius)
                int maskVal = d_mask[(ky + maskRadius) * maskWidth + (kx + maskRadius)];
                
                sum += val * maskVal;
            }
        }

        // No clamping (it doesn't work )
        d_out[g_out_y * width + g_out_x] = (BYTE)sum;
    }
}

void selectFilter(const char* name, int* mask, int* width) {
    // Default 3x3
    *width = 3;
    for(int i=0; i<MAX_MASK_WIDTH*MAX_MASK_WIDTH; i++) mask[i] = 0;

    if (strcmp(name, "negative") == 0) { 
        // 3x3 Edge
        mask[1] = 1; mask[3] = 1; mask[4] = -5; mask[5] = 1; mask[7] = 1;
    } 
    else if (strcmp(name, "sharpen") == 0) {
        mask[1] = -1; mask[3] = -1; mask[4] = 5; mask[5] = -1; mask[7] = -1;
    }
    else if (strcmp(name, "blur") == 0) { 

        for(int i=0; i<9; i++) mask[i] = 1;
    }
    else {
        // Default negative
        mask[1] = 1; mask[3] = 1; mask[4] = -5; mask[5] = 1; mask[7] = 1;
    }
}

int main(int argc, char* argv[])
{
    const char* filterName = (argc > 1) ? argv[1] : "negative";

	int width, height, dimension, imgSize; 
	FIBITMAP *photo;
	BYTE *bits, *pixel;
    BYTE *d_in, *d_out; 
    float milliseconds = 0;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

	FreeImage_Initialise();
	photo = FreeImage_Load(FIF_JPEG, "images/input/foto.jpg", JPEG_GREYSCALE);
    if (!photo) { printf("Error: Could not find images/input/foto.jpg\n"); return -1; }

	width = FreeImage_GetWidth(photo);
	height = FreeImage_GetHeight(photo);
	dimension = width * height;
    imgSize = dimension * sizeof(BYTE); 

    cudaMalloc((void**) &d_in, imgSize);
    cudaMalloc((void**) &d_out, imgSize); 

	FIBITMAP *photoconv = FreeImage_Allocate(width, height, 8);
    bits = (BYTE *) FreeImage_GetBits(photo);
	pixel = (BYTE *) FreeImage_GetBits(photoconv);

    cudaMemcpy(d_in, bits, imgSize, cudaMemcpyHostToDevice); 

    // --- CONFIGURACION FILTRO ---
    int h_mask[MAX_MASK_WIDTH * MAX_MASK_WIDTH];
    int maskWidth = 3;
    selectFilter(filterName, h_mask, &maskWidth);
    
    cudaMemcpyToSymbol(d_mask, h_mask, maskWidth * maskWidth * sizeof(int));

    // --- CALCULO DE GRID Y SMEM ---
    dim3 blockSize(TILE_W, TILE_W);
    dim3 gridSize((width + TILE_W - 1) / TILE_W, (height + TILE_W - 1) / TILE_W);
    
    int maskRadius = maskWidth / 2;
    int smem_w = TILE_W + 2 * maskRadius;
    size_t sharedMemSize = smem_w * smem_w * sizeof(unsigned char);

    printf("Filter: %s (%dx%d)\n", filterName, maskWidth, maskWidth);
    printf("Shared Memory per block: %lu bytes\n", sharedMemSize);

    cudaEventRecord(start);
    // Lanzamiento con 3er argumento: Shared Mem Size
    convolutionKernel<<<gridSize, blockSize, sharedMemSize>>>(d_in, d_out, width, height, maskWidth);
    cudaEventRecord(stop);
    
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&milliseconds, start, stop);

    printf("GPU Time: %.5f ms\n", milliseconds);

    cudaMemcpy(pixel, d_out, imgSize, cudaMemcpyDeviceToHost);
	
    char outName[100];
    sprintf(outName, "images/output/fotoconv_%s.jpg", filterName);
    FreeImage_Save(FIF_JPEG, photoconv, outName, 0);

    cudaFree(d_in); cudaFree(d_out);
	FreeImage_DeInitialise();
    return 0;
}