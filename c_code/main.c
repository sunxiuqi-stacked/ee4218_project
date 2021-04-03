/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_types.h"
#include "xplatform_info.h"
#include "xparameters.h"

#include "xil_io.h"
#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"

#include "xuartps.h"
#include "xuartps_hw.h"

#include "xil_printf.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>

#define UART_DEVICE_ID1 0

XUartPs UART_PS;

int input(int size, int out[]);
int Node_Multiply(int arrA[], int arrB[], int arrRES[], int sizeA, int sizeB, int sizeRES);
int sigmoid(int arr1[], int arr2[], int arrsig[], int size1);

int main(void)
{
	int size1_1=64, size1_2=7, size2=8, size2_2=2, size1=size1_1*size1_2, size3=size2*size2_2;
	int sig_size = 	256;
	int sig_array[sig_size];
	int arr1[size1], arr2[size3], arr3[size1_1], arr4[size1_1];
	int size4 = 3;
	int arr5[size4];
	int arrRES[size1_1];

	input(size1,arr1);
	input(size3,arr2);
	input(sig_size,sig_array);
	input(size4,arr5);

	int arr2_1[size2], arr2_2[size2], i, a=0, b=0;
	for(i=0;i<size3;i++){
		if(i%2==0){
			arr2_1[a] = arr2[i];
			a++;
		}
		else{
			arr2_2[b] = arr2[i];
			b++;
		}
	}

	Node_Multiply(arr1, arr2_1, arr3, size1, size2, size1_1);
	Node_Multiply(arr1, arr2_2, arr4, size1, size2, size1_1);

	int n1[size1_1], n2[size1_1];

	sigmoid(arr3, n1,sig_array, size1_1);
	sigmoid(arr4, n2,sig_array, size1_1);

	int* total = malloc(128 * sizeof(int));

	memcpy(total,		n1, 64 * sizeof(float));
	memcpy(total + 64, 	n2, 64 * sizeof(float));

	Node_Multiply(total, arr5, arrRES, 128, size4, size1_1);

	int k;
	for(k=0;k<sizeof(arrRES);k++){
		printf("%d\n",arrRES[k]);
	}

	return 0;
}

int input(int size, int out[]){
	int Count = 0;
	while (Count < size) {
		scanf("%d,",&out[Count]);
		Count++;
	}
	return 0;
}

int sigmoid(int arr1[], int arr2[],int arrsig[], int size1){
	int i = 0, j=0;
	for(;i<size1;i++){
		j=arr1[i];
		if(j>256)
			j=256;
		arr2[i]=arrsig[j];
	}
	return 0;
}

int Node_Multiply(int arrA[], int arrB[], int arrRES[], int sizeA, int sizeB, int sizeRES){
	int i=0,j=0,k=0,sum=0;
	while(i<sizeA){
		for(j=0;j<sizeB;j++){
			if(j==0){
				sum += 1*arrB[j];
			}else{
				sum += arrA[i]*arrB[j];
				i++;
			}
		}
		arrRES[k] = sum/256;
		sum = 0;
		k++;
	}
	return 0;
}
