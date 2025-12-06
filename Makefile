# Compiladores
CXX = g++
NVCC = nvcc

# Flags de compilación
# -Iinclude busca archivos .h en la carpeta include/
# -O3 optimiza el código para máximo rendimiento
CXXFLAGS = -Iinclude -O3
NVCCFLAGS = -Iinclude -O3

# Librerías
# -lfreeimage enlaza con la librería FreeImage instalada en el sistema
LIBS = -lfreeimage

# Directorios
SRC_DIR = src
BIN_DIR = bin

# Nombres de los archivos fuente y ejecutables
# Ajusta 'convol_cuda.cu' al nombre real de tu archivo CUDA cuando lo crees
SEQ_SRC = $(SRC_DIR)/convol-seq.cpp
CUDA_SRC = $(SRC_DIR)/convol_cuda.cu

SEQ_EXE = $(BIN_DIR)/convol_seq
CUDA_EXE = $(BIN_DIR)/convol_cuda

# --- Reglas ---

# Regla por defecto: intenta compilar ambos
all: folders seq cuda

# Crear directorio bin si no existe
folders:
	@mkdir -p $(BIN_DIR)

# Compilar versión Secuencial (CPU)
seq: $(SEQ_SRC)
	$(CXX) $(CXXFLAGS) -o $(SEQ_EXE) $(SEQ_SRC) $(LIBS)
	@echo "--> Compilación secuencial exitosa: $(SEQ_EXE)"

# Compilar versión Paralela (CUDA)
# Nota: Esta regla fallará si aun no has creado el archivo .cu en src/
cuda: $(CUDA_SRC)
	$(NVCC) $(NVCCFLAGS) -o $(CUDA_EXE) $(CUDA_SRC) $(LIBS)
	@echo "--> Compilación CUDA exitosa: $(CUDA_EXE)"

# Limpiar ejecutables
clean:
	rm -f $(BIN_DIR)/*

# Regla de ayuda
help:
	@echo "Opciones disponibles:"
	@echo "  make seq   -> Compila solo la versión secuencial"
	@echo "  make cuda  -> Compila solo la versión CUDA"
	@echo "  make all   -> Compila todo"
	@echo "  make clean -> Elimina los ejecutables"
