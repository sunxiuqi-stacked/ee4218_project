// Modified Dual-Port Block RAM with Two Write Ports
// Original File: rams_tdp_rf_rf.v
// Modified by: Justin Chong

module B_RAM 
	#(
		parameter width = 8, 					// width is the number of bits per location
		parameter depth_bits_a = 2,				// depth is the number of locations (2^number of address bits)
		parameter depth_bits_b = 2
	) 
	(
		input clk,
		input write_ena,
		input write_enb,
		input [depth_bits_a-1:0] write_addra,
		input [depth_bits_b-1:0] write_addrb,
		input [width-1:0] write_dia,
		input [width-1:0] write_dib,
		input read_ena, 
		input read_enb,
		input [depth_bits_a-1:0] read_addra,
		input [depth_bits_b-1:0] read_addrb,
		output reg [width-1:0] read_doa,
		output reg [width-1:0] read_dob);

reg [width-1:0] ram_a [0:2**depth_bits_a-1];
reg [width-1:0] ram_b [0:2**depth_bits_b-1];
wire [depth_bits_a-1:0] address_a;
wire [depth_bits_b-1:0] address_b;
wire ena;
wire enb;

assign ena = read_ena | write_ena;
assign enb = read_enb | write_enb;
assign address_a = write_ena? write_addra:read_addra;
assign address_b = write_enb? write_addrb:read_addrb;

always @(posedge clk)
begin 
  if (ena)
    begin
      if (write_ena)
        ram_a[address_a] <= write_dia;
      else
      	read_doa <= ram_a[address_a];
    end
  if (enb)
  	begin
  	  if (write_enb)
  	  	ram_b[address_b] <= write_dib;
  	  else
  	  	read_dob <= ram_b[address_b];
  	end
end

endmodule
