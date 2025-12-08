# Compilers
CXX = g++
NVCC = nvcc

# Directories
SRC_DIR = src
BIN_DIR = bin

# Flags
# Assumes FreeImage headers are in standard system paths (e.g., /usr/include)
CXXFLAGS = -Iinclude -O3
NVCCFLAGS = -Iinclude -O3

# Libraries
# Links against system-installed FreeImage
LIBS = -lfreeimage -lpthread

# Files
SEQ_SRC = $(SRC_DIR)/convol-seq.cpp
CUDA_SRC = $(SRC_DIR)/convol_cuda.cu

SEQ_EXE = $(BIN_DIR)/convol_seq
CUDA_EXE = $(BIN_DIR)/convol_cuda

# --- Rules ---

all: folders seq cuda

folders:
	@mkdir -p $(BIN_DIR)
	@mkdir -p images/output

seq: $(SEQ_SRC)
	$(CXX) $(CXXFLAGS) -o $(SEQ_EXE) $(SEQ_SRC) $(LIBS)
	@echo "Sequential Compiled: $(SEQ_EXE)"

cuda: $(CUDA_SRC)
	$(NVCC) $(NVCCFLAGS) -o $(CUDA_EXE) $(CUDA_SRC) $(LIBS)
	@echo "CUDA Compiled: $(CUDA_EXE)"

clean:
	rm -f $(BIN_DIR)/*

help:
	@echo "Options: make seq, make cuda, make all, make clean"
