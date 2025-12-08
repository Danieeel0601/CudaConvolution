#include <stdlib.h>
#include <iostream>
#include <FreeImage.h>

/* Programa de tratamiento de imágenes.
 
   Carga una imagen .jpg en formato de escala de grises
   (8 bits por pixel que equivale a unsigned char)
 
   Le aplica una matriz de convolución para darle un efecto a la imagen
   y la guarda con un nombre diferente.

   La matriz convolucion para efecto negativo aplicada es:
   0   1   0
   1  -5   1
   0   1   0
   donde para cada elemento (i,j) de la imagen se calcula 
   pixel[i][j] = pixel[i-1][j] + pixel[i+1][j] 
               + pixel[i][j-1] + pixel[i][j+1] 
      			   - 5*pixel[i][j]

Compilar con:
      (g++ | nvcc) <archivo_fuente> -lfreeimage -o <archivo_objeto>
*/

int main()
{
	int ancho, alto, dimension;
	int i, j;
	FIBITMAP *foto;
	BYTE *bits, *pixel;
	char archivo[20];

//inicializaciòn de FreeImage	
	FreeImage_Initialise();

// carga el archivo foto.jpg en escala de grises en la estructura foto
// y obtiene sus dimensiones
	foto = FreeImage_Load(FIF_JPEG, "images/input/foto.jpg", JPEG_GREYSCALE);
	ancho = FreeImage_GetWidth(foto);
	alto = FreeImage_GetHeight(foto);
	dimension = ancho * alto;

// almacena el contenido del arreglo foto en el archivo fotogris.jpg
	FreeImage_Save(FIF_JPEG, foto, "images/output/fotogris_seq.jpg",0);

// Reserva la memoria correspondiente a la foto resultado
	FIBITMAP *fotoconv = FreeImage_Allocate(ancho, alto, 8);

// obtiene la secuencia de byte de los pixeles
//bits contiene los valores de los pixeles de entrada
//pixel contiene los valores de los pixeles transformados
  bits = (BYTE *) FreeImage_GetBits(foto);
	pixel = (BYTE *) FreeImage_GetBits(fotoconv);

// aplicacion de la matriz convolución	
	for (i=1; i<alto-1; i++)
		for (j=1; j<ancho-1; j++)
			pixel[i*ancho+j] = bits[(i-1)*ancho+j]+bits[(i+1)*ancho+j]+bits[i*ancho+j-1]+bits[i*ancho+j+1]-5*bits[i*ancho+j];

//Guardar el arreglo de pixeles resultante en el archivo fotoconv.jpg
	FreeImage_Save(FIF_JPEG, fotoconv, "images/output/fotoconv_seq.jpg",0);

// terminaciòn de FreeImage
	FreeImage_DeInitialise();
}
