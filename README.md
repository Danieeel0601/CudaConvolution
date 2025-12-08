# CUDA Image Convolution

This project implements image convolution filters (blur, sharpen, edge detection) using both a Sequential C++ implementation and a Parallel CUDA implementation for performance comparison.

## Requirements

*   **Linux/Unix** OS (Recommended)
*   **CUDA Toolkit** (for compiling the GPU version)
*   **FreeImage Library**

### Installing Dependencies (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install libfreeimage-dev
```

## Structure

*   `src/`: Source code (`convol_cuda.cu`, `convol-seq.cpp`).
*   `bin/`: Compiled executables (generated).
*   `images/input/`: Place your input images here (default: `foto.jpg`).
*   `images/output/`: Processed images will appear here.

## Compilation

Use the provided `Makefile` to compile the project.

```bash
# Compile both sequential and CUDA versions
make all

# Compile only Sequential
make seq

# Compile only CUDA
make cuda

# Clean binaries
make clean
```

## Usage

### CUDA Version

```bash
./bin/convol_cuda [filter_name]
```

Available filters:
*   `negative` (default)
*   `blur`
*   `sharpen`

Example:
```bash
./bin/convol_cuda blur
```

### Sequential Version

```bash
./bin/convol_seq
```
*(Currently, the sequential version applies a fixed negative/edge effect as defined in the code).*

## Performance

The CUDA implementation uses dynamic shared memory and constant memory caching for the convolution mask to optimize performance significantly over the sequential CPU version.