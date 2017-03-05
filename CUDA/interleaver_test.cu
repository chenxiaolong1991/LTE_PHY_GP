/*
% Function:		interleaver
% Description:	Interleaves ULSCH data with RI and ACK control information
% Inputs:		input_h 			Input bits
%				ri_h				RI control bits to interleave
% 				ack_h				ACK control bits to interleave
%				N_l					Number of layers
%				Qm					Number of bits per modulation symbol
% Outputs:		*output_h			Output bits
By: Ahmad Nour
*/

#include "interleaver.cuh"

int main(int argc, char **argv) {
	
	//Init. the input data (generated using this MATLAB code)
	/*
	rng(10);
	N_l = 1;            % Number of Layers
	Q_m = 6;            % Modulation Order(2 = QPSK, 4 = 16QAM, 6 = 64QAM)
	N_ri_bits = 12;     % #RI bit(Should be multiples of 12)
						% as the # of columns of the constructed matrix = 12

	data_bits = randi([0 1], 1, 1728);
	ri_bits = randi([0 1], 1, N_ri_bits);
	*/

	const int N_l = 1;            // Number of Layers
	const int Qm = 6;			  // Modulation Order(2 = QPSK, 4 = 16QAM, 6 = 64QAM)

	const Byte input_h[] = { 1,0,1,1,0,0,0,1,0,0,1,1,0,1,1,1,1,0,1,1,1,0,0,1,0,0,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1,0,1,0,1,0,1,0,0,0,0,1,0,0,1,1,0,1,0,1,1,1,1,0,0,0,0,0,1,0,0,0,1,0,0,1,1,1,0,1,1,1,0,0,0,0,0,1,1,0,0,0,1,0,0,1,0,0,1,1,1,0,0,1,1,1,0,0,1,0,1,1,0,0,0,0,0,1,0,0,1,0,1,0,1,0,0,1,0,0,1,0,0,1,1,1,1,0,1,1,1,1,1,1,1,0,0,1,0,0,0,1,1,0,1,1,1,0,0,0,0,0,0,1,1,0,0,1,1,1,1,1,1,1,0,1,0,0,1,0,1,0,0,1,1,0,0,0,0,0,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,1,1,1,0,1,1,0,1,0,0,0,0,0,0,1,0,0,1,0,0,1,0,1,0,1,1,1,1,0,0,0,1,1,0,0,1,0,0,1,1,0,1,0,1,0,1,1,1,0,0,1,1,1,0,0,0,1,1,0,0,1,1,1,1,1,1,0,0,0,1,0,1,0,1,0,1,1,0,0,1,0,0,0,0,1,0,1,1,1,1,1,0,0,1,0,1,1,1,0,0,0,1,1,0,1,1,0,1,1,1,0,0,0,1,0,0,1,0,0,1,1,0,0,1,0,0,1,1,1,1,0,1,1,1,1,1,1,0,1,0,0,1,1,1,1,0,1,0,0,0,1,1,1,0,0,1,1,0,0,1,0,1,1,0,1,0,1,0,1,1,1,0,1,0,0,1,1,1,0,0,0,1,0,0,0,0,0,0,1,0,1,0,0,0,1,1,1,1,1,0,1,1,1,1,0,0,1,1,1,0,1,1,0,0,0,0,0,1,1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,0,0,0,1,1,1,0,1,0,1,1,1,0,1,1,0,0,1,1,0,0,0,0,1,1,0,0,1,0,1,1,1,1,0,1,1,1,1,0,0,0,0,0,1,1,1,1,0,1,1,0,0,0,1,0,0,1,0,1,0,0,0,0,0,1,1,0,0,0,0,1,1,0,1,1,0,0,1,1,0,0,1,1,0,1,1,1,1,1,0,0,1,0,1,0,0,1,0,0,1,0,0,0,0,0,1,1,0,0,0,1,1,1,0,1,1,1,1,1,0,0,1,0,0,0,1,0,0,0,0,0,1,1,0,0,0,1,1,1,0,0,1,0,1,0,1,0,1,0,1,0,0,0,0,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,0,1,1,0,1,0,1,0,1,1,0,0,0,1,1,0,0,0,1,0,0,0,0,1,1,1,1,0,1,0,0,1,0,1,1,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,0,1,1,1,0,1,1,1,0,0,0,1,1,0,1,1,1,1,1,1,0,1,1,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,1,1,1,1,1,1,0,0,1,0,1,1,0,0,0,0,1,1,0,1,1,0,1,0,1,1,0,1,0,0,1,1,1,1,0,1,0,1,0,0,1,0,1,0,1,1,1,1,1,0,0,0,1,1,1,1,1,1,0,1,1,0,1,1,0,1,0,1,1,0,1,1,0,1,1,1,1,0,1,1,0,0,0,0,0,1,0,0,1,1,0,1,1,1,0,1,1,1,1,1,1,0,0,0,0,1,0,0,1,1,0,1,1,1,0,1,1,1,0,0,0,1,0,0,0,1,0,1,1,0,0,0,0,0,0,1,0,1,0,1,0,1,0,0,1,0,0,1,1,0,1,1,0,0,1,1,1,0,0,0,0,0,1,0,1,1,0,0,0,0,1,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,0,1,1,0,0,0,0,1,0,0,1,0,0,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,1,0,0,0,0,0,1,1,1,1,1,0,1,1,0,1,1,0,0,1,1,1,0,1,0,1,0,0,1,0,0,0,0,1,0,0,0,0,1,0,1,0,0,0,1,0,1,0,1,0,0,0,0,0,0,1,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,1,0,0,1,0,0,1,0,1,0,0,1,0,1,0,1,1,1,1,0,1,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,1,0,1,1,0,0,1,1,0,0,0,0,0,0,0,1,1,1,0,1,0,1,0,0,0,1,1,1,0,0,0,1,1,0,1,0,1,1,1,1,0,1,0,0,1,0,1,1,1,1,1,1,0,0,0,0,0,1,0,1,1,1,0,0,1,0,1,0,0,0,1,0,1,1,0,0,1,1,1,1,1,0,1,0,0,0,0,0,1,1,0,1,0,0,1,1,1,0,1,1,0,0,0,1,1,0,0,1,1,0,1,0,0,0,0,0,0,0,0,1,1,1,1,0,1,0,0,0,1,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,1,0,0,0,0,1,1,1,1,1,1,0,0,0,0,1,1,0,1,1,1,1,1,0,1,0,0,1,1,0,0,1,0,1,1,0,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0,1,0,0,1,1,1,0,0,1,1,1,1,0,0,1,0,1,1,0,0,0,1,1,1,1,0,1,1,0,0,0,1,0,1,0,0,0,1,0,1,0,0,1,1,0,1,1,1,0,1,1,0,1,0,1,1,0,1,0,1,0,0,1,1,0,0,0,1,0,1,0,0,0,1,0,1,1,0,0,0,0,0,0,1,0,1,1,0,1,0,1,0,0,0,0,0,0,0,0,1,0,0,1,1,1,1,1,1,0,0,1,0,1,1,1,0,1,1,0,1,0,1,1,0,0,1,0,1,1,0,1,0,1,0,1,0,1,1,0,0,0,1,0,1,0,0,0,1,1,1,1,0,1,1,1,1,0,1,0,1,1,0,0,0,0,0,1,0,1,0,1,1,0,1,0,0,1,0,1,1,1,0,1,1,0,1,1,0,1,1,0,0,1,0,1,0,1,0,0,1,0,1,1,0,0,0,1,1,1,0,1,0,0,1,0,0,1,0,1,1,1,1,0,1,1,1,1,0,1,1,1,0,0,1,0,1,1,0,0,1,1,1,0,1,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,0,1,0,0,1,0,0,1,0,0,0,1,1,1,0,1,1,0,1,1,0,0,1,1,1,0,1,1,0,1,1,1,0,1,1,0,0,1,1,0,0,1,0,0,1,1,1,1,0,0,0,0,0,0,0,1,0,1,1,1,1,1,1,1,0,0,0,1,0,0,1,0,1,0,1,0,1,1,1,0,1,0,0,0,0,1,1,0,1,1,0,0,0,0,0,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,1,0,1,1,0,1,1,1,0,0,0,1,1,1,1,0,1,0,0,1,0,1,1,1,0,0,0,0,1,0,0,0,1,1,0,0,1,1,0,1,0,1,1,0,0,0,0,0,0,1,1,1,0,0,1,1,0,0,1,0,0,1,0,0,1,1,1,1,0,0,0,1,1,1,1,1,0,1,0,0,0,1,1,0,1,0,1,1,0,1,1,0,1,0,0,1,0,0,0,0,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,0,1,0,0,0,0,1,0,1,0 };
	const Byte ri_h[] = { 1,1,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,1,0,1,1,0,1,0,1,1,1,1,1,1,1,0,1,0,0,0,1,0,0,0,1,1,1,1,1,1,1,1,0,1,0,0,0,1,0,0,0,0,1,0,1,0 };
	const int N = sizeof(input_h) / sizeof(input_h[0]);				//length of input
	const int N_ri = sizeof(ri_h) / sizeof(ri_h[0]);				//length of ri

	//For output:
	Byte *output_h = 0;

	//Call the interleaver Function
	interleaver(input_h, ri_h, &output_h, N, N_ri, Qm, N_l);

	//Print results
	for (int i = 0; i < (N+N_ri); i++)
		printf("idx = %d \t %d\n", i + 1, output_h[i]);

	printf("\n\n");

	//To compare with MATLAB results
	//Run the file (interleaver_Results.m)
	FILE *results;
	if ((results = freopen("interleaver_Results.m", "w+", stdout)) == NULL) {
		printf("Cannot open file.\n");
		exit(1);
	}

	printf("clear; clc;\noutput = [ ");
	for (int i = 0; i < (N+N_ri); i++)
	{
		printf("%d", output_h[i]);
		if (i != (N + N_ri - 1))
			printf(",");
	}

	printf(" ];\n");

	//Matlab code
	printf("rng(10);\nN_l = 1;\nQ_m = 6;\nN_ri_bits = 12;\ndata_bits = randi([0 1],1,1728);\nri_bits = randi([0 1],1,N_ri_bits*Q_m*N_l);\nack_bits = [];\noutput_MATLAB = channel_interleaver(data_bits, ri_bits, ack_bits, N_l, Q_m);\nsum(abs(output_MATLAB-output))");
	fclose(results);
}