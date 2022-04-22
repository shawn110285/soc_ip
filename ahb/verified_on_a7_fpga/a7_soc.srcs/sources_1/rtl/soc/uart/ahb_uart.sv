/*-------------------------------------------------------------------------
// Module:  ahb2axi_uart
// File:    ahb2axi_uart.v
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


module ahb2axi_uart
(
    output   logic             leds_o,
    //ahb slave
    input    logic             hclk_i,
    input    logic             hresetn_i,
    input    logic             hsel_i,
    input    logic [31:0]      haddr_i,
    input    logic [31:0]      hwdata_i,
    input    logic             hwrite_i,
    input    logic [2:0]       hsize_i,
    input    logic [2:0]       hburst_i,
    input    logic [3:0]       hprot_i,
    input    logic [1:0]       htrans_i,
    input    logic             hready_i,
    output   logic             hreadyout_o,
    output   logic             hresp_o,
    output   logic [31:0]      hrdata_o,
    // UART
    input    logic             uart_rx_i,
    output   logic             uart_tx_o,
    output   logic             uart_int_o
);

    logic [25:0]  cnt;
    always @(posedge hclk_i) begin
        if (!hresetn_i) begin
            cnt <= 26'd0;
		end else if(hsel_i) begin
			cnt <= 26'd2500_0000;
		end else if (cnt > 0 ) begin
            cnt <= cnt - 1'b1;
	    end
    end
    assign leds_o = ( cnt > 0 ) ? 1'b1 : 1'b0;

	//1. ahb to axi
	//logic [3:0]  m_axi_awid;
	logic [7:0]  m_axi_awlen;
	logic [2:0]  m_axi_awsize;
	logic [1:0]  m_axi_awburst;
	logic [3:0]  m_axi_awcache;
	logic [31:0] m_axi_awaddr;
	logic [2:0]  m_axi_awprot;
	logic        m_axi_awvalid;
	logic        m_axi_awready;
	logic        m_axi_awlock;

	logic [31:0] m_axi_wdata;
	logic [3:0]  m_axi_wstrb;
	logic        m_axi_wlast;
	logic        m_axi_wvalid;
	logic        m_axi_wready;

	//logic [3:0]  m_axi_bid;
	logic [1:0]  m_axi_bresp;
	logic        m_axi_bvalid;
	logic        m_axi_bready;

	logic [3:0]  m_axi_arid;
	logic [7:0]  m_axi_arlen;
	logic [2:0]  m_axi_arsize;
	logic [1:0]  m_axi_arburst;
	logic [2:0]  m_axi_arprot;
	logic [3:0]  m_axi_arcache;
	logic        m_axi_arvalid;
	logic [31:0] m_axi_araddr;
	logic        m_axi_arlock;
	logic        m_axi_arready;

	// logic [3:0]  m_axi_rid;
	logic [31:0] m_axi_rdata;
	logic [1:0]  m_axi_rresp;
	logic        m_axi_rvalid;
	//logic        m_axi_rlast;
	logic        m_axi_rready;

	ahblite_axi_bridge_0 AHBLite2AXI_uart
	(
		.s_ahb_hclk       (hclk_i           ),      // input wire s_ahb_hclk
		.s_ahb_hresetn    (hresetn_i        ),       // input wire s_ahb_hresetn

		.s_ahb_hsel       (hsel_i           ),            // input wire s_ahb_hsel
		.s_ahb_haddr      (haddr_i          ),        // input wire [31 : 0] s_ahb_haddr
		.s_ahb_hwdata     (hwdata_i         ),        // input wire [31 : 0] s_ahb_hwdata
		.s_ahb_hwrite     (hwrite_i         ),        // input wire s_ahb_hwrite
		.s_ahb_hsize      (hsize_i          ),   // input wire [2 : 0] s_ahb_hsize
		.s_ahb_hburst     (hburst_i         ),           // input wire [2 : 0] s_ahb_hburst
		.s_ahb_hprot      (hprot_i          ),        // input wire [3 : 0] s_ahb_hprot
		.s_ahb_htrans     (htrans_i         ),        // input wire [1 : 0] s_ahb_htrans
		.s_ahb_hready_in  (hready_i         ),        // input wire s_ahb_hready_in
		.s_ahb_hready_out (hreadyout_o      ),        // output wire s_ahb_hready_out
		.s_ahb_hresp      (hresp_o          ),        // output wire s_ahb_hresp
		.s_ahb_hrdata     (hrdata_o         ),        // output wire [31 : 0] s_ahb_hrdata

		// axi A channel
		.m_axi_awid       (                 ),         // output wire [3 : 0] m_axi_awid
		.m_axi_awlen      (m_axi_awlen      ),         // output wire [7 : 0] m_axi_awlen
		.m_axi_awsize     (m_axi_awsize     ),         // output wire [2 : 0] m_axi_awsize
		.m_axi_awburst    (m_axi_awburst    ),         // output wire [1 : 0] m_axi_awburst
		.m_axi_awcache    (m_axi_awcache    ),         // output wire [3 : 0] m_axi_awcache
		.m_axi_awaddr     (m_axi_awaddr     ),         // output wire [31 : 0] m_axi_awaddr
		.m_axi_awprot     (m_axi_awprot     ),         // output wire [2 : 0] m_axi_awprot
		.m_axi_awvalid    (m_axi_awvalid    ),         // output wire m_axi_awvalid
		.m_axi_awready    (m_axi_awready    ),         // input wire m_axi_awready
		.m_axi_awlock     (m_axi_awlock     ),         // output wire m_axi_awlock


		// axi write data channel
		.m_axi_wdata      (m_axi_wdata      ),           // output wire [31 : 0] m_axi_wdata
		.m_axi_wstrb      (m_axi_wstrb      ),           // output wire [3 : 0] m_axi_wstrb
		.m_axi_wlast      (m_axi_wlast      ),           // output wire m_axi_wlast
		.m_axi_wvalid     (m_axi_wvalid     ),           // output wire m_axi_wvalid
		.m_axi_wready     (m_axi_wready     ),           // input wire m_axi_wready


		// b channel
		.m_axi_bid        ( 4'b0001         ),           // input wire [3 : 0] m_axi_bid
		.m_axi_bresp      (m_axi_bresp      ),           // input wire [1 : 0] m_axi_bresp
		.m_axi_bvalid     (m_axi_bvalid     ),           // input wire m_axi_bvalid
		.m_axi_bready     (m_axi_bready     ),           // output wire m_axi_bready

		// a channel
		.m_axi_arid       (m_axi_arid       ),           // output wire [3 : 0] m_axi_arid
		.m_axi_arlen      (m_axi_arlen      ),           // output wire [7 : 0] m_axi_arlen
		.m_axi_arsize     (m_axi_arsize     ),           // output wire [2 : 0] m_axi_arsize
		.m_axi_arburst    (m_axi_arburst    ),           // output wire [1 : 0] m_axi_arburst
		.m_axi_arprot     (m_axi_arprot     ),           // output wire [2 : 0] m_axi_arprot
		.m_axi_arcache    (m_axi_arcache    ),           // output wire [3 : 0] m_axi_arcache
		.m_axi_arvalid    (m_axi_arvalid    ),           // output wire m_axi_arvalid
		.m_axi_araddr     (m_axi_araddr     ),           // output wire [31 : 0] m_axi_araddr
		.m_axi_arlock     (m_axi_arlock     ),           // output wire m_axi_arlock
		.m_axi_arready    (m_axi_arready    ),           // input wire m_axi_arready

		// r channel
		.m_axi_rid        ( 4'b0001         ),            // input wire [3 : 0] m_axi_rid
		.m_axi_rdata      (m_axi_rdata      ),            // input wire [31 : 0] m_axi_rdata
		.m_axi_rresp      (m_axi_rresp      ),            // input wire [1 : 0] m_axi_rresp
		.m_axi_rvalid     (m_axi_rvalid     ),            // input wire m_axi_rvalid
		.m_axi_rlast      (1'b1             ),            // input wire m_axi_rlast
		.m_axi_rready     (m_axi_rready     )             // output wire m_axi_rready

	);

	axi_uartlite_0 axi_uartlite_inst
	(
	  .rx             (uart_rx_i),                   // input wire rx
	  .tx             (uart_tx_o),                   // output wire tx
	  .interrupt      (uart_int_o),           // output wire interrupt

	  .s_axi_aclk     (hclk_i),          // input wire s_axi_aclk
	  .s_axi_aresetn  (hresetn_i),     // input wire s_axi_aresetn

	  .s_axi_awaddr   (m_axi_awaddr[3:0]),    // input wire [3 : 0] s_axi_awaddr
	  .s_axi_awvalid  (m_axi_awvalid),  // input wire s_axi_awvalid
	  .s_axi_awready  (m_axi_awready),  // output wire s_axi_awready

	  .s_axi_wdata    (m_axi_wdata),      // input wire [31 : 0] s_axi_wdata
	  .s_axi_wstrb    (m_axi_wstrb),      // input wire [3 : 0] s_axi_wstrb
	  .s_axi_wvalid   (m_axi_wvalid),    // input wire s_axi_wvalid
	  .s_axi_wready   (m_axi_wready),    // output wire s_axi_wready

	  .s_axi_bresp    (m_axi_bresp),      // output wire [1 : 0] s_axi_bresp
	  .s_axi_bvalid   (m_axi_bvalid),    // output wire s_axi_bvalid
	  .s_axi_bready   (m_axi_bready),    // input wire s_axi_bready

	  .s_axi_araddr   (m_axi_araddr[3:0]),    // input wire [3 : 0] s_axi_araddr
	  .s_axi_arvalid  (m_axi_arvalid),  // input wire s_axi_arvalid
	  .s_axi_arready  (m_axi_arready),  // output wire s_axi_arready

	  .s_axi_rdata    (m_axi_rdata),      // output wire [31 : 0] s_axi_rdata
	  .s_axi_rresp    (m_axi_rresp),      // output wire [1 : 0] s_axi_rresp
	  .s_axi_rvalid   (m_axi_rvalid),    // output wire s_axi_rvalid
	  .s_axi_rready   (m_axi_rready)     // input wire s_axi_rready

	);

endmodule


