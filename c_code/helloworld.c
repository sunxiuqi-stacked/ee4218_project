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

int input(int size1, int size2, int size3, int out1[], int out2[], int out3[]);
int Matrix_Multiply(int arrA[], int arrB[], int arrRES[]);
int sigmoid(int arr1[], int arr2[]);

int main(void)
{
	int i1x = 64, i1y = 7, nodes = 2, i2x = 8, i2y = 2;
	int output = 3;
	int size1 = i1x*i1y;
	int size2 = i2x*i2y;

    int out1[size1], out2[size2], out3[nodes], out_wt[output], out[output];

    int WCount = 0;


    input(size1, size2, nodes, out1, out2, out3);
    while (WCount < output) {
    	scanf("%d,",&out_wt[WCount]);
    	WCount++;
    }
    Matrix_Multiply(out1, out2, out3);
    sigmoid(out1,out2);


    Matrix_Multiply(nodes, out_wt, out);
	return 0;
}

int input(int size1, int size2, int size3, int out1[], int out2[], int out3[])
{
	int ACount = 0, BCount = 0;
	int sizeA = size1;
	int sizeB = size2;
	int sizeRES = size3;

	int arrA[sizeA];
	int arrB[sizeB];
	int arrRES[sizeRES];

	while (ACount < sizeA) {
		scanf("%d,",&out1[ACount]);
		ACount++;
	}

	while (BCount < sizeB){
		scanf("%d,",&out2[BCount]);
		BCount++;
	}

	out1 = arrA;
	out2 = arrB;
	out3 = arrRES;

	return 0;
}

int sigmoid(int arr1[], int arr2[]){
	int i = 0;
	for(;i<sizeof(arr1);i++){
		double a = -(arr1[i]*(6/256)-3), b;
		b = ((a+3)*(a+3)+3)*((a-3)*(a-3)+3);
		arr2[i] = 256/(1+b);
	}
}

int Matrix_Multiply(int arrA[], int arrB[], int arrRES[])
{
	int i=0,j=0,k=0,sum=0;
	for(i=0;i<sizeof(arrA);i++){
		sum += arrA[i]*arrB[j];
		if((i+1)%sizeof(arrB)==0){
			arrRES[k] = sum/256;
			k++;
			sum = 0;
			j = 0;
		}else{
			j++;
		}
	}

	for(k=0;k<sizeof(arrRES);k++){
		printf("%d\n",arrRES[k]);
	}


	return 0;
}
