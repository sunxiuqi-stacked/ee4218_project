/* 
----------------------------------------------------------------------------------
--	(c) Rajesh C Panicker, NUS
--  Description : Matrix Multiplication AXI Stream Coprocessor. Based on the orginal AXIS Coprocessor template (c) Xilinx Inc
-- 	Based on the orginal AXIS coprocessor template (c) Xilinx Inc
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
/*
-------------------------------------------------------------------------------
--
-- Definition of Ports
-- ACLK              : Synchronous clock
-- ARESETN           : System reset, active low
-- S_AXIS_TREADY  : Ready to accept data in
-- S_AXIS_TDATA   :  Data in 
-- S_AXIS_TLAST   : Optional data in qualifier
-- S_AXIS_TVALID  : Data in is valid
-- M_AXIS_TVALID  :  Data out is valid
-- M_AXIS_TDATA   : Data Out
-- M_AXIS_TLAST   : Optional data out qualifier
-- M_AXIS_TREADY  : Connected slave device is ready to accept data out
--
-------------------------------------------------------------------------------
*/

module simple_ML_IP_v1_0 
	(
		// DO NOT EDIT BELOW THIS LINE ////////////////////
		ACLK,
		ARESETN,
		S_AXIS_TREADY,
		S_AXIS_TDATA,
		S_AXIS_TLAST,
		S_AXIS_TVALID,
		M_AXIS_TVALID,
		M_AXIS_TDATA,
		M_AXIS_TLAST,
		M_AXIS_TREADY
		// DO NOT EDIT ABOVE THIS LINE ////////////////////
	);

input                          ACLK;    // Synchronous clock
input                          ARESETN; // System reset, active low
// slave in interface
output                         S_AXIS_TREADY;  // Ready to accept data in
input      [31 : 0]            S_AXIS_TDATA;   // Data in
input                          S_AXIS_TLAST;   // Optional data in qualifier
input                          S_AXIS_TVALID;  // Data in is valid
// master out interface
output                         M_AXIS_TVALID;  // Data out is valid
output     [31 : 0]            M_AXIS_TDATA;   // Data Out
output                         M_AXIS_TLAST;   // Optional data out qualifier
input                          M_AXIS_TREADY;  // Connected slave device is ready to accept data out

//----------------------------------------
// Implementation Section
//----------------------------------------
// This implements a hardware accelerator that does the following:
// 1. Read all inputs, which are the pre-trained weights and bias
// 2. Add each input to the corresponding RAM (X_RAM, whid_RAM, wout_RAM)
// 3. Compute the prediction and return the predicted labels, 
//    which should be stored in RES_RAM
//

// RAM parameters
localparam X_depth_bits = 9;  		// 2^9 = 512 elements (X is a 64x7 matrix)
localparam whid_depth_bits = 4; 	// 2^4 =  16 elements (whid is a 8x2 matrix)
localparam wout_depth_bits = 2; 	// 2^2 =   4 elements (wout is a 3x1 matrix)
localparam sigm_depth_bits = 8;		// 2^8 = 256 elements (sigm is a 1x256 matrix)
localparam hRES_depth_bits = 7; 	// 2^7 = 128 elements (hRES is a 64x2 matrix)
localparam RES_depth_bits = 6;		// 2^6 =  64 elements (RES is a 64x1 matrix)
localparam width = 8;				// all 8-bit data
	
// wires (or regs) to connect to RAMs and matrix_multiply_0 for assignment 1
// those which are assigned in an always block of myip_v1_0 shoud be changes to reg.
reg		X_write_en;									// -> X_RAM. Possibly reg.
reg		[X_depth_bits-1:0] X_write_address;			// -> X_RAM. Possibly reg. 
reg		[width-1:0] X_write_data_in;				// -> X_RAM. Possibly reg.
wire	X_read_en;									// X_RAM ->
wire	[X_depth_bits-1:0] X_read_address;			// X_RAM ->
wire	[width-1:0] X_read_data_out;				// X_RAM ->
reg		whid_write_en;								// -> whid_RAM. Possibly reg.
reg		[whid_depth_bits-1:0] whid_write_address;	// -> whid_RAM. Possibly reg.
reg		[width-1:0] whid_write_data_in;				// -> whid_RAM. Possibly reg.
wire	whid_read_en;								// whid_RAM ->
wire	[whid_depth_bits-1:0] whid_read_address;	// whid_RAM ->
wire	[width-1:0] whid_read_data_out;				// whid_RAM ->
reg		wout_write_en;								// -> wout_RAM. Possibly reg.
reg		[wout_depth_bits-1:0] wout_write_address;	// -> wout_RAM. Possibly reg.
reg		[width-1:0] wout_write_data_in;				// -> wout_RAM. Possibly reg.
wire	wout_read_en;								// wout_RAM ->
wire	[wout_depth_bits-1:0] wout_read_address;	// wout_RAM ->
wire	[width-1:0] wout_read_data_out;				// wout_RAM ->
reg		sigm_write_en;								// -> sigm_RAM. Possibly reg.
reg		[sigm_depth_bits-1:0] sigm_write_address;	// -> sigm_RAM. Possibly reg.
reg		[width-1:0] sigm_write_data_in;				// -> sigm_RAM. Possibly reg.
wire	sigm_read_en;								// wout_RAM ->
wire	[sigm_depth_bits-1:0] sigm_read_address;	// wout_RAM ->
wire	[width-1:0] sigm_read_data_out;				// wout_RAM ->
wire	hRES_write_en;								// -> hRES_RAM.
wire	[hRES_depth_bits-1:0] hRES_write_address;	// -> hRES_RAM.
wire	[width-1:0] hRES_write_data_in;				// -> hRES_RAM.
wire 	hRES_read_en;  								// hRES_RAM -> Possibly reg.
wire	[hRES_depth_bits-1:0] hRES_read_address;	// hRES_RAM -> Possibly reg.
wire	[width-1:0] hRES_read_data_out;				// hRES_RAM ->
wire	RES_write_en;								// -> RES_RAM.
wire	[RES_depth_bits-1:0] RES_write_address;		// -> RES_RAM.
wire	[width-1:0] RES_write_data_in;				// -> RES_RAM.
reg		RES_read_en;  								// RES_RAM -> Possibly reg.
reg		[RES_depth_bits-1:0] RES_read_address;		// RES_RAM -> Possibly reg.
wire	[width-1:0] RES_read_data_out;				// RES_RAM -> 

// wires to connect to predictor
reg	    Start_whid = 0; 							// Start the hidden layer computation in coprocessor
reg	    Start_wout = 0; 							// Start the predictor computation in coprocessor
wire	Done_whid;									// Signal from hidden layer that computation is done 
wire	Done_wout;									// Signal from predictro that computation is done
			
				
// Total number of input data.
localparam NUMBER_OF_INPUT_VALUES  = 723; // 2^X_depth_bits + 2^whid_depth_bits + 2^wout_depth_bits + 2^sigm_depth_bits = 788
localparam NUMBER_OF_X = 448;
localparam NUMBER_OF_whid = 16;
localparam NUMBER_OF_wout = 3;
localparam NUMBER_OF_sigm = 256;
// Total number of output data
localparam NUMBER_OF_OUTPUT_VALUES = 64; // 2**RES_depth_bits = 64

// Define the states of state machine (one hot encoding)
localparam Idle  		= 4'b1000;
localparam Read_Inputs 	= 4'b0100;
localparam Compute 		= 4'b0010;
localparam Write_Outputs= 4'b0001;

localparam Read_output = 3'b100;
localparam Write_output = 3'b010;
localparam Idle_output = 3'b001;
    
reg [3:0] state;
reg [2:0] output_state;
reg write_done  = 0;
reg [8:0] RES_size;
reg [31:0] sum;

// Counters to store the number inputs read & outputs written
reg [15:0] nr_of_reads;
reg [15:0] X_of_reads;
reg [15:0] whid_of_reads;
reg [15:0] wout_of_reads;
reg [15:0] sigm_of_reads;
reg [15:0] hRES_of_reads;
reg [15:0] RES_of_reads;
reg [15:0] nr_of_writes;

assign S_AXIS_TREADY = (state == Read_Inputs);
assign M_AXIS_TVALID = (output_state == Write_output);
assign M_AXIS_TLAST = write_done;

assign M_AXIS_TDATA = sum;

always @(posedge ACLK) 
begin
    /****** Synchronous reset (active low) ******/
	if (!ARESETN)
   	begin
    	RES_size     = NUMBER_OF_OUTPUT_VALUES;
        state       <= Idle;
        nr_of_reads <= NUMBER_OF_INPUT_VALUES;
        //reset the write addresses
        X_write_address    <= 0;
        whid_write_address <= 0;
        wout_write_address <= 0;
        sigm_write_address <= 0;
        RES_read_address   <= 0;
        //Reset the number of reads
        X_of_reads 	  <= NUMBER_OF_X;
        whid_of_reads <= NUMBER_OF_whid;
        wout_of_reads <= NUMBER_OF_wout;
        sigm_of_reads <= NUMBER_OF_sigm;
        sum           <= 0;
        //set enable bits for read and write
        X_write_en    <= 0;
        whid_write_en <= 0;
        wout_write_en <= 0;
        sigm_write_en <= 0;
        RES_read_en   <= 0;
        Start_whid    <= 0;
        Start_wout	  <= 0;
     end
      /************** state machine **************/
     else
     	case (state)

        Idle:
        	if (S_AXIS_TVALID == 1)
            begin
                nr_of_reads <= NUMBER_OF_INPUT_VALUES;
            	RES_size 	 = NUMBER_OF_OUTPUT_VALUES;
            	//reset the write addresses
            	X_write_address    <= 0;
            	whid_write_address <= 0;
            	wout_write_address <= 0;
            	sigm_write_address <= 0;
            	RES_read_address   <= 0;
            	//Reset the number of reads
        		X_of_reads 	  <= NUMBER_OF_X;
        		whid_of_reads <= NUMBER_OF_whid;
        		wout_of_reads <= NUMBER_OF_wout;
        		sigm_of_reads <= NUMBER_OF_sigm;
            	X_write_en    <= 1;
                whid_write_en <= 1;
                wout_write_en <= 1;
                sigm_write_en <= 1;
                RES_read_en   <= 0;
            	sum           <= 0;
            	state          = Read_Inputs;
				output_state   = Idle_output;
				write_done    <= 0;
            end

      	  Read_Inputs:
          if (nr_of_reads == 0)
          begin
          	state <= Compute;
          	X_write_en <= 0;
			whid_write_en <= 0;
			wout_write_en <= 0;
			sigm_write_en <= 0;
          end
          else if (S_AXIS_TVALID == 1)
          begin
          	if(S_AXIS_TREADY == 1)
            begin
            	if(wout_of_reads == 0)
            	begin
            		wout_write_en <= 0;
                	sigm_write_data_in = S_AXIS_TDATA[width-1:0];
                    sigm_write_address <= sigm_write_address + 1;
                    sigm_of_reads <= sigm_of_reads - 1;
                    if(sigm_of_reads == 1)
                    	sigm_write_en <= 0;
                end
                else if(whid_of_reads == 0)
                begin
                	whid_write_en <= 0;
                    wout_write_data_in = S_AXIS_TDATA[width-1:0];
                    wout_write_address <= wout_write_address + 1;
                    wout_of_reads <= wout_of_reads - 1;
                    if(wout_of_reads == 1)
                    	wout_write_en <= 0;
                end
                else if(X_of_reads == 0)
                begin
                	X_write_en <= 0;
                    whid_write_data_in = S_AXIS_TDATA[width-1:0];
                    whid_write_address <= whid_write_address + 1;
                    whid_of_reads <= whid_of_reads - 1;
                    if(whid_of_reads == 1)
                    	whid_write_en <= 0;
                end
                else
                begin
                    X_write_data_in = S_AXIS_TDATA[width-1:0];
                    if(X_of_reads != 1<<(X_depth_bits))
                       	X_write_address <= X_write_address + 1;
                    X_of_reads <= X_of_reads - 1;
                    if(X_of_reads == 1)
                    	X_write_en <= 0;
                end
                nr_of_reads <= nr_of_reads - 1;
            end
          end
            
          Compute:
				// If multiplication is done, write to outputs, else begin multiplication by bring start bit high
				if(~Start_whid && ~Done_whid)
				begin
					X_write_en 	  <= 0;
					whid_write_en <= 0;
					wout_write_en <= 0;
					sigm_write_en <= 0;
					Start_whid <= 1;
				end
				else if(~Start_wout && Done_whid)
				begin
					Start_whid <= 0;
					Start_wout <= 1;
				end
				else if(Done_wout)
				begin
					Start_wout <= 0;
					write_done <= 0;
					RES_read_en <= 1;
				    state <= Write_Outputs;
				end
				
          Write_Outputs:
          	begin
            // If there are writes left, read datat out, else go back to Idle
            if (M_AXIS_TREADY == 1)
                case (output_state)               	
                	Idle_output:
                		begin
                		//m_axis_valid <= 0;
//                		write_done <= 0;
                		RES_read_en <= 1;
                		output_state <= Read_output;
                		end
           
                	Read_output:
                		begin
                		//m_axis_valid <= 0;
                    	sum <= RES_read_data_out;
						if(~write_done)
                    		RES_read_address <= RES_read_address + 1;
                    	output_state <= Write_output;
   						end
   					Write_output:
   						begin
   						//m_axis_valid <= 1;
   						if(RES_read_address == RES_size-1)
   							begin
   							if(write_done)
   								begin
   								write_done <= 0;
   								output_state <= Idle_output;
   								RES_read_address <= 0;
   								end
   							else
   								begin
   								write_done <= 1;
   								output_state <= Read_output;
   								end
   							end
   						else
   							begin
   							output_state <= Read_output;
   							end
   						end
   						
                 endcase
			else
				begin
				write_done <= 0;
				//m_axis_valid <= 0;
				state <= Idle;
				end
			end
        endcase
   end
	   
	// Connection to sub-modules
	
//	memory_RAM 
//	#(
//		.width(width), 
//		.depth_bits(X_depth_bits)
//	) X_RAM 
//	(
//		.clk(ACLK),
//		.write_en(X_write_en),
//		.write_address(X_write_address),
//		.write_data_in(X_write_data_in),
//		.read_en(X_read_en),    
//		.read_address(X_read_address),
//		.read_data_out(X_read_data_out)
//	);
										
										
//	memory_RAM 
//	#(
//		.width(width), 
//		.depth_bits(whid_depth_bits)
//	) whid_RAM 
//	(
//		.clk(ACLK),
//		.write_en(whid_write_en),
//		.write_address(whid_write_address),
//		.write_data_in(whid_write_data_in),
//		.read_en(whid_read_en),    
//		.read_address(whid_read_address),
//		.read_data_out(whid_read_data_out)
//	);

	B_RAM
	#(
		.width(width),
		.depth_bits_a(X_depth_bits),
		.depth_bits_b(whid_depth_bits)
	) X_whid_RAM
	(
		.clk(ACLK),
		.write_ena(X_write_en),
		.write_enb(whid_write_en),
		.write_addra(X_write_address),
		.write_addrb(whid_write_address),
		.write_dia(X_write_data_in),
		.write_dib(whid_write_data_in),
		.read_ena(X_read_en),
		.read_enb(whid_read_en),
		.read_addra(X_read_address),
		.read_addrb(whid_read_address),
		.read_doa(X_read_data_out),
		.read_dob(whid_read_data_out)
	);
	
	memory_RAM 
	#(
		.width(width), 
		.depth_bits(wout_depth_bits)
	) wout_RAM 
	(
		.clk(ACLK),
		.write_en(wout_write_en),
		.write_address(wout_write_address),
		.write_data_in(wout_write_data_in),
		.read_en(wout_read_en),    
		.read_address(wout_read_address),
		.read_data_out(wout_read_data_out)
	);
	
		memory_RAM 
	#(
		.width(width), 
		.depth_bits(sigm_depth_bits)
	) sigm_RAM 
	(
		.clk(ACLK),
		.write_en(sigm_write_en),
		.write_address(sigm_write_address),
		.write_data_in(sigm_write_data_in),
		.read_en(sigm_read_en),    
		.read_address(sigm_read_address),
		.read_data_out(sigm_read_data_out)
	);

	memory_RAM 
	#(
		.width(width), 
		.depth_bits(hRES_depth_bits)
	) hRES_RAM 
	(
		.clk(ACLK),
		.write_en(hRES_write_en),
		.write_address(hRES_write_address),
		.write_data_in(hRES_write_data_in),
		.read_en(hRES_read_en),    
		.read_address(hRES_read_address),
		.read_data_out(hRES_read_data_out)
	);
										
	memory_RAM 
	#(
		.width(width), 
		.depth_bits(RES_depth_bits)
	) RES_RAM 
	(
		.clk(ACLK),
		.write_en(RES_write_en),
		.write_address(RES_write_address),
		.write_data_in(RES_write_data_in),
		.read_en(RES_read_en),    
		.read_address(RES_read_address),
		.read_data_out(RES_read_data_out)
	);
										
	hid_layer 
	#(
		.width(width), 
		.X_depth_bits(X_depth_bits), 
		.whid_depth_bits(whid_depth_bits),
		.sigm_depth_bits(sigm_depth_bits),
		.hRES_depth_bits(hRES_depth_bits) 
	) hid_layer
	(									
		.clk(ACLK),
		.Start(Start_whid),
		.Done(Done_whid),
		
		.X_read_en(X_read_en),
		.X_read_address(X_read_address),
		.X_read_data_out(X_read_data_out),
		
		.whid_read_en(whid_read_en),
		.whid_read_address(whid_read_address),
		.whid_read_data_out(whid_read_data_out),
		
		.sigm_read_en(sigm_read_en),
		.sigm_read_address(sigm_read_address),
		.sigm_read_data_out(sigm_read_data_out),
		
		.hRES_write_en(hRES_write_en),
		.hRES_write_address(hRES_write_address),
		.hRES_write_data_in(hRES_write_data_in)
	);

	predictor
	#(
		.width(width), 
		.wout_depth_bits(wout_depth_bits), 
		.hRES_depth_bits(hRES_depth_bits),
		.RES_depth_bits(RES_depth_bits) 
	) predictor
	(									
		.clk(ACLK),
		.Start(Start_wout),
		.Done(Done_wout),
		
		.wout_read_en(wout_read_en),
		.wout_read_address(wout_read_address),
		.wout_read_data_out(wout_read_data_out),

		.hRES_read_en(hRES_read_en),
		.hRES_read_address(hRES_read_address),
		.hRES_read_data_out(hRES_read_data_out),

		.RES_write_en(RES_write_en),
		.RES_write_address(RES_write_address),
		.RES_write_data_in(RES_write_data_in)
	);

endmodule



/*
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
*/
