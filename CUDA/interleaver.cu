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

__global__ void initializeMatricies(Byte* y_idx_d, Byte* y_mat_d, int N_idx, int N_mat)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;

	//initialize Matricies
	//Not to run more threads than available data
	if (idx >= N_mat)
		return;
	
	if (idx < N_idx)
	{
		y_idx_d[idx] = 100;
		y_mat_d[idx] = 0;
	}
	else
	{
		y_mat_d[idx] = 0;
	}
}

__global__ void interleaveRI(Byte* y_idx_d, Byte* y_mat_d, Byte* ri_d, int R_prime_mux, int N_ri_bits)
{

	int col = threadIdx.x;
	int row = blockIdx.y;
	int idx = row * blockDim.x + col;
	int C_mux = 12;
	int Ncol = blockDim.x;

	//Not to run more threads than available data
	if (row >= N_ri_bits)
		return;

	Byte ri_column_set[4] = { 1, 10, 7, 4 };
	//Byte ack_column_set[4] = { 2, 9, 8, 3 };

	int r = R_prime_mux - 1 - (row / 4);
	int C_ri = ri_column_set[(row % 4)];
	
	y_idx_d[r*C_mux + C_ri] = 1;
	y_mat_d[C_mux*r*Ncol + C_ri*Ncol + col] = ri_d[row * Ncol + col];

}

__global__ void interleaveData(Byte* y_idx_d, Byte* y_mat_d, Byte* input_d, int numThreads, int H_prime_total, int N_ri_bits, int Qm, int N_l)
{
	
	const int Ncol = blockDim.x;		//Total number of columns
	int col = threadIdx.x;
	int row = blockDim.y * blockIdx.y + threadIdx.y;
	int idx = row * Ncol + col;
	const int C_mux = 12;

	//Not to run more threads than available data
	if (row >= numThreads)
		return;

	int firstRI_row = H_prime_total - (N_ri_bits * 3);		// The original eqn:
															// firstRI_row = ((H_prime_total/12) - (N_N_ri_bits / 4))*12
	
	if (row < firstRI_row)		//No RI bits in this range
	{
		y_idx_d[row] = 1;
		y_mat_d[row*(Qm*N_l) + col] = input_d[row * (Qm*N_l) + col];
	}
	else
	{
		/*
		Now, we reshape the matrix to be of (12 cols):
		idx							0	1	2	3	4	5	6	7	8	9	10	11701b4032c
		Data can be put? (No RI)	yes	no	yes	yes	no	yes	yes	no	yes	yes	no	yes
		So, to map the data to indices where no RI bits exist, this equation is applied:
		col = col + (col / 2) + (col % 2);
		*/
		
		int old_mapping = (row - firstRI_row);
		int new_mapping = old_mapping + (old_mapping / 2) + (old_mapping % 2);
		int new_row = row + (new_mapping - old_mapping);

		y_idx_d[new_row] = 1;
		y_mat_d[new_row*(Qm*N_l) + col] = input_d[row * (Qm*N_l) + col];
	}
}

__global__ void serialOut(Byte* output_d, Byte* y_mat_d, int Nrows, int Qm, int N_l) {

	int x = blockDim.x * blockIdx.x + threadIdx.x;
	int y = blockDim.y * blockIdx.y + threadIdx.y;
	int z = blockDim.z * blockIdx.z + threadIdx.z;

	int idx = y * blockDim.x + x + z * (Nrows * blockDim.x);

	const int C_mux = 12;

	//Not to run more threads than available data
	if (y >= Nrows)
		return;

	output_d[idx] = y_mat_d[y*C_mux*Qm*N_l + z*Qm*N_l + x];
}

void interleaver(const Byte* input_h, const Byte* ri_h, Byte** output_h, const int N, const int N_ri, const int Qm, const int N_l)
{
	//For timing purpose
	float elapsed = 0;				//For time calc.
	cudaEvent_t start, stop;

	//Device data
	Byte *input_d, *ri_d, *output_d, *y_idx_d, *y_mat_d;

	//Reshape parameters
	int data_vec_len = Qm*N_l;
	int ri_vec_len = Qm*N_l;
	int N_data_bits = N / data_vec_len;
	int N_ri_bits = N_ri / data_vec_len;

	//Interleaver
	// Step 1: Define C_mux
	int C_mux = N_pusch_symbs;

	//Step 2: Define R_mux and R_prime_mux
	int H_prime = N_data_bits;
	int H_vec_len = data_vec_len;
	int H_prime_total = H_prime + N_ri_bits;

	int R_mux = (H_prime_total*Qm*N_l) / C_mux;
	int R_prime_mux = R_mux / (Qm*N_l);

	//Host data allocation
	*output_h = (Byte *)malloc(sizeof(Byte)*(N+N_ri));

	//Device data allocation
	startTimer();
	cudaMalloc((void **)&input_d, sizeof(Byte)*N);
	cudaMalloc((void **)&ri_d, sizeof(Byte)*N_ri);
	cudaMalloc((void **)&y_idx_d, sizeof(Byte)*(C_mux*R_prime_mux));
	cudaMalloc((void **)&y_mat_d, sizeof(Byte)*(C_mux*R_mux));
	cudaMalloc((void **)&output_d, sizeof(Byte)*(C_mux*R_mux));
	stopTimer("cudaMalloc Time= %.6f ms\n", elapsed);

	//Copying data to device
	startTimer();
	cudaMemcpy(input_d, input_h, sizeof(Byte)*N, cudaMemcpyHostToDevice);
	cudaMemcpy(ri_d, ri_h, sizeof(Byte)*N_ri, cudaMemcpyHostToDevice);
	stopTimer("cudaMemcpy Host->Device Time= %.6f ms\n", elapsed);

	//Calc. number of needed threads for calling kernel(s)
	int numThreads = (C_mux*R_mux);
	int blockDim = (numThreads < 1024) ? numThreads : 1024;	//block size in threads (max 1024 thread)
	int gridDim = numThreads / (blockDim)+(numThreads % blockDim == 0 ? 0 : 1); //grid size in bloack (min 1)

	//Calling the kernel(s)
	startTimer();
	initializeMatricies << <gridDim, blockDim >> > (y_idx_d, y_mat_d, (C_mux*R_prime_mux), (C_mux*R_mux));
	stopTimer("Initialize Matricies Time= %.6f ms\n", elapsed);

	// Step 3: Interleave the RI control bits
	if (N_ri != 0)
	{
		//Calc. number of needed threads for calling kernel(s)
		numThreads = N_ri_bits;
		int rows = (numThreads < 1024) ? numThreads : 1024;	//block size in threads (max 1024 thread)

		dim3 blockDim( Qm*N_l,1 );
		dim3 gridDim( 1,rows);
		startTimer();
		interleaveRI << <gridDim, blockDim >> > (y_idx_d, y_mat_d, ri_d, R_prime_mux, numThreads);
		stopTimer("RI Interleaving Time= %.6f ms\n", elapsed);
	}

	// Step 4: Interleave the data bits
	//Calc. number of needed threads for calling kernel(s)
	numThreads = H_prime;		//Actually, it's number of required rows or it's total_threads / (Qm*N_l)
	int rows = (numThreads < (1024/ (Qm*N_l))) ? numThreads : (1024/ (Qm*N_l));
	int gridY = numThreads / (rows)+(numThreads % rows == 0 ? 0 : 1); //grid size in bloack (min 1)

	dim3 blockDim_2(Qm*N_l, rows);
	dim3 gridDim_2(1, gridY);
	startTimer();
	interleaveData << <gridDim_2, blockDim_2 >> >(y_idx_d, y_mat_d, input_d, numThreads, H_prime_total, N_ri_bits, Qm, N_l);
	stopTimer("Data Interleaving Time= %.6f ms\n", elapsed);

	// Step 6: Read out the bits
	//Calc. number of needed threads for calling kernel(s)
	numThreads = C_mux * R_prime_mux * H_vec_len;
	rows = (numThreads < (1024)) ? numThreads : (1024 / (C_mux*H_vec_len));
	gridY = numThreads / (rows*(C_mux*H_vec_len)) + (numThreads % (rows*(C_mux*H_vec_len)) == 0 ? 0 : 1); //grid size in bloack (min 1)

	dim3 blockDim_3(H_vec_len, rows, C_mux);
	dim3 gridDim_3(1,gridY);
	startTimer();
	serialOut << <gridDim_3, blockDim_3 >> >(output_d, y_mat_d, R_prime_mux, Qm, N_l);
	stopTimer("Serial Out Time= %.6f ms\n", elapsed);

	cudaDeviceSynchronize();

	//Retrieve data from device
	startTimer();
	cudaMemcpy(*output_h, output_d, sizeof(Byte)*(C_mux*R_mux), cudaMemcpyDeviceToHost);
	stopTimer("cudaMemcpy Device->Host Time= %.6f ms\n", elapsed);

	// Cleanup
	cudaFree(input_d);
	cudaFree(output_d);
	cudaFree(ri_d);

	//Destroy timers
	destroyTimers();
	
}
