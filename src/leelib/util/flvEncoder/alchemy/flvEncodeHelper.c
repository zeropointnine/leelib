#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "AS3.h"
 
static unsigned char* buffer;
int bufferSize;

int width;
int height;

static unsigned char* output;
int outputLength;

const int BLOCK_WIDTH = 32;
const int BLOCK_HEIGHT = 32;

static AS3_Val initBuffer(void* self, AS3_Val args)
{ 
	AS3_ArrayValue(args, "IntType, IntType", &width, &height);
	
	// Allocate buffer of size "bufferSize"
	bufferSize = width * height * 4;
 	buffer = (unsigned char*)malloc(bufferSize*sizeof(char));
	
	// Also the helper array used in makeImageBlocks()
	outputLength = width * height * 3;
	output = (unsigned char*)malloc(outputLength);
	
 
	//return pointer to the location in memory
	return AS3_Int((int)buffer);
}


// NOT USING THIS
static AS3_Val writeData(void* self, AS3_Val args)
{
	char *tempBuffer;
	AS3_ArrayValue(args, "StrType", &tempBuffer);
 
	//copy string to buffer
	strcpy((char*)buffer, (char*)tempBuffer);
 
	return AS3_String((char*)tempBuffer);
}

static AS3_Val clearBuffer(void* self, AS3_Val args)
{
	//free the buffer
	free(buffer);
	*buffer = 0;
	return 0;
}

/*
	Makes all image blocks that make up a frame in one 
	flattened ByteArray plus an array of offset indicies, which 
	will then be handed off to Flash for final assembly of the
	FLV video frame.
	
	(Each image block needs to be compressed, which will be done
	on the Flash side, taking advantage of Flash Player's 'native'
	zlib compress routine)
	
	(General strategy is to minimize context switching between
	Alchemy and Flash)
	
	Argument 1: ByteArray which will take image data result
	
	Argument 2: ByteArray of unsigned shorts that are indices of
				each of the image blocks	
*/
static AS3_Val makeImageBlocks(void* self, AS3_Val args)
{
	AS3_Val asOutput = AS3_GetS(args, "0");
	AS3_Val asIndices = AS3_GetS(args, "1");
	
	// unsigned char * output = (unsigned char*)malloc(outputLength);
	
	int idx = 0;
	int count = 0;
	
	int rowMax = (int)(height / BLOCK_HEIGHT);
	int rowRemainder = height % BLOCK_HEIGHT; 
	if (rowRemainder > 0) rowMax += 1;
	
	int colMax = (int)(width / BLOCK_WIDTH);
	int colRemainder = width % BLOCK_WIDTH;				
	if (colRemainder > 0) colMax += 1;

	int indicesLength = rowMax * colMax;
	unsigned char * indices = (unsigned char*)malloc(indicesLength*2);
	
	int row;
	for (row = 0; row < rowMax; row++)
	{
		int col;
		for (col = 0; col < colMax; col++) 
		{
			int xStart = col * BLOCK_WIDTH;
			int xLimit = (colRemainder > 0 && col + 1 == colMax) ? colRemainder : BLOCK_WIDTH;
			int xEnd = xStart + xLimit;
			
			int yStart = height - (row * BLOCK_HEIGHT); // * goes from bottom to top
			int yLimit = (rowRemainder > 0 && row + 1 == rowMax) ? rowRemainder : BLOCK_HEIGHT;	
			int yEnd = yStart - yLimit;

			int pos = idx;
			
			int y;
			for (y = yStart-1; y >= yEnd; y--)
			{
				int off = (y * width * 4) + (xStart * 4)  +  1; // "+1" means R byte instead of A byte

				int x;
				for (x = xStart; x < xEnd; x++)
				{
					output[idx++] = buffer[off+2];
					output[idx++] = buffer[off+1];
					output[idx++] = buffer[off  ];
					
					off += 4;
				}
			}

			// Creating an unsigned short that won't get garbled across the bridge
			// (Not 100% sure it's necessary to do it this way)
			int len = idx - pos;
			indices[count++] = (unsigned char) (len >> 8);
			indices[count++] = (unsigned char) (len & 0xFF);
		}
	}
	
	AS3_ByteArray_writeBytes(asOutput, output, outputLength);
	AS3_ByteArray_writeBytes(asIndices, indices, indicesLength*2);

	// cleanup
	// (Note how we're not clearing buffer, which is just reused; must be clear()'ed at the end of use.)
	*indices = 0;
	
	AS3_Release(asOutput);
	AS3_Release(asIndices); 
	
	return AS3_Int(0);
}


// Not implemented yet (someday)
static AS3_Val makeImageBlocksAsync(void* self, AS3_Val args)
{
	flyield();
	makeImageBlocks(self, args);
}

static AS3_Val clear(void* self, AS3_Val args)
{
	free(output);
	*output = 0;
}

int main()
{
	// *** makeImageBlocksAsyncMethod() not real yet

	AS3_Val initBufferMethod = AS3_Function(NULL, initBuffer);
	AS3_Val writeDataMethod = AS3_Function(NULL, writeData);
	AS3_Val clearBufferMethod = AS3_Function(NULL, clearBuffer);
	AS3_Val makeImageBlocksMethod = AS3_Function(NULL, makeImageBlocks);
	AS3_Val makeImageBlocksAsyncMethod = AS3_Function(NULL, makeImageBlocksAsync);
	AS3_Val clearMethod = AS3_Function(NULL, clear);
 
	AS3_Val result = AS3_Object("initBuffer:AS3ValType, writeData:AS3ValType, clearBuffer:AS3ValType, makeImageBlocks:AS3ValType, makeImageBlocksAsync:AS3ValType, clear:AS3ValType", initBufferMethod, writeDataMethod, clearBufferMethod, makeImageBlocksMethod, makeImageBlocksAsyncMethod, clearMethod);
 
	AS3_Release(initBufferMethod);
	AS3_Release(writeDataMethod);
	AS3_Release(clearBufferMethod);
	AS3_Release(makeImageBlocksMethod);
	AS3_Release(makeImageBlocksAsyncMethod);
	AS3_Release(clearMethod);

	AS3_LibInit(result);
	return 0;
}

// CLEAN UPSKI