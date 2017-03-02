/*
This function is used to read the bits from a text file and return the number of bits as well.
If no argument is passed, it will try to read from the same directory from the file "input.txt".
Bits should be in one line with no spaces, for example: (100011110)
To do so in MATLAB, use this command:

dlmwrite('output.txt',Variable_to_Print,'delimiter','');

By: Ahmad Nour
*/

#include "input.cuh"

BYTE* readBits(int argc, char* argv, int *numBits)
{

	FILE *inputFile;
	char* path = "input.txt";

	if (argc >= 2)		//a path is given, use it instead
		path = argv;

	if ((inputFile = fopen(path, "r+")) == NULL) {
		printf("Cannot open file.\n");
		exit(1);
	}

	fseek(inputFile, 0, SEEK_END);
	long N = ftell(inputFile);
	fseek(inputFile, 0, SEEK_SET);

	BYTE* inputBits = (BYTE*)malloc(sizeof(BYTE)* N);

	fread(inputBits, sizeof(BYTE), N, inputFile);

	fclose(inputFile);

	*numBits = N;
	return inputBits;

}
