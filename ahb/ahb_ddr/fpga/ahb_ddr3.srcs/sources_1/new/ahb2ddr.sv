module ahb2ddr
(
    //ahb interface
    input  logic           hclk_i,
    input  logic           hrstn_i,

    input  logic           hready_i,
    input  logic           hsel_i,
    input  logic           hwrite_i,
    input  logic [2:0]     htrans_i,
    input  logic [2:0]     hsize_i,
    input  logic [2:0]     hburst_i,
    input  logic [3:0]     hprot_i,
    input  logic [31:0]    haddr_i,
    input  logic [31:0]    hwdata_i,

    output logic           hreadyout_o,
    output logic           hresp_o,
    output logic [31:0]    hrdata_o,


    // memory port side
    input  logic           app_rdy,               // MIG is ready to process request
    input  logic           app_wdf_rdy,           // MIG is ready to write data

    input  logic           app_rd_data_valid,     // the data is valid in the mig
    input  logic [255:0]   app_rd_data,           // the data to read, each time 32 bytes

    output logic [2:0]     app_cmd,               // read or write cmd
    output logic           app_en,                // start a cmd on mig
    output logic [27:0]    app_addr,              // the address to access
    output logic           app_wdf_wren,          // start the write on mig
    output logic [255:0]   app_wdf_data,          // the data to write to ddr
    output logic [31:0]    app_wdf_mask,          // the data mask for writing
    output logic           app_wdf_end           // the last data to write
);

    typedef enum logic [4:0]  { IDLE=0, WRITE_ADDR=1, WRITE_DATA=2, WRITE_PEND=3, WRITE_TRY=4, WRITE_DONE=5, READ_ADDR=6, READ_PEND=7, READ_TRY=8, READ_RESP=9}  state_t;
	typedef enum logic [2:0]  { CMD_WRITE = 3'b0, CMD_READ = 3'b001 } mig_cmd_t;

    typedef enum logic        { NOT_RDY = 0, RDY =1} hreaddy_t;
    typedef enum logic        { OKAY = 0, ERROR = 1} hresp_t;
	
    //typedef enum logic [1:0] { IDLE=0, BUSY=1, NONSEQ=2, SEQ=3} htrans_t;
    //typedef enum logic       { READ =0, WRITETE =1} hrw_t;
    //typedef enum logic [2:0] { SINGLE=0, INCR=1, WRAP4=2, INCR4=3, WRAP8=4, INCR8=5, WRAP16=6, INCR16=7} hburst_t;
    //typedef enum logic [2:0] { BYTE =0, HALFWORD =1 , WORD=2, DWORD =3} hsize_t;
 
	
    state_t  cur_st, nxt_st;


    // AHB Interface FSM
    always_comb begin
        nxt_st = cur_st;
        case(cur_st)
            IDLE : begin
                // start a new transaction
                if ((htrans_i == 2'b10 || htrans_i == 2'b11) & hready_i == 1'b1 & hsel_i == 1'b1) begin
                    if (hwrite_i == 1) begin
                        nxt_st = WRITE_ADDR;
                    end else begin
                        nxt_st = READ_ADDR;
                    end
                end  // if ((htrans_i == 2'b10 || htrans_i == 2'b11) & hready_i == 1'b1 & hsel_i == 1'b1) begin
            end

            // save the address, mask, length, etc
            WRITE_ADDR: begin
                nxt_st = WRITE_DATA;
            end

            // save the data 
            WRITE_DATA: begin
				if(app_rdy && app_wdf_rdy) begin     // MIG is ready to process request &&  MIG is ready to write data
                   nxt_st = WRITE_TRY;
				end else begin
				   nxt_st = WRITE_PEND;
				end
            end //if ((htrans_i == 2'b10 || htrans_i == 2'b11) && hready_i == 1'b1 && hsel_i == 1'b1) begin

            // waiting for issue write cmd
			WRITE_PEND: begin
				if(app_rdy && app_wdf_rdy) begin     // MIG is ready to process request &&  MIG is ready to write data
                   nxt_st = WRITE_TRY;
				end else begin
				   nxt_st = WRITE_PEND;
				end			
			end

            // waiting for the end of the write cmd
			WRITE_TRY: begin
				if(app_rdy && app_wdf_rdy) begin     // MIG is ready to process request &&  MIG is ready to write data
                   nxt_st = WRITE_DONE;
                end				   
			end

			WRITE_DONE: begin
                // continuous read or write
				if(hready_i == 1'b1) begin
					if ((htrans_i == 2'b10 || htrans_i == 2'b11) && hsel_i == 1'b1) begin
						if (hwrite_i == 1) begin
							nxt_st = WRITE_DATA;  //continuous writing
						end else begin
							nxt_st = READ_ADDR;
						end
					end else begin 
						nxt_st = IDLE;
					end // else if (hready_i == 1'b1) begin
				end // if(hready_i == 1'b1) begin			
			end
			
            // save the read address
            READ_ADDR: begin
				if(app_rdy) begin
				    nxt_st = READ_TRY;
				end else begin
				    nxt_st = READ_PEND;
				end
            end

            // waiting for issue a read command
            READ_PEND: begin
				if(app_rdy) begin
				    nxt_st = READ_TRY;
				end else begin
				    nxt_st = READ_PEND;
				end
            end

            // waiting for the read response
            READ_TRY: begin
			    if (app_rd_data_valid == 1'b1) begin
                    nxt_st = READ_RESP;
                end else begin
				    nxt_st = READ_TRY; 
				end
			end

            // the reading data is ready
            READ_RESP: begin
                // continuous read or write
				if(hready_i == 1'b1) begin
					if ((htrans_i == 2'b10 || htrans_i == 2'b11) && hsel_i == 1'b1) begin
						if (hwrite_i == 1) begin
							nxt_st = WRITE_DATA;  //continuous writing
						end else begin
							nxt_st = READ_ADDR;
						end
					end else begin 
						nxt_st = IDLE;
					end // else if (hready_i == 1'b1) begin
				end // if(hready_i == 1'b1) begin	
            end
            
            default : nxt_st = IDLE;
        endcase
    end // always_comb begin


    function logic [3:0] wr_mask_f;
        input logic [1:0] addr_s;
        input logic [1:0] byte_size;

        if ( byte_size == 2'b00)   // 1 byte
            case(addr_s)
                0:  wr_mask_f = 1;
                1:  wr_mask_f = 2;
                2:  wr_mask_f = 4;
                3:  wr_mask_f = 8;
                default : wr_mask_f = 4'b1111;
            endcase
        else if (byte_size == 2'b01) begin  // halfword
            if (addr_s[1] == 1'b1)
                wr_mask_f = 4'b1100;
            else
                wr_mask_f = 4'b0011;
            end
        else // word
            wr_mask_f = 4'b1111;
    endfunction

    logic [27:0]    app_addr_prev;             // the address to access 
    logic [31:0]    app_wdf_mask_prev;         // the data mask for writing
		
    always @(posedge hclk_i or negedge hrstn_i) begin
        if (!hrstn_i) begin
            cur_st           <= IDLE;
            //mig reset
            app_cmd           <= 3'b0;          // read or write cmd
            app_en            <= 1'b0;          // start a cmd on mig
			app_addr_prev     <= 28'b0;
            app_addr          <= 28'b0;         // the address to access
            app_wdf_wren      <= 1'b0;          // start the write on mig
            app_wdf_data      <= 256'b0;        // the data to write to ddr, 32 bytes
            app_wdf_mask      <= 32'b0;         // the data mask for writing
			app_wdf_mask_prev <= 32'b0;  
            app_wdf_end       <= 1'b0;          // the last data to write

        end else begin
            cur_st <= nxt_st;
			
			case (nxt_st)
                IDLE : begin
				    hresp_o <= OKAY;
                    hreadyout_o <= RDY;
					hrdata_o <= 32'b0; 
				end
				
                WRITE_ADDR : begin
					// write address
					app_addr_prev     <= haddr_i[27:0];                                         // the address to access
					app_wdf_mask_prev <= { 28'hfffffff, ~wr_mask_f(haddr_i[1:0], hsize_i[1:0]) };     // the data mask for writing
					//
				    hresp_o <= OKAY;
                    hreadyout_o <= NOT_RDY;
					hrdata_o <= 32'b0; 					
				end
				
                WRITE_DATA : begin
					// write data
					app_addr     <= app_addr_prev;               // the address to access
					app_wdf_mask <= app_wdf_mask_prev;           // the data mask for writing
					app_wdf_data <= { 224'b0, hwdata_i };        // the data to write to ddr
					// prepare for the next writing
					app_addr_prev     <= haddr_i[27:0];                                         // the address to access
					app_wdf_mask_prev <= { 28'hfffffff, ~wr_mask_f(haddr_i[1:0], hsize_i[1:0]) };     // the data mask for writing		
					
					//
				    hresp_o <= OKAY;
                    hreadyout_o <= NOT_RDY;
					hrdata_o <= 32'b0;  							
				end

                WRITE_PEND : begin
				    //
				    hresp_o <= OKAY;
                    hreadyout_o <= NOT_RDY;
					hrdata_o <= 32'b0; 					
				end

                WRITE_TRY : begin
					app_cmd      <= CMD_WRITE;               // 3'd0, write cmd
					app_en       <= 1'b1;                    // start a cmd on mig
					app_wdf_wren <= 1'b1;                    // start the write on mig
					app_wdf_end  <= 1'b1;                    // the last data to write		
					//
				    hresp_o <= OKAY;
                    hreadyout_o <= NOT_RDY;
					hrdata_o <= 32'b0; 						
				end

                WRITE_DONE : begin
					app_cmd      <= CMD_WRITE;               // 3'd0, write cmd
					app_en       <= 1'b0;                    // start a cmd on mig
					app_wdf_wren <= 1'b0;                    // start the write on mig
					app_wdf_end  <= 1'b0;                    // the last data to write	
					// write data
					app_addr     <= app_addr_prev;           // the address to access
					app_wdf_mask <= app_wdf_mask_prev;       // the data mask for writing
					app_wdf_data <= { 224'b0, hwdata_i };    // the data to write to ddr
					// prepare for the next writing
					app_addr_prev     <= haddr_i[27:0];                                               // the address to access
					app_wdf_mask_prev <= { 28'hfffffff, ~wr_mask_f(haddr_i[1:0], hsize_i[1:0]) };     // the data mask for writing	
                    //
				    hresp_o <= OKAY;
                    hreadyout_o <= RDY;
					hrdata_o <= 32'b0; 						
				end
				
                READ_ADDR : begin
                    app_cmd <= CMD_READ;           // 3'd1 read cmd
                    app_en  <= 1'b0;               // start a cmd on mig				
                    app_addr <= haddr_i[27:0];     // the address to access
					//
				    hresp_o <= OKAY;
                    hreadyout_o <= NOT_RDY;
					hrdata_o <= 32'b0;  						
                end
				
			    READ_PEND : begin
                    app_cmd <= CMD_READ;           // 3'd1 read cmd
                    app_en  <= 1'b0;               // start a cmd on mig					
					//
				    hresp_o <= OKAY;
                    hreadyout_o <= NOT_RDY;
					hrdata_o <= 32'b0; 						
				end
				
				READ_TRY: begin
                    app_cmd <= CMD_READ;           // 3'd1 read cmd
                    app_en  <= 1'b1;               // start a cmd on mig
					//
				    hresp_o <= OKAY;
                    hreadyout_o <= NOT_RDY;
					hrdata_o <= 32'b0; 						
				end
			
                READ_RESP : begin
                    app_cmd <= CMD_READ;           // 3'd1 read cmd
                    app_en  <= 1'b0;               // start a cmd on mig
					//
				    hresp_o <= OKAY;
                    hreadyout_o <= RDY;
					hrdata_o <= app_rd_data[31:0];							
                end
				
				default : begin
				
				end
			endcase
        end // if (!hrstn_i) begin
    end // always @(posedge gated_clk_s or negedge hrstn_i) begin

endmodule

