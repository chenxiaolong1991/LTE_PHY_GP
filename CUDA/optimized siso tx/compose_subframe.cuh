#pragma once

extern cudaStream_t stream_default;

#include <cufft.h>
#include <cuda_runtime.h>
#include <helper_math.h>
#include <stdio.h>
#include <stdlib.h>
#include "device_launch_parameters.h"
#include <math.h>
#include <cuda.h>
#include <device_functions.h>
#include <cuda_runtime_api.h>


typedef unsigned char Byte;
typedef signed char signedByte;

#define N_sc_rb  12
#define FFT_size 2048
#define N_cp_L_0 160
#define N_cp_L_else 144
#define N_symbs_per_slot 7
#define N_symbs_per_subframe 14					//2*N_symbs_per_slot
#define modulated_subframe_length 30720			//2*N_cp_L_0 + 12*N_cp_L_else + 14*FFT_size
//#define timerInit(); float elapsed = 0; cudaEvent_t start, stop;
//#define startTimer(); cudaEventCreate(&start); cudaEventCreate(&stop); cudaEventRecord(start, 0);
//#define stopTimer(msg, var); cudaEventRecord(stop, 0); cudaEventSynchronize(stop); cudaEventElapsedTime(&elapsed, start, stop); printf(msg,var);
//#define destroyTimers(); 	cudaEventDestroy(start); cudaEventDestroy(stop);

//Example for timer macros usage:
//	timerInit();
//	startTimer();
//  ...do_something();
//  stopTimer("Time= %.10f ms\n", elapsed);
//  ...at the very end
//  destroyTimers();

//__global__ void compose_subframe(cufftComplex* complex_data_d, cufftComplex* dmrs_1_d, cufftComplex* dmrs_2_d, int M_pusch_sc, cufftComplex* subframe_d);
void compose_subframe(cufftComplex* complex_data_h, cufftComplex* dmrs_1_h, cufftComplex* dmrs_2_h, const int M_pusch_rb, cufftComplex** subframe_h);