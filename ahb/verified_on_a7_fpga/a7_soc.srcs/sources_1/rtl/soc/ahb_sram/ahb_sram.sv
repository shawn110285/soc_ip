/*-------------------------------------------------------------------------
// Module:  ahb2sram
// File:    ahb2sram.v
// Author:  shawn Liu
// E-mail:  shawn110285@gmail.com
// Description: Synchronous memory interface for 32-bit wide AHB bus
--------------------------------------------------------------------------*/
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------


module ahb2sram
(
    output logic [1:0]     leds_o,      //indicates read or write to the memory

    // AHB-light Slave side,No prot, burst or resp
    input logic            hclk_i,      // System clock
    input logic            hresetn_i,   // System reset
    input logic            hsel_i,
    input logic [31:0]     haddr_i,
    input logic            hwrite_i,
    input logic [2:0]      hsize_i,
    input logic [2:0]      hburst_i,
    input logic [3:0]      hprot_i,
    input logic [1:0]      htrans_i,
    input logic            hready_i,
    input logic [31:0]     hwdata_i,
    output logic           hresp_o,
    output logic           hreadyout_o,
    output logic [31:0]    hrdata_o
);

    // Constants
    localparam       HTRANS_SIZE   = 2;
    localparam       HSIZE_SIZE    = 3;
    localparam       HBURST_SIZE   = 3;
    localparam       HPROT_SIZE    = 4;

    //htrans_i
    localparam [1:0] HTRANS_IDLE   = 2'b00,
                     HTRANS_BUSY   = 2'b01,
                     HTRANS_NONSEQ = 2'b10,
                     HTRANS_SEQ    = 2'b11;

    //hsize_i
    localparam [2:0] HSIZE_B8    = 3'b000,
                     HSIZE_B16   = 3'b001,
                     HSIZE_B32   = 3'b010,
                     HSIZE_B64   = 3'b011,
                     HSIZE_B128  = 3'b100, //4-word line
                     HSIZE_B256  = 3'b101, //8-word line
                     HSIZE_B512  = 3'b110,
                     HSIZE_B1024 = 3'b111;

    //hburst_i
    localparam [2:0] HBURST_SINGLE = 3'b000,
                     HBURST_INCR   = 3'b001,
                     HBURST_WRAP4  = 3'b010,
                     HBURST_INCR4  = 3'b011,
                     HBURST_WRAP8  = 3'b100,
                     HBURST_INCR8  = 3'b101,
                     HBURST_WRAP16 = 3'b110,
                     HBURST_INCR16 = 3'b111;

    //hprot_i
    localparam [3:0] HPROT_OPCODE         = 4'b0000,
                     HPROT_DATA           = 4'b0001,
                     HPROT_USER           = 4'b0000,
                     HPROT_PRIVILEGED     = 4'b0010,
                     HPROT_NON_BUFFERABLE = 4'b0000,
                     HPROT_BUFFERABLE     = 4'b0100,
                     HPROT_NON_CACHEABLE  = 4'b0000,
                     HPROT_CACHEABLE      = 4'b1000;

    //hresp_o
    localparam       HRESP_OKAY  = 1'b0,
                     HRESP_ERROR = 1'b1;

    //connect to sram
    logic [31:0]     m_address;
    logic            m_write;
    logic [31:0]     m_wdata;
    logic [ 3:0]     m_wstrobe;
    logic            m_read;
    logic [31:0]     m_rdata;

    // htrans_i[0] is never used as this module does not care if accesses are sequential or not
    logic             read_memory_req;            // ahb read request
    logic             read_memory_req_phase1;

    logic             write_buf_req;              // ahb write request
    logic             write_buf_req_phase1;

    logic             write_memory_req;           // request to write the memory

    // write strobe generation
    logic [3:0]       w_info;
    logic  [3:0]      w_strobe;

    // Single entry write buffer
    logic  [31:0]     local_buf_addr;   // latest Write address, 4 bytes algin
    logic             local_buf_valid;  // If buffer is filled
    logic  [31:0]     local_buf_data;   // Write data
    logic  [ 3:0]     local_buf_wea;    // The write strobes

    logic            local_buf_hit;    // Bus 1 write hit
    logic             local_buf_hit_prev;

    // always ready (Which is the main purpose of this module)
    assign hreadyout_o  = 1'b1;

    /* AHB BUS Response  */
    assign hresp_o = HRESP_OKAY; //always OK

    // Need to do a read from memory if there is a read request
    assign read_memory_req = hsel_i & htrans_i[1] & ~hwrite_i;

    // Write to buffer each time a write transaction from bus comes in
    assign write_buf_req = hsel_i & htrans_i[1] & hwrite_i;

    // determine read from write buffer address
    assign local_buf_hit = read_memory_req & local_buf_valid & (haddr_i[31:2] == local_buf_addr[31:2]);

    // Write to memory if the write buffer is valid and
    // 1: Another write transation arised on the bus (the data will be available in the next cycle, we can use this cycle to finish writing)
    // Or
    // 2: No active transaction in this cycle(we can also use this idle cycle to finish the writing)
    assign write_memory_req  = local_buf_valid & ((htrans_i[1] & hwrite_i) | ~htrans_i[1]);

    // save the phase1 info into register
    always @(posedge hclk_i or negedge hresetn_i) begin
        if (!hresetn_i) begin
            read_memory_req_phase1 <= 1'b0;
            write_buf_req_phase1   <= 1'b0;

            // write buffer
            local_buf_addr      <= 31'b0;
            local_buf_data      <= 32'h0;
            local_buf_wea       <= 4'b0;
            local_buf_valid     <= 1'b0;
            local_buf_hit_prev  <= 1'b0;
        end else begin
            // keep the previous read and write transation request
            read_memory_req_phase1 <= read_memory_req;
            write_buf_req_phase1 <= write_buf_req;
            // in the previous cycle, read hit the local buf
            local_buf_hit_prev <= local_buf_hit;

            // write buffer update
            // Note that write strobes are derived from hsize_i[1:0] & address
            // this come in the address cycle, not the data cycle
            if (write_buf_req) begin
                local_buf_addr   <= haddr_i;
                local_buf_wea    <= w_strobe;
                local_buf_valid  <= 1'b1;
            end else if (write_memory_req) begin
                local_buf_valid  <= 1'b0; // write to the memory and clear the flag
            end

            // the previous cycle is a write transaction, pickup the data,
            if (write_buf_req_phase1) begin
                local_buf_data <=  hwdata_i;
            end
        end
    end // always


    // For a back-to-back write or a write followed by idle
    // use the AHB wdata as it is not yet in local_buf_data register
    always @( *) begin
        if ((write_buf_req_phase1 & write_buf_req ) || (write_buf_req_phase1 & write_memory_req))
            m_wdata = hwdata_i;
        else
            m_wdata = local_buf_data;
    end

    // write strobe generation using hsize_i[1:0] and LS address bits
    assign w_info = {hsize_i[1:0],haddr_i[1:0]} ;
    always @( w_info ) begin
        case (w_info)
            4'b00_00 : // byte, address 0
                w_strobe = 4'b0001;
            4'b00_01 : // byte, address 1
                w_strobe = 4'b0010;
            4'b00_10 : // byte, address 2
                w_strobe = 4'b0100;
            4'b00_11 : // byte, address 3
                w_strobe = 4'b1000;
            4'b01_00 : // HW, address 0
                w_strobe = 4'b0011;
            4'b01_01 : // HW, address 1 illegal!!
                w_strobe = 4'b0011;
            4'b01_10 : // HW, address 2
                w_strobe = 4'b1100;
            4'b01_11 : // HW, address 3 illegal!!
                w_strobe = 4'b1100;
            4'b10_00 : // word, address 0
                w_strobe = 4'b1111;
            4'b10_01 : // word, address 1 illegal!!
                w_strobe = 4'b1111;
            4'b10_10 : // word, address 2 illegal!!
                w_strobe = 4'b1111;
            4'b10_11 : // word, address 3 illegal!!
                w_strobe = 4'b1111;
            default :  // 64-bit: Not supported
                w_strobe = 4'b0000;
        endcase
    end

    // data on bus comes from write buffer or memory
    always @( * ) begin
        if (local_buf_hit_prev) begin
            // From write buffer only if write strobe was set
            hrdata_o[ 7: 0] = local_buf_wea[0] ? local_buf_data[ 7: 0] : m_rdata[ 7: 0];
            hrdata_o[15: 8] = local_buf_wea[1] ? local_buf_data[15: 8] : m_rdata[15: 8];
            hrdata_o[23:16] = local_buf_wea[2] ? local_buf_data[23:16] : m_rdata[23:16];
            hrdata_o[31:24] = local_buf_wea[3] ? local_buf_data[31:24] : m_rdata[31:24];
        end else
            hrdata_o = m_rdata;
    end

    // Memory interface, writes have priority
    assign m_write   = write_memory_req;
    assign m_read    = read_memory_req & ~m_write;
    assign m_address = m_write ? local_buf_addr : m_read ? haddr_i : 32'b0;
    assign m_wstrobe = local_buf_wea;

    logic[3:0] ram_wea;
    assign ram_wea = m_write ? m_wstrobe : 4'b0;

    //create a instance of the sram (bram of the fpga here)
    blk_mem_gen_0  ram_inst
    (
        .clka  (hclk_i            ),  // input logic clka
        .ena   (m_read|m_write  ),  // input logic ena
        .wea   (ram_wea         ),  // input logic[3:0] wea
        .addra (m_address[15:2] ),  // input logic [13 : 0] addra
        .dina  (m_wdata         ),  // input [31:0]dina;
        .douta (m_rdata         )   // output [31:0]douta;
    );

    // flash the led on reading
    logic [25:0]  rd_cnt;
    always @(posedge hclk_i) begin
        if (!hresetn_i) begin
            rd_cnt <= 26'd0;
        end else if(m_read) begin
            rd_cnt <= 26'd2500_0000;
        end else if (rd_cnt > 0 ) begin
            rd_cnt <= rd_cnt - 1'b1;
        end
    end
    assign leds_o[0]  = (rd_cnt > 0 ) ? 1'b1 : 1'b0;

    // flash the led on writing
    logic [25:0]  wr_cnt;
    always @(posedge hclk_i) begin
        if (!hresetn_i) begin
            wr_cnt <= 26'd0;
        end else if(m_write) begin
            wr_cnt <= 26'd2500_0000;
        end else if (wr_cnt > 0 ) begin
            wr_cnt <= wr_cnt - 1'b1;
        end
    end
    assign leds_o[1]  = ( wr_cnt > 0 ) ? 1'b1 : 1'b0;

endmodule // ahb_sram