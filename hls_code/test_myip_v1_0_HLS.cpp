/*
----------------------------------------------------------------------------------
--	(c) Rajesh C Panicker, NUS,
--  Description : Self-checking testbench for AXI Stream Coprocessor (HLS) implementing the sum of 4 numbers
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
/*NOTE: This simulation testbench will not work due to the sum being divided by 256!*/

#include <stdio.h>
#include "hls_stream.h"

/***************** AXIS with TLAST structure declaration *********************/

struct AXIS_wLAST{
	int data;
	bool last;
};

/***************** Coprocessor function declaration *********************/

void myip_v1_0_HLS(hls::stream<AXIS_wLAST>& S_AXIS, hls::stream<AXIS_wLAST>& M_AXIS);


/***************** Macros *********************/
#define NUMBER_OF_INPUT_WORDS 723  // length of an input vector
#define A_SIZE 448
#define B_SIZE 8
#define NUMBER_OF_OUTPUT_WORDS 64  // length of an input vector
#define NUMBER_OF_TEST_VECTORS 1  // number of such test vectors (cases)


/************************** Variable Definitions *****************************/


/*****************************************************************************
* Main function
******************************************************************************/
int main()
{
	int test_input_memory[NUMBER_OF_TEST_VECTORS*NUMBER_OF_INPUT_WORDS];
	int test_result_expected_memory[NUMBER_OF_TEST_VECTORS*NUMBER_OF_OUTPUT_WORDS];// 4 outputs *2
	int result_memory[NUMBER_OF_TEST_VECTORS*NUMBER_OF_OUTPUT_WORDS]; // same size as test_result_expected_memory
	int word_cnt, word_cnt2 = 512, test_case_cnt = 0, K = 0;
	int success;
	AXIS_wLAST read_output, write_input;
	hls::stream<AXIS_wLAST> S_AXIS;
	hls::stream<AXIS_wLAST> M_AXIS;

	/************** Run a software version of the hardware function to validate results ************/
	// instead of hard-coding the results in test_result_expected_memory
	/*
	int sum = 0;
	for(word_cnt = 0; word_cnt < A_SIZE; word_cnt++){
		sum += test_input_memory[word_cnt]*test_input_memory[word_cnt2];
		if((word_cnt+1)%B_SIZE==0){
			test_result_expected_memory[K] = sum;
			K++;
			sum = 0;
			word_cnt2 = 512;
		}else{
			word_cnt2++;
		}
	}
	*/

	FILE *in_file = fopen("C:\\Users\\thebo\\Downloads\\STUDYMATERIALS\\AY2021_SEM2\\EE4218\\project\\X.csv","r");
	int i = 0;
	for(i=0;i<NUMBER_OF_INPUT_WORDS;i++){
		fscanf(in_file,"%d,",test_input_memory[i]);
	}

	for (test_case_cnt=0 ; test_case_cnt < NUMBER_OF_TEST_VECTORS ; test_case_cnt++){


		/******************** Input to Coprocessor : Transmit the Data Stream ***********************/

		printf(" Transmitting Data for test case %d ... \r\n", test_case_cnt);

		for (word_cnt=0 ; word_cnt < NUMBER_OF_INPUT_WORDS ; word_cnt++){

			write_input.data = test_input_memory[word_cnt+test_case_cnt*NUMBER_OF_INPUT_WORDS];
			write_input.last = 0;
			if(word_cnt==NUMBER_OF_INPUT_WORDS-1)
			{
				write_input.last = 1;
				// S_AXIS_TLAST is asserted for the last word.
				// Actually, doesn't matter since we are not making using of S_AXIS_TLAST.
			}
			S_AXIS.write(write_input); // insert one word into the stream
		}

		/* Transmission Complete */

		/********************* Call the hardware function (invoke the co-processor / ip) ***************/

		myip_v1_0_HLS(S_AXIS, M_AXIS);


		/******************** Output from Coprocessor : Receive the Data Stream ***********************/

		printf(" Receiving data for test case %d ... \r\n", test_case_cnt);

		for (word_cnt=0 ; word_cnt < NUMBER_OF_OUTPUT_WORDS ; word_cnt++){

			read_output = M_AXIS.read(); // extract one word from the stream
			result_memory[word_cnt+test_case_cnt*NUMBER_OF_OUTPUT_WORDS] = read_output.data;
		}

		/* Reception Complete */
	}

	/************************** Checking correctness of results *****************************/
	printf("%d,",test_result_expected_memory[0]);
	printf("%d,",test_result_expected_memory[1]);
	printf("%d,",test_result_expected_memory[2]);

	success = 1;

	/* Compare the data send with the data received */
	printf(" Comparing data ...\r\n");
	for(word_cnt=0; word_cnt < NUMBER_OF_TEST_VECTORS*NUMBER_OF_OUTPUT_WORDS; word_cnt++){
		success = success & (result_memory[word_cnt] == test_result_expected_memory[word_cnt]);
		printf("%d,",result_memory[word_cnt]);
		//printf("\n");
		printf("%d,",test_result_expected_memory[word_cnt]);
	}

	if (success != 1){
		printf("Test Failed\r\n");
		return 1;
	}

	printf("Test Success\r\n");

	return 0;
}
