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
// multiples a 64*7 matrix with a 8*2 matrix, with the first row of the 8*2 matrix as bias values
// takes the multipled values or a column, adds the bias, and applies sigmoid function to it through LUT
// writes the output of the sigmoid function into hRES, which is a 64*2 matrix used by the predictor

module hid_layer
	#(	parameter width = 8, 			// width is the number of bits per location
		parameter X_depth_bits = 9, 	// depth is the number of locations (2^number of address bits)
		parameter whid_depth_bits = 4,
		parameter sigm_depth_bits = 8, 
		parameter hRES_depth_bits = 7
	) 
	(
		input clk,										
		input Start,
		output reg Done = 0,
		
		output reg X_read_en = 0,
		output reg [X_depth_bits-1:0] X_read_address,
		input [width-1:0] X_read_data_out,
		
		output reg whid_read_en = 0,
		output reg [whid_depth_bits-1:0] whid_read_address,
		input [width-1:0] whid_read_data_out,
		
		output reg sigm_read_en = 1,
		output reg [sigm_depth_bits-1:0] sigm_read_address,
		input [width-1:0] sigm_read_data_out,
			
		output reg hRES_write_en = 0, 							
		output reg [hRES_depth_bits-1:0] hRES_write_address, 	
		output reg [width-1:0] hRES_write_data_in 
	);
	
// implement the logic to read X_RAM, whid_RAM, wout_RAM, and sigm_RAM
// do the multiplication of weights and addition of bias
// apply sigmoid function by looking up sigm_RAM, write the results to RES_RAM

//main states
localparam RESET 		= 3'b100;
localparam IDLE 		= 3'b010;
localparam COMPUTE		= 3'b001; // multiply values from X_RAM (64x7) and whid_RAM (7x2 after skipping bias), store in RES_RAM (64x2)

//substates
localparam READ_A		= 4'b0001;	// read from X and whid (skip bias)
localparam READ_B		= 4'b0010;	// read from whid, incl bias and storage of two column elements simultaneously
localparam MULTIPLY  	= 4'b0100;	// multiply A and B1, A and B2
localparam WRITE_hRES 	= 4'b1000; 	// write final result to hRES_RAM (64x2)

reg [15:0] total_1 = 0, total_2 = 0;
reg [7:0]  state = RESET, substate = READ_A;
reg [7:0]  A = 0, B1 = 0, B2 = 0; //multiplication placeholder registers
reg [7:0]  bias1 = 0, bias2 = 0; //bias registers
reg [1:0]  neuron_cnt = 0, sigm_wr = 0;

always@(negedge clk)
begin
	case (state)
		
		RESET:
			begin
			X_read_address <= 0;
			whid_read_address <= 0;
			sigm_read_address <= 0;
			hRES_write_en <= 0;
			hRES_write_address <= 0;
			hRES_write_data_in <= 0;
			neuron_cnt <= 0;
			state <= IDLE;
			end
		IDLE:
		begin
			if(Start)
			begin
				X_read_en <= 1;
				state <= COMPUTE;
				substate <= READ_A;
			end
		end
		COMPUTE:
		begin
			case (substate)
			
				READ_A:
				begin
					A = X_read_data_out;
					X_read_address <= X_read_address + 1;
					X_read_en <= 0;
					whid_read_en <= 1;
					substate <= READ_B;
				end
				
				READ_B:
				begin
					if(whid_read_address == 0)
					begin
						bias1 = whid_read_data_out;
						whid_read_address <= whid_read_address + 1;
					end
					else if(whid_read_address == 1)
					begin
						bias2 = whid_read_data_out;
						whid_read_address <= whid_read_address + 1;
					end
					else
					begin
						if(neuron_cnt == 0)
						begin
							B1 = whid_read_data_out;
							whid_read_address <= whid_read_address + 1;
							neuron_cnt = 1;
						end
						else
						begin
							B2 = whid_read_data_out;
							whid_read_address <= whid_read_address + 1;
							neuron_cnt = 0;
							substate <= MULTIPLY;
							whid_read_en <= 0;
						end					
					end
				end
				
				MULTIPLY:
				begin
					total_1 = total_1 + (A*B1);
					total_2 = total_2 + (A*B2);
					if(whid_read_address == 0)
					begin
						substate <= WRITE_hRES;
					end
					else
					begin
						X_read_en <= 1;
						substate <= READ_A;
					end
				end
				
				WRITE_hRES:
				begin
					if(neuron_cnt == 0)
					begin
						if(sigm_wr == 0)
						begin
							hRES_write_en <= 0;
							total_1 = (total_1>>8) + bias1;
							sigm_read_address <= total_1;
							sigm_wr <= 1;
							if(hRES_write_address != 0)
								hRES_write_address <= hRES_write_address + 1;
						end
						else
						begin
							hRES_write_en <= 1;
							hRES_write_data_in <= sigm_read_data_out;
							sigm_wr = 0;
							neuron_cnt = 1;
						end
					end
					else
					begin
						if(sigm_wr == 0)
						begin
							hRES_write_en <= 0;
							total_2 = (total_2>>8) + bias2;
							sigm_read_address = total_2;
							sigm_wr = 1;
							hRES_write_address <= hRES_write_address + 1;
						end
						else
						begin
							hRES_write_en <= 1;
							hRES_write_data_in <= sigm_read_data_out;
							sigm_wr = 0;
							neuron_cnt = 0;
							total_1 <= 0;
							total_2 <= 0;
							if(X_read_address == 448)
							begin
								Done = 1;
								state <= RESET;
								substate <= READ_A;
							end
							else
							begin
								X_read_en <= 1;
								substate <= READ_A;
							end
						end
					end
				end
			endcase
		end
	endcase
end
endmodule