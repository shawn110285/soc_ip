
module ahb2axi_uart
(
    output   logic             leds_o,
    input    logic             core_clk_i,
    input    logic             core_rstn_i,

	//ahb slave
    input    logic             s_ahb_hsel,
    input    logic [31:0]      s_ahb_haddr,

    input    logic [31:0]      s_ahb_hwdata,
    input    logic             s_ahb_hwrite,
    input    logic [1:0]       s_ahb_hsize,
    input    logic [2:0]       s_ahb_hburst,
    input    logic [3:0]       s_ahb_hprot,
    input    logic [1:0]       s_ahb_htrans,
    input    logic             s_ahb_hready_in,

    output   logic             s_ahb_hready_out,
    output   logic             s_ahb_hresp,
    output   logic [31:0]      s_ahb_hrdata,

	// UART
    input    logic             uart_rx_i,
	output   logic             uart_tx_o,
	output   logic             uart_int
);

    logic [25:0]  cnt;
    always @(posedge core_clk_i) begin
        if (!core_rstn_i) begin
            cnt <= 26'd0;
		end else if(s_ahb_hsel) begin
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
		.s_ahb_hclk       (core_clk_i         ),      // input wire s_ahb_hclk
		.s_ahb_hresetn    (core_rstn_i       ),       // input wire s_ahb_hresetn

		.s_ahb_hsel       (s_ahb_hsel       ),        // input wire s_ahb_hsel
		.s_ahb_haddr      (s_ahb_haddr      ),        // input wire [31 : 0] s_ahb_haddr
		.s_ahb_hwdata     (s_ahb_hwdata     ),        // input wire [31 : 0] s_ahb_hwdata
		.s_ahb_hwrite     (s_ahb_hwrite     ),        // input wire s_ahb_hwrite
		// HSIZE[2:0]: Indicates the size of the transfer, which is typically byte (8-bit), halfword (16-bit) or word (32-bit). The protocol allows for larger transfer sizes up to a maximum of 1024 bits.
		.s_ahb_hsize      ({1'b0, s_ahb_hsize  } ),   // input wire [2 : 0] s_ahb_hsize
		// HBURST[2:0]: Indicates if the transfer forms part of a burst. F
		.s_ahb_hburst     ( s_ahb_hburst ),           // input wire [2 : 0] s_ahb_hburst
		.s_ahb_hprot      (s_ahb_hprot      ),        // input wire [3 : 0] s_ahb_hprot
		.s_ahb_htrans     (s_ahb_htrans     ),        // input wire [1 : 0] s_ahb_htrans
		.s_ahb_hready_in  (s_ahb_hready_in  ),        // input wire s_ahb_hready_in
		.s_ahb_hready_out (s_ahb_hready_out ),        // output wire s_ahb_hready_out
		.s_ahb_hresp      (s_ahb_hresp      ),        // output wire s_ahb_hresp
		.s_ahb_hrdata     (s_ahb_hrdata     ),        // output wire [31 : 0] s_ahb_hrdata

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
	  .rx(uart_rx_i),                   // input wire rx
	  .tx(uart_tx_o),                   // output wire tx
	  .interrupt(uart_int),           // output wire interrupt

	  .s_axi_aclk(core_clk_i),          // input wire s_axi_aclk
	  .s_axi_aresetn(core_rstn_i),     // input wire s_axi_aresetn

	  .s_axi_awaddr(m_axi_awaddr[3:0]),    // input wire [3 : 0] s_axi_awaddr
	  .s_axi_awvalid(m_axi_awvalid),  // input wire s_axi_awvalid
	  .s_axi_awready(m_axi_awready),  // output wire s_axi_awready

	  .s_axi_wdata(m_axi_wdata),      // input wire [31 : 0] s_axi_wdata
	  .s_axi_wstrb(m_axi_wstrb),      // input wire [3 : 0] s_axi_wstrb
	  .s_axi_wvalid(m_axi_wvalid),    // input wire s_axi_wvalid
	  .s_axi_wready(m_axi_wready),    // output wire s_axi_wready

	  .s_axi_bresp(m_axi_bresp),      // output wire [1 : 0] s_axi_bresp
	  .s_axi_bvalid(m_axi_bvalid),    // output wire s_axi_bvalid
	  .s_axi_bready(m_axi_bready),    // input wire s_axi_bready

	  .s_axi_araddr(m_axi_araddr[3:0]),    // input wire [3 : 0] s_axi_araddr
	  .s_axi_arvalid(m_axi_arvalid),  // input wire s_axi_arvalid
	  .s_axi_arready(m_axi_arready),  // output wire s_axi_arready

	  .s_axi_rdata(m_axi_rdata),      // output wire [31 : 0] s_axi_rdata
	  .s_axi_rresp(m_axi_rresp),      // output wire [1 : 0] s_axi_rresp
	  .s_axi_rvalid(m_axi_rvalid),    // output wire s_axi_rvalid
	  .s_axi_rready(m_axi_rready)     // input wire s_axi_rready

	);

endmodule


