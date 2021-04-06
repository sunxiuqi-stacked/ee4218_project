`timescale 0.001ns / 1ps

/* 
----------------------------------------------------------------------------------
--	(c) Rajesh C Panicker, NUS
--  Description : Template for the Matrix Multiply unit for the AXI Stream Coprocessor
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

// those outputs which are assigned in an always block of matrix_multiply shoud be changes to reg (such as output reg Done).
// reads the 64*2 matrix from hRES, and the 3*1 matrix from wout_RAM
// multiplies them, taking the first row of wout_RAM as bias
// adds the bias to the multiplied values of each column

module predictor
	#(	parameter width = 8, 			// width is the number of bits per location
		parameter wout_depth_bits = 2,	// depth is the number of locations (2^number of address bits)
		parameter hRES_depth_bits = 7,
		parameter RES_depth_bits = 6
	) 
	(
		input clk,										
		input Start,
		output reg Done = 0,

		output reg wout_read_en = 0,
		output reg [wout_depth_bits-1:0] wout_read_address,
		input [width-1:0] wout_read_data_out,
		
		output reg hRES_read_en = 0,
		output reg [hRES_depth_bits-1:0] hRES_read_address,
		input [width-1:0] hRES_read_data_out,
			
		output reg RES_write_en, 							
		output reg [RES_depth_bits-1:0] RES_write_address, 	
		output reg [width-1:0] RES_write_data_in 
	);
	
// implement the logic to read X_RAM, whid_RAM, wout_RAM, and sigm_RAM
// do the multiplication of weights and addition of bias
// apply sigmoid function by looking up sigm_RAM, write the results to RES_RAM

//main states
localparam RESET 		= 3'b100;
localparam IDLE 		= 3'b010;
localparam COMPUTE		= 3'b001; // multiply values stored in hRES_RAM (64x2) and values from wout_RAM (2x1 after skipping bias)

//substates
localparam READ_hRES	= 4'b0001;	// read from hRES
localparam READ_wout	= 4'b0010;	// read from wout, including bias (first element)
localparam MULTIPLY  	= 4'b0100;	// multiply A and B
localparam WRITE_RES 	= 4'b1000; 	// write final result to RES_RAM (64x2, 64x1)

reg [15:0] total = 0;
reg [7:0]  state = RESET, substate = READ_wout;
reg [7:0]  A1 = 0, A2 = 0, B1 = 0, B2 = 0;	//multiplication placeholder registers
reg [7:0]  bias1 = 0;	//bias registers
reg [1:0]  neuron_cnt = 0; //flags

always@(negedge clk)
begin
	case (state)
		
		RESET:
			begin
			hRES_read_address <= 0;
			wout_read_address <= 0;
			RES_write_en <= 0;
			RES_write_address <= 0;
			RES_write_data_in <= 0;
			Done <= 0;
			state <= IDLE;
			end
		IDLE:
		begin
			if(Start)
			begin
				wout_read_en <= 1;
				state <= COMPUTE;
				substate <= READ_wout;
			end
		end
		COMPUTE:
		begin
			case (substate)
			
				READ_wout:
				begin
					wout_read_address <= wout_read_address + 1;
					if(wout_read_address == 0)
						bias1 = wout_read_data_out;
					else if(wout_read_address == 1)
						B1 = wout_read_data_out;
					else if(wout_read_address == 2)
					begin
						B2 = wout_read_data_out;
						substate <= READ_hRES;
						hRES_read_en <= 1;
						wout_read_en <= 0;
					end

				end
				
				READ_hRES:
				begin
					hRES_read_address <= hRES_read_address + 1;
					if(neuron_cnt == 0)
					begin
						A1 = hRES_read_data_out;
						neuron_cnt = 1;
					end
					else
					begin
						A2 = hRES_read_data_out;
						neuron_cnt = 0;
						hRES_read_en <= 0;
						substate <= MULTIPLY;
					end
				end
				
				MULTIPLY:
				begin
					total = (A1*B1) + (A2*B2);
					substate <= WRITE_RES;
				end
				
				WRITE_RES:
				begin
					RES_write_en <= 1;
					if(RES_write_en != 0)
						RES_write_address <= RES_write_address + 1;
					RES_write_data_in = (total + bias1)>>8;
					if(hRES_read_address == 0)
					begin
						Done <= 1;
						state <= RESET;
						substate <= READ_wout;
					end
					else
					begin
						hRES_read_en <= 1;
						substate <= READ_hRES;
					end
				end
			endcase
		end
	endcase
end
endmodule