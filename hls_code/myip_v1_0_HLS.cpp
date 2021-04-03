/*
----------------------------------------------------------------------------------
--	(c) Rajesh C Panicker, NUS,
--  Description : AXI Stream Coprocessor (HLS), implementing the sum of 4 numbers
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post a modified version of this on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of any entity.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course EE4218 at the National University of Singapore);
--		(vi) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

//#include "ap_axi_sdata.h" // ap_axis can also be used, but it will include all sideband signals which we don't need
#include "hls_stream.h"
//#include "ap_int.h"

// Creating a custom structure which includes the data word and TLAST signal.
// ACLK, ARESETN, TREADY, TDATA, TVALID are essential signals for AXIS.
// TLAST is a sideband signal which is optional in AXIS.
// However, it is necessary for us since we connecting M_AXIS to AXI Stream FIFO / AXI DMA.
// So, we create a struct with data (TDATA) and last (TLAST). The rest of the essential AXIS signals are automatically dealt with by the HLS tool.

#define NUMBER_OF_INPUT_WORDS 723  // length of an input vector
#define A_SIZE 448 	//size of A
#define B_SIZE 8	//size of B
#define C_SIZE 3	//size of C
#define SIG_SIZE 256 //size of sigmoid
#define RES_SIZE 64
#define NUMBER_OF_OUTPUT_WORDS 64  // length of an output vector

struct AXIS_wLAST{
	int data;
	bool last;
};


void myip_v1_0_HLS(hls::stream<AXIS_wLAST>& S_AXIS, hls::stream<AXIS_wLAST>& M_AXIS){
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE axis port=S_AXIS
#pragma HLS INTERFACE axis port=M_AXIS



	int word_cnt = 0, word_cnt2 = 0, word_cnt3 = 0;
	//ap_uint<8> sum = 0; // using arbitrary precision
	int sum = 0;		 // using 32 bit precision
	int input_memory_A[A_SIZE];
#pragma HLS array_partition variable=input_memory_A cyclic factor=8
	int input_memory_B[B_SIZE];
#pragma HLS array_partition variable=input_memory_B cyclic factor=2
	int input_memory_B_1[B_SIZE];
#pragma HLS array_partition variable=input_memory_B_1 cyclic factor=2
	int input_memory_B_2[B_SIZE];
#pragma HLS array_partition variable=input_memory_B_2 cyclic factor=2
	int input_memory_C[C_SIZE];
	int input_memory_RES1[RES_SIZE];
#pragma HLS array_partition variable=input_memory_RES1 cyclic factor=8
	int input_memory_RES2[RES_SIZE];
#pragma HLS array_partition variable=input_memory_RES2 cyclic factor=8
	int input_memory_N[RES_SIZE*2];
#pragma HLS array_partition variable=input_memory_N cyclic factor=8
	int input_memory_SIG[256];
#pragma HLS array_partition variable=input_memory_SIG cyclic factor=8
	int res_memory[NUMBER_OF_OUTPUT_WORDS];
#pragma HLS array_partition variable=res_memory cyclic factor=8

	AXIS_wLAST read_input, write_output;

		myip_v1_0_HLS_for1:for(word_cnt = 0; word_cnt < A_SIZE; word_cnt++){
//#pragma HLS unroll factor=8
			read_input = S_AXIS.read();
			// read_input is the element (data + other signals) received by our ip through S_AXIS in one clock cycle (which contains one word).
			// read() extracts it from the stream. Overloaded operator >> can also be used.
			input_memory_A[word_cnt] = read_input.data;
			// We are not making using of S_AXIS_TLAST in this example.
			// S_AXIS_TLAST is required only when we are receiving an unknown number of words.
		}

		myip_v1_0_HLS_for2:for(word_cnt = 0; word_cnt < B_SIZE; word_cnt++){
//#pragma HLS unroll factor=2
			read_input = S_AXIS.read();
			// read_input is the element (data + other signals) received by our ip through S_AXIS in one clock cycle (which contains one word).
			// read() extracts it from the stream. Overloaded operator >> can also be used.
			input_memory_B[word_cnt] = read_input.data;
			// We are not making using of S_AXIS_TLAST in this example.
			// S_AXIS_TLAST is required only when we are receiving an unknown number of words.
		}

		myip_v1_0_HLS_for3:for(word_cnt = 0; word_cnt < C_SIZE; word_cnt++){
//#pragma HLS unroll factor=1
			read_input = S_AXIS.read();
			// read_input is the element (data + other signals) received by our ip through S_AXIS in one clock cycle (which contains one word).
			// read() extracts it from the stream. Overloaded operator >> can also be used.
			input_memory_C[word_cnt] = read_input.data;
			// We are not making using of S_AXIS_TLAST in this example.
			// S_AXIS_TLAST is required only when we are receiving an unknown number of words.
		}

		myip_v1_0_HLS_for4:for(word_cnt = 0; word_cnt < SIG_SIZE; word_cnt++){
//#pragma HLS unroll factor=8
			read_input = S_AXIS.read();
			// read_input is the element (data + other signals) received by our ip through S_AXIS in one clock cycle (which contains one word).
			// read() extracts it from the stream. Overloaded operator >> can also be used.
			input_memory_SIG[word_cnt] = read_input.data;
			// We are not making using of S_AXIS_TLAST in this example.
			// S_AXIS_TLAST is required only when we are receiving an unknown number of words.
		}

		int a=0, b=0;
		myip_v1_0_HLS_for5:for(word_cnt = 0; word_cnt < B_SIZE; word_cnt++){
#pragma HLS pipeline II=1
			if(word_cnt%2==0){
				input_memory_B_1[a] = input_memory_B[word_cnt];
				a++;
			}
			else{
				input_memory_B_2[b] = input_memory_B[word_cnt];
				b++;
			}
		}

		int i=0,j=0,k=0;
		sum=0;
		myip_v1_0_HLS_for6:for(;i<A_SIZE;){
			for(j=0;j<B_SIZE;j++){
				if(j==0){
					sum += 1*input_memory_B_1[j];
				}else{
					sum += input_memory_A[i]*input_memory_B_1[j];
					i++;
				}
			}
			input_memory_RES1[k] = sum/256;
			sum = 0;
			k++;
		}
		i=0,j=0,k=0,sum=0;
		myip_v1_0_HLS_for7:for(;i<A_SIZE;){
			for(j=0;j<B_SIZE;j++){
				if(j==0){
					sum += 1*input_memory_B_1[j];
				}else{
					sum += input_memory_A[i]*input_memory_B_2[j];
					i++;
				}
			}
			input_memory_RES2[k] = sum/256;
			sum = 0;
			k++;
		}
		i=0, j=0;
		myip_v1_0_HLS_for8:for(;i<RES_SIZE;i++){
			j=input_memory_RES1[i];
			if(j>256)
				j=256;
			input_memory_N[i]=input_memory_SIG[j];
		}
		j=0;
		myip_v1_0_HLS_for9:for(;i<RES_SIZE*2;i++){
			j=input_memory_RES2[i];
			if(j>256)
				j=256;
			input_memory_N[i]=input_memory_SIG[j];
		}

		i=0,j=0,k=0,sum=0;
		myip_v1_0_HLS_for10:for(;i<128;){
			for(j=0;j<C_SIZE;j++){
				if(j==0){
					sum += 1*input_memory_C[j];
				}else{
					sum += input_memory_N[i]*input_memory_C[j];
					i++;
				}
			}
			res_memory[k] = sum/256;
			sum = 0;
			k++;
		}

		myip_v1_0_HLS_for11:for(word_cnt = 0; word_cnt < NUMBER_OF_OUTPUT_WORDS; word_cnt++){
//#pragma HLS unroll factor=8
			//write_output.data = sum.to_int();	// using arbitrary precision
			write_output.data = res_memory[word_cnt];			// using 32 bit precision
			// write_output is the element sent by our ip through M_AXIS in one clock cycle.
			write_output.last = 0;
			if(word_cnt==NUMBER_OF_OUTPUT_WORDS-1)
			{
				write_output.last = 1;
				// M_AXIS_TLAST is required to be asserted for the last word.
				// Else, the AXI Stream FIFO / AXI DMA will not know if all the words have been received from the co-processor.
			}
			M_AXIS.write(write_output);
			// write() inserts it into the stream. Overloaded operator << can also be used.
		}
}
