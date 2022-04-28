
 module ahb_test_bench
 (
   output logic            led,
   input logic             hclk_i,                 // System clock
   input logic             hresetn_i,              // System reset

   // AHB-light Slave side,No prot, burst or resp
   output logic            hsel_o,
   output logic [31:0]     haddr_o,

   output logic            hwrite_o,
   output logic [2:0]      hsize_o,
   output logic [2:0]      hburst_o,
   output logic [3:0]      hprot_o,
   output logic [1:0]      htrans_o,
   output logic            hready_o, // not used
   output logic [31:0]     hwdata_o,

   input  logic            hresp_i,
   input  logic            hreadyout_i,
   input  logic [31:0]     hrdata_i
 );

	//parameter define
	parameter  TEST_LENGTH = 20;
	parameter  L_TIME      = 25'd25_000_000;

	parameter  IDLE             = 3'd0;
	parameter  WRITE_START      = 3'd1;
	parameter  WRITE            = 3'd2;
	parameter  WAIT             = 3'd3;
	parameter  READ_START       = 3'd4;
	parameter  READ             = 3'd5;

    logic     [2 :0]    state;

    logic     [31:0]    write_addr_cnt;
	logic     [31:0]    write_data_cnt;

    logic     [31:0]    read_addr_cnt;
    logic     [31:0]    read_data_cnt;

    logic               error_flag;
	logic               error;

	//logic define
	logic  [24:0]  led_cnt;

	//*****************************************************
	//**                    main code
	//*****************************************************
	assign error = ( hreadyout_i && (read_data_cnt != hrdata_i) );

    //typedef enum logic[1:0] { IDLE=0, BUSY=1, NONSEQ=2, SEQ=3 } htrans_t;
    //typedef enum logic { READ =0, WRITETE =1 } hwr_t;
    //typedef enum logic [2:0] { SINGLE=0, INCR=1, WRAP4=2, INCR4=3, WRAP8=4, INCR8=5, WRAP16=6, INCR16=7 } hburst_t;
    //typedef enum logic [2:0] { BYTE =0, HALFWORD =1 , WORD=2, DWORD =3 } hsize_t;
    //typedef enum logic [1:0] { OKAY = 0, ERROR = 1, RETRY = 2, SPLIT =3 } hresp_t;
    //typedef enum logic { NOT_RDY = 0, RDY =1 } hready_t;

	assign hsel_o = ((state == WRITE_START) ||(state == WRITE) ||(state == READ_START) || (state == READ)) ? 1'b1:1'b0;
	assign haddr_o = ((state == WRITE_START) ||(state == WRITE) ) ? write_addr_cnt : ( ( (state == READ_START) || (state == READ)) ? read_addr_cnt : 0);
	assign hwrite_o = ((state == WRITE_START) ||(state == WRITE) ) ? 1'b1:1'b0;
    assign hsize_o = 2;
    assign hburst_o = 0;
	assign hprot_o = 3;
    assign hready_o = 1'b1;
	assign htrans_o =( (state == WRITE_START) || (state == READ_START) ) ? 2 :   // NONSEQ
	                 ( (state == WRITE) || (state == READ)) ? 3 : 0;   //SEQ
	assign hwdata_o = write_data_cnt;

	//DDR3
	always @(posedge hclk_i or negedge hresetn_i) begin
		if( ~hresetn_i ) begin
			state           <= IDLE;

			write_addr_cnt  <= 32'd0;
			write_data_cnt  <= 32'd0;

			read_addr_cnt   <= 32'd0;
			read_data_cnt   <= 32'd0;
		end else begin
			case(state)
				IDLE:begin
					state <= WRITE_START;
					write_data_cnt <= 32'd0;
					write_addr_cnt <= 32'd0;
				end

                WRITE_START: begin
                   state <= WRITE;
				end

				WRITE:begin
					if(hreadyout_i) begin
					    if(write_data_cnt == TEST_LENGTH - 1) begin
							state <= WAIT;
						end else begin
							write_data_cnt  <= write_data_cnt + 1;
							write_addr_cnt  <= write_addr_cnt + 8;
						end
					end else begin
						write_data_cnt  <= write_data_cnt;
						write_addr_cnt  <= write_addr_cnt;
					end
				end

				WAIT:begin
					state  <= READ_START;
					read_addr_cnt <= 32'd0;
					read_data_cnt <= 32'd0;
				end

                READ_START: begin
                    state  <= READ;
				end

				READ:begin
					if(hreadyout_i) begin
					    if(read_data_cnt == TEST_LENGTH - 1) begin
							state <= IDLE;
							read_addr_cnt <= 32'd0;
						    read_data_cnt <= 32'd0;	
						end else begin
							read_addr_cnt <= read_addr_cnt + 8;
							read_data_cnt <= read_data_cnt + 1;
						end
					end else begin
						read_addr_cnt <= read_addr_cnt;
						read_data_cnt <= read_data_cnt;
					end				
				end

				default:begin
					state    <= IDLE;
					write_data_cnt <= 32'd0;
					write_addr_cnt <= 32'd0;
					read_addr_cnt  <= 32'd0;
					read_data_cnt  <= 0;
				 end
			endcase
		end  // end else if ( init_calib_complete ) begin
	end  // always @(posedge ui_clk or negedge hresetn_i) begin

	// error flag
	always @(posedge hclk_i or negedge hresetn_i) begin
		if(~hresetn_i)
			error_flag <= 0;
		else if(error)
			error_flag <= 1;
	end

	//led
	always @(posedge hclk_i or negedge hresetn_i) begin
		if( ~hresetn_i) begin
			led_cnt <= 25'd0;
			led <= 1'b0;
		end else begin
			if(~error_flag)                        // if all good, keep the led turned on
			    led <= 1'b1;
			else begin                             // if something wrong, flash the led
				led_cnt <= led_cnt + 25'd1;
				if(led_cnt == L_TIME - 1'b1) begin
				    led_cnt <= 25'd0;
				    led <= ~led;
				end
			end
		end
	end

 endmodule
