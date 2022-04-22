/*-------------------------------------------------------------------------
// Module:  simple_soc
// File:    simple_soc.v
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

module simple_soc
(
    input  logic              sys_clk_i,
    input  logic              sys_rstn_i,
    /*
    input  logic              jtag_tck,
    input  logic              jtag_tdi,
    input  logic              jtag_tms,
    output logic              jtag_tdo, */

    input  logic               uart_rx,
    output logic               uart_tx,
    output logic[3:0]          leds,

    // DDR3 SDRAM
    inout  logic [31:0]        ddr3_dq      ,
    inout  logic [3:0]         ddr3_dqs_n   ,
    inout  logic [3:0]         ddr3_dqs_p   ,
    output logic [13:0]        ddr3_addr    ,
    output logic [2:0]         ddr3_ba      ,
    output logic               ddr3_ras_n   ,
    output logic               ddr3_cas_n   ,
    output logic               ddr3_we_n    ,
    output logic               ddr3_reset_n ,
    output logic [0:0]         ddr3_ck_p    ,
    output logic [0:0]         ddr3_ck_n    ,
    output logic [0:0]         ddr3_cke     ,
    output logic [0:0]         ddr3_cs_n    ,
    output logic [3:0]         ddr3_dm      ,
    output logic [0:0]         ddr3_odt
);

    logic  clk5M, clk25M, clk200M;
    logic  core_clk;
    logic  ddr_clk_o;
    logic  ddr_ready_o;

    assign core_clk = clk25M;

   // ---------- Clock divider ----------------//
    logic  clk_locked;          // indicates pll is stable
    assign core_rstn = sys_rstn_i & clk_locked;

    clk_divider u_clk_div
	(
	   .clk_out1(clk200M),      // output clk_out1, 200M
	   .clk_out2(clk25M),       // output clk_out2, 20M
	   .clk_out3(clk5M),        // output clk_out2, 5M
	   .resetn(sys_rstn_i),     // input resetn
	   .locked(clk_locked),     // output locked
	   .clk_in1(sys_clk_i)      // input clk_in1
    );

    // sram1
    logic [13:0]   ccm1_mem_addr_o ;  //2**4= 16K
    logic          ccm1_mem_csb_o  ;
    logic          ccm1_mem_rwb_o  ;
    logic [3:0]    ccm1_mem_wm_o   ;
    logic [31:0]   ccm1_mem_wdata_o;
    logic [31:0]   ccm1_mem_rdata_i;

    logic[3:0] ccm1_wea;
    assign ccm1_wea = ccm1_mem_rwb_o ? ccm1_mem_wm_o : 4'b0;

    blk_mem_gen_0  tim0
    (
        .clka  (core_clk              ),  // input wire clka
        .ena   (~ccm1_mem_csb_o       ),  // input wire ena
        .wea   (ccm1_wea              ),  // input [3:0]wea
        .addra (ccm1_mem_addr_o       ),  // input wire [31 : 0] addra
        .dina  (ccm1_mem_wdata_o      ),  // input [31:0]dina;
        .douta (ccm1_mem_rdata_i      )   // output [31:0]douta;
    );

    // sram2
    logic [13:0]   ccm2_mem_addr_o ;
    logic          ccm2_mem_csb_o  ;
    logic          ccm2_mem_rwb_o  ;
    logic [3:0]    ccm2_mem_wm_o   ;
    logic [31:0]   ccm2_mem_wdata_o;
    logic [31:0]   ccm2_mem_rdata_i;

    logic[3:0] ccm2_wea;
    assign ccm2_wea = ccm2_mem_rwb_o ? ccm2_mem_wm_o : 4'b0;

    blk_mem_tim  tim1
    (
        .clka  (core_clk              ),  // input wire clka
        .ena   (~ccm2_mem_csb_o       ),  // input wire ena
        .wea   (ccm2_wea              ),  // input [3:0]wea
        .addra (ccm2_mem_addr_o       ),  // input wire [11 : 0] addra
        .dina  (ccm2_mem_wdata_o      ),  // input [31:0]dina;
        .douta (ccm2_mem_rdata_i      )   // output [31:0]douta;
    );

    // AHB master interface
    logic         ddr_hsel;
    logic [31:0]  ddr_haddr;
    logic [31:0]  ddr_hwdata;
    logic         ddr_hwrite;
    logic [1:0]   ddr_hsize;
    logic         ddr_hburst;
    logic [3:0]   ddr_hprot;
    logic [1:0]   ddr_htrans;
    logic         ddr_hready;
    logic         ddr_hreadyout;
    logic         ddr_hresp;
    logic [31:0]  ddr_hrdata;

   /* use the sram  as ddr */
   /*
    ahb2sram   ahb_sram0
    (
        .leds_o     (leds_o[2:1])
        .hclk_i     (core_clk),
        .hresetn_i  (core_rstn),
        .hsel_i     (ddr_hsel),            //input
        .haddr_i    (ddr_haddr),           //input      [HADDR_SIZE-1:0]
        .hwdata_i   (ddr_hwdata),          //input      [HDATA_SIZE-1:0]
        .hwrite_i   (ddr_hwrite),          //input
        .hsize_i    ({1'b0, ddr_hsize}),   //input      [           2:0]
        .hburst_i   ({2'b0, ddr_hburst}),  //input      [           2:0]
        .hprot_i    (ddr_hprot),           //input      [           3:0]
        .htrans_i   (ddr_htrans),          //input      [           1:0]
        .hready_i   (ddr_hready),          //input

        .hreadyout_o(ddr_hreadyout),       //output reg
        .hresp_o    (ddr_hresp),           //output
        .hrdata_o   (ddr_hrdata)           //output reg [HDATA_SIZE-1:0]
    );
    */

    ahb2axi_ddr  ddr_inst
    (
	    .leds_o           (leds[2:1]           ),
	    //AHB
	    .hclk_i           (core_clk            ),
	    .hresetn_i        (core_rstn           ),
	    .hsel_i           (ddr_hsel            ),
	    .haddr_i          (ddr_haddr           ),
	    .hwdata_i         (ddr_hwdata          ),
	    .hwrite_i         (ddr_hwrite          ),
	    .hsize_i          ( {1'b0, ddr_hsize } ),
	    .hburst_i         ( {2'b0, ddr_hburst} ),
	    .hprot_i          (ddr_hprot           ),
	    .htrans_i         (ddr_htrans          ),
	    .hready_i         (ddr_hready          ),
	    .hreadyout_o      (ddr_hreadyout       ),
	    .hresp_o          (ddr_hresp           ),
	    .hrdata_o	      (ddr_hrdata          ),

        //ddr clock
        .clk200M_i        (clk200M             ),
        .ddr_ready_o      (ddr_ready_o         ),
        .ddr_ui_clk_o     (ddr_clk_o           ),
        //ddr
        .ddr3_reset_n     (ddr3_reset_n        ),
        .ddr3_cke         (ddr3_cke            ),
        .ddr3_ck_p        (ddr3_ck_p           ),
        .ddr3_ck_n        (ddr3_ck_n           ),
        .ddr3_cs_n        (ddr3_cs_n           ),
        .ddr3_ras_n       (ddr3_ras_n          ),
        .ddr3_cas_n       (ddr3_cas_n          ),
        .ddr3_we_n        (ddr3_we_n           ),
        .ddr3_ba          (ddr3_ba             ),
        .ddr3_addr        (ddr3_addr           ),
        .ddr3_odt         (ddr3_odt            ),
        .ddr3_dm          (ddr3_dm             ),
        .ddr3_dqs_p       (ddr3_dqs_p          ),
        .ddr3_dqs_n       (ddr3_dqs_n          ),
        .ddr3_dq		  (ddr3_dq             )
    );

    // uart
    logic          uart_hsel;
    logic [31 : 0] uart_haddr;
    logic [31 : 0] uart_hwdata;
    logic          uart_hwrite;
    logic [1 : 0]  uart_hsize;
    logic          uart_hburst;
    logic [3 : 0]  uart_hprot;
    logic [1 : 0]  uart_htrans;
    logic          uart_hready;
    logic          uart_hreadyout;
    logic          uart_hresp;
    logic [31 : 0] uart_hrdata;

    logic          uart_int;

    ahb2axi_uart uart_inst
    (
        .leds_o       (                     ),
        .hclk_i       (core_clk             ),
        .hresetn_i    (core_rstn            ),

        .hsel_i       (uart_hsel            ),
        .haddr_i      (uart_haddr           ),
        .hwdata_i     (uart_hwdata          ),
        .hwrite_i     (uart_hwrite          ),
        .hsize_i      ( {1'b0, uart_hsize}  ),
        .hburst_i     ( {2'b0, uart_hburst} ),
        .hprot_i      (uart_hprot           ),
        .htrans_i     (uart_htrans          ),
        .hready_i     (uart_hready          ),

        .hreadyout_o  (uart_hreadyout       ),
        .hresp_o      (uart_hresp           ),
        .hrdata_o     (uart_hrdata          ),

        //uart
        .uart_rx_i    (uart_rx              ),
        .uart_tx_o    (uart_tx              ),
        .uart_int_o   (uart_int             )
    );

    logic[31:0] jtag_idcode;
    assign jtag_idcode = {4'h1, 16'h3200, 11'h537, 1'h1};

    logic      jtag_tck = 1'b0;
    logic      jtag_tdi = 1'b0;;
    logic      jtag_tms = 1'b0;;
    logic      jtag_tdo;

   //delay the instruction fetch
    logic fetch_enable;
    logic [10:0] fetch_clk_cnt;
    always @(posedge core_clk or negedge core_rstn) begin
        if (!core_rstn) begin
            fetch_enable <= 1'b0;
            fetch_clk_cnt <= 11'b0;
        end else begin
            fetch_clk_cnt <= fetch_clk_cnt + 1;
            if(fetch_clk_cnt>100) begin
                fetch_enable <= 1;
            end
        end
    end

    assign leds[0] = fetch_enable;

endmodule
