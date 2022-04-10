
module ahb2axi_ddr
(
    output   logic[1:0]        leds_o,
    input    logic             core_clk_i,
    input    logic             core_rstn_i,
	input    logic             ddr_clk_i,

	output   logic             ddr_ready_o,
	output   logic             ddr_ui_clk_o,

	//ahb slave
    input    logic             s_ahb_hsel,
    input    logic [31:0]      s_ahb_haddr,

    input    logic [31:0]      s_ahb_hwdata,
    input    logic             s_ahb_hwrite,

	// HSIZE[2:0] The amount of data written to the four internal registers depends on the transfer size setting, 32 (3'b010) or 64 bits (3'b011) wide
	// then HSIZE[1:0] would be sufficient
	//  2'b00:Byte   2'b01:halfword, 2'b10: word

	input    logic [2:0]       s_ahb_hsize,
    input    logic [2:0]       s_ahb_hburst,
    input    logic [3:0]       s_ahb_hprot,

    input    logic [1:0]       s_ahb_htrans,
    input    logic             s_ahb_hready_in,

    output   logic             s_ahb_hready_out,
    output   logic             s_ahb_hresp,
    output   logic [31:0]      s_ahb_hrdata,

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
    assign leds_o[1]  = ( cnt > 0 ) ? 1'b1 : 1'b0;

	//1. ahb to axi
	logic [3:0]  m_axi_awid;
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

	logic [3:0]  m_axi_bid;
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

	logic [3:0]  m_axi_rid;
	logic [31:0] m_axi_rdata;
	logic [1:0]  m_axi_rresp;
	logic        m_axi_rvalid;
	logic        m_axi_rlast;
	logic        m_axi_rready;


	ahblite_axi_bridge_0 AHBLite2AXI_DDR
	(
		.s_ahb_hclk       (core_clk_i       ),        // input wire s_ahb_hclk
		.s_ahb_hresetn    (ddr_ready_o      ),        // input wire s_ahb_hresetn

		.s_ahb_hsel       (s_ahb_hsel       ),        // input wire s_ahb_hsel
		.s_ahb_haddr      (s_ahb_haddr      ),        // input wire [31 : 0] s_ahb_haddr
		.s_ahb_hwdata     (s_ahb_hwdata     ),        // input wire [31 : 0] s_ahb_hwdata
		.s_ahb_hwrite     (s_ahb_hwrite     ),        // input wire s_ahb_hwrite
		.s_ahb_hsize      (s_ahb_hsize      ),        // input wire [2 : 0] s_ahb_hsize
		.s_ahb_hburst     (s_ahb_hburst     ),        // input wire [2 : 0] s_ahb_hburst
		.s_ahb_hprot      (s_ahb_hprot      ),        // input wire [3 : 0] s_ahb_hprot
		.s_ahb_htrans     (s_ahb_htrans     ),        // input wire [1 : 0] s_ahb_htrans
		.s_ahb_hready_in  (s_ahb_hready_in  ),        // input wire s_ahb_hready_in
		.s_ahb_hready_out (s_ahb_hready_out ),        // output wire s_ahb_hready_out
		.s_ahb_hresp      (s_ahb_hresp      ),        // output wire s_ahb_hresp
		.s_ahb_hrdata     (s_ahb_hrdata     ),        // output wire [31 : 0] s_ahb_hrdata

		// axi A channel
		.m_axi_awid       (m_axi_awid       ),        // output wire [3 : 0] m_axi_awid
		.m_axi_awlen      (m_axi_awlen      ),        // output wire [7 : 0] m_axi_awlen
		.m_axi_awsize     (m_axi_awsize     ),        // output wire [2 : 0] m_axi_awsize
		.m_axi_awburst    (m_axi_awburst    ),        // output wire [1 : 0] m_axi_awburst
		.m_axi_awcache    (m_axi_awcache    ),        // output wire [3 : 0] m_axi_awcache
		.m_axi_awaddr     (m_axi_awaddr     ),        // output wire [31 : 0] m_axi_awaddr
		.m_axi_awprot     (m_axi_awprot     ),        // output wire [2 : 0] m_axi_awprot
		.m_axi_awvalid    (m_axi_awvalid    ),        // output wire m_axi_awvalid
		.m_axi_awready    (m_axi_awready    ),        // input wire m_axi_awready
		.m_axi_awlock     (m_axi_awlock     ),        // output wire m_axi_awlock

		// axi write data channel
		.m_axi_wdata      (m_axi_wdata      ),        // output wire [31 : 0] m_axi_wdata

		// The write strobe signals, WSTRB, enable sparse data transfer on the write data bus.
		// Each write strobe signal corresponds to one byte of the write data bus.
		// When asserted, a write strobe indicates that the corresponding byte lane of the data bus
		// contains valid information to be updated in memory.
		.m_axi_wstrb      (m_axi_wstrb      ),        // output wire [3 : 0] m_axi_wstrb
		.m_axi_wlast      (m_axi_wlast      ),        // output wire m_axi_wlast
		.m_axi_wvalid     (m_axi_wvalid     ),        // output wire m_axi_wvalid
		.m_axi_wready     (m_axi_wready     ),        // input wire m_axi_wready

		// b channel
		.m_axi_bid        (m_axi_bid        ),        // input wire [3 : 0] m_axi_bid
		.m_axi_bresp      (m_axi_bresp      ),        // input wire [1 : 0] m_axi_bresp
		.m_axi_bvalid     (m_axi_bvalid     ),        // input wire m_axi_bvalid
		.m_axi_bready     (m_axi_bready     ),        // output wire m_axi_bready

		// a channel
		.m_axi_arid       (m_axi_arid       ),        // output wire [3 : 0] m_axi_arid
		.m_axi_arlen      (m_axi_arlen      ),        // output wire [7 : 0] m_axi_arlen
		.m_axi_arsize     (m_axi_arsize     ),        // output wire [2 : 0] m_axi_arsize
		.m_axi_arburst    (m_axi_arburst    ),        // output wire [1 : 0] m_axi_arburst
		.m_axi_arprot     (m_axi_arprot     ),        // output wire [2 : 0] m_axi_arprot
		.m_axi_arcache    (m_axi_arcache    ),        // output wire [3 : 0] m_axi_arcache
		.m_axi_arvalid    (m_axi_arvalid    ),        // output wire m_axi_arvalid
		.m_axi_araddr     (m_axi_araddr     ),        // output wire [31 : 0] m_axi_araddr
		.m_axi_arlock     (m_axi_arlock     ),        // output wire m_axi_arlock
		.m_axi_arready    (m_axi_arready    ),        // input wire m_axi_arready

		// r channel
		.m_axi_rid        (m_axi_rid        ),        // input wire [3 : 0] m_axi_rid
		.m_axi_rdata      (m_axi_rdata      ),        // input wire [31 : 0] m_axi_rdata
		.m_axi_rresp      (m_axi_rresp      ),        // input wire [1 : 0] m_axi_rresp
		.m_axi_rvalid     (m_axi_rvalid     ),        // input wire m_axi_rvalid
		.m_axi_rlast      (m_axi_rlast      ),        // input wire m_axi_rlast
		.m_axi_rready     (m_axi_rready     )         // output wire m_axi_rready
	);

	logic                            ui_clk;             // mig ui_clk
	logic                            ui_clk_sync_rst;    // mig ui_reset
	logic                            mmcm_locked;        // indicates the ui clock from mig is stable
	logic                            aresetn;
	logic [11:0]                     device_temp;

	logic                            init_calib_complete;
	logic                            ddr_reset;      // reset to the SoC

	assign ddr_ready_o = init_calib_complete;  //inform the cpu, ddr is ready
	assign ddr_ui_clk_o = ui_clk;

    // Signals from Master to axi slave converter
	logic [3:0]  s_axi_awid;
	logic [7:0]  s_axi_awlen;
	logic [2:0]  s_axi_awsize;
	logic [1:0]  s_axi_awburst;
	logic [3:0]  s_axi_awcache;
	logic [31:0] s_axi_awaddr;
	logic [2:0]  s_axi_awprot;
	logic        s_axi_awvalid;
	logic        s_axi_awready;
	logic        s_axi_awlock;

	logic [31:0] s_axi_wdata;
	logic [3:0]  s_axi_wstrb;
	logic        s_axi_wlast;
	logic        s_axi_wvalid;
	logic        s_axi_wready;

	logic [3:0]  s_axi_bid;
	logic [1:0]  s_axi_bresp;
	logic        s_axi_bvalid;
	logic        s_axi_bready;

	logic [3:0]  s_axi_arid;
	logic [7:0]  s_axi_arlen;
	logic [2:0]  s_axi_arsize;
	logic [1:0]  s_axi_arburst;
	logic [2:0]  s_axi_arprot;
	logic [3:0]  s_axi_arcache;
	logic        s_axi_arvalid;
	logic [31:0] s_axi_araddr;
	logic        s_axi_arlock;
	logic        s_axi_arready;

	logic [3:0]  s_axi_rid;
	logic [31:0] s_axi_rdata;
	logic [1:0]  s_axi_rresp;
	logic        s_axi_rvalid;
	logic        s_axi_rlast;
	logic        s_axi_rready;

    // Instantiating the clock converter between the core_clk_i and ddr_ui_clk) and DDR3 ui_clk
    clk_converter clock_converter
    (
		.s_axi_aclk(core_clk_i),
		.s_axi_aresetn(core_rstn_i),

		.s_axi_awid(m_axi_awid),
		.s_axi_awaddr(m_axi_awaddr),
		.s_axi_awlen(m_axi_awlen),
		.s_axi_awsize(m_axi_awsize),
		.s_axi_awburst(m_axi_awburst),
		.s_axi_awlock(m_axi_awlock),
		.s_axi_awcache(m_axi_awcache),
		.s_axi_awprot(m_axi_awprot),
		.s_axi_awregion(4'b0),
		.s_axi_awqos(4'b0),
		.s_axi_awvalid(m_axi_awvalid),
		.s_axi_awready(m_axi_awready),

		.s_axi_wdata(m_axi_wdata),
		.s_axi_wstrb(m_axi_wstrb),
		.s_axi_wlast(m_axi_wlast),
		.s_axi_wvalid(m_axi_wvalid),
		.s_axi_wready(m_axi_wready),

		.s_axi_bid(m_axi_bid),
		.s_axi_bresp(m_axi_bresp),
		.s_axi_bvalid(m_axi_bvalid),
		.s_axi_bready(m_axi_bready),

		.s_axi_arid(m_axi_arid),
		.s_axi_araddr(m_axi_araddr),
		.s_axi_arlen(m_axi_arlen),
		.s_axi_arsize(m_axi_arsize),
		.s_axi_arburst(m_axi_arburst),
		.s_axi_arlock(m_axi_arlock),
		.s_axi_arcache(m_axi_arcache),
		.s_axi_arprot(m_axi_arprot),
		.s_axi_arregion(4'b0),
		.s_axi_arqos(4'b0),
		.s_axi_arvalid(m_axi_arvalid),
		.s_axi_arready(m_axi_arready),

		.s_axi_rid(m_axi_rid),
		.s_axi_rdata(m_axi_rdata),
		.s_axi_rresp(m_axi_rresp),
		.s_axi_rlast(m_axi_rlast),
		.s_axi_rvalid(m_axi_rvalid),
		.s_axi_rready(m_axi_rready),

		.m_axi_aclk(ui_clk),
		.m_axi_aresetn(ddr_ready_o),

		.m_axi_awid(s_axi_awid),
		.m_axi_awaddr(s_axi_awaddr),
		.m_axi_awlen(s_axi_awlen),
		.m_axi_awsize(s_axi_awsize),
		.m_axi_awburst(s_axi_awburst),
		.m_axi_awlock(s_axi_awlock),
		.m_axi_awcache(s_axi_awcache),
		.m_axi_awprot(s_axi_awprot),
		.m_axi_awregion(),
		.m_axi_awqos(),
		.m_axi_awvalid(s_axi_awvalid),
		.m_axi_awready(s_axi_awready),

		.m_axi_wdata(s_axi_wdata),
		.m_axi_wstrb(s_axi_wstrb),
		.m_axi_wlast(s_axi_wlast),
		.m_axi_wvalid(s_axi_wvalid),
		.m_axi_wready(s_axi_wready),

		.m_axi_bid(s_axi_bid),
		.m_axi_bresp(s_axi_bresp),
		.m_axi_bvalid(s_axi_bvalid),
		.m_axi_bready(s_axi_bready),

		.m_axi_arid(s_axi_arid),
		.m_axi_araddr(s_axi_araddr),
		.m_axi_arlen(s_axi_arlen),
		.m_axi_arsize(s_axi_arsize),
		.m_axi_arburst(s_axi_arburst),
		.m_axi_arlock(s_axi_arlock),
		.m_axi_arcache(s_axi_arcache),
		.m_axi_arprot(s_axi_arprot),
		.m_axi_arregion(),
		.m_axi_arqos(),
		.m_axi_arvalid(s_axi_arvalid),
		.m_axi_arready(s_axi_arready),

		.m_axi_rid(s_axi_rid),
		.m_axi_rdata(s_axi_rdata),
		.m_axi_rresp(s_axi_rresp),
		.m_axi_rlast(s_axi_rlast),
		.m_axi_rvalid(s_axi_rvalid),
        .m_axi_rready(s_axi_rready)
    );


	mig_ddr3 ddr3_inst
	(
		// DDR Pins
		.ddr3_ck_p             (ddr3_ck_p),
		.ddr3_ck_n             (ddr3_ck_n),
		.ddr3_reset_n          (ddr3_reset_n),
		.ddr3_cke              (ddr3_cke),
		.ddr3_cs_n             (ddr3_cs_n),
		.ddr3_ras_n            (ddr3_ras_n),
		.ddr3_we_n             (ddr3_we_n),
		.ddr3_cas_n            (ddr3_cas_n),
		.ddr3_ba               (ddr3_ba),
		.ddr3_addr             (ddr3_addr),
		.ddr3_odt              (ddr3_odt),
		.ddr3_dqs_p            (ddr3_dqs_p),
		.ddr3_dqs_n            (ddr3_dqs_n),
		.ddr3_dq               (ddr3_dq),
		.ddr3_dm               (ddr3_dm),

		// Slave Interface Write Address Ports
		.s_axi_awid            (s_axi_awid),
		.s_axi_awaddr          (s_axi_awaddr[28:0]),
		.s_axi_awlen           (s_axi_awlen),
		.s_axi_awsize          (s_axi_awsize),
		.s_axi_awburst         (s_axi_awburst),
		.s_axi_awlock          (s_axi_awlock),
		.s_axi_awcache         (s_axi_awcache),
		.s_axi_awprot          (s_axi_awprot),
		.s_axi_awqos           (4'h0),
		.s_axi_awvalid         (s_axi_awvalid),
		.s_axi_awready         (s_axi_awready),

		// Slave Interface Write Data Ports
		.s_axi_wdata           (s_axi_wdata),
		.s_axi_wstrb           (s_axi_wstrb),
		.s_axi_wlast           (s_axi_wlast),
		.s_axi_wvalid          (s_axi_wvalid),
		.s_axi_wready          (s_axi_wready),

		// Slave Interface Write Response Ports
		.s_axi_bid             (s_axi_bid),
		.s_axi_bresp           (s_axi_bresp),
		.s_axi_bvalid          (s_axi_bvalid),
		.s_axi_bready          (s_axi_bready),

		// Slave Interface Read Address Ports
		.s_axi_arid            (s_axi_arid),
		.s_axi_araddr          (s_axi_araddr[28:0]),
		.s_axi_arlen           (s_axi_arlen),
		.s_axi_arsize          (s_axi_arsize),
		.s_axi_arburst         (s_axi_arburst),
		.s_axi_arlock          (s_axi_arlock),
		.s_axi_arcache         (s_axi_arcache),
		.s_axi_arprot          (s_axi_arprot),
		.s_axi_arqos           (4'h0),
		.s_axi_arvalid         (s_axi_arvalid),
		.s_axi_arready         (s_axi_arready),

		// Slave Interface Read Data Ports
		.s_axi_rid             (s_axi_rid),
		.s_axi_rdata           (s_axi_rdata),
		.s_axi_rresp           (s_axi_rresp),
		.s_axi_rlast           (s_axi_rlast),
		.s_axi_rvalid          (s_axi_rvalid),
		.s_axi_rready          (s_axi_rready),

		// Misc
		.sys_clk_i             (ddr_clk_i),  //ddr3_main,  This is the system clock input for the memory interface and is typically connected to a low-jitter external clock source.
		.clk_ref_i             (ddr_clk_i),  // This is the reference frequency input for the IDELAY control. must be 200Mhz

		.ui_clk                (ui_clk),
		.ui_clk_sync_rst       (ui_clk_sync_rst),
		
		.mmcm_locked           (mmcm_locked),
		.aresetn               (1'b1),  //
		.app_sr_req            (1'b0),  // This input is reserved and should be tied to 0.
		.app_ref_req           (1'b0),  // This active-High input requests that a refresh command be issued to the DRAM.
		.app_zq_req            (1'b0),  // This active-High input requests that a ZQ calibration command be issued to the DRAM
		.app_sr_active         (),      // This output is reserved.
		.app_ref_ack           (),      // This active-High output indicates that the memory controller has sent the requested refresh command to the PHY interface.
		.app_zq_ack            (),      // This active-High output indicates that the memory controller has sent the requested ZQ calibration command to the PHY interface.

		.init_calib_complete   (init_calib_complete), // This output indicates that the memory initialization and calibration is complete and that the interface is ready to use.
		.sys_rst               (1'b1        ),        // This is the system reset input that can be generated internally or driven from a pin.
		.device_temp           (device_temp        )
	);

    logic  init_cmplt;
    always @(posedge core_clk_i) begin
	    if((!core_rstn_i) || (ui_clk_sync_rst) || (!mmcm_locked) ) begin
		    init_cmplt <= 0;
		end else if(init_calib_complete) begin
		    init_cmplt <= 1;
		end else begin

		end
    end
    assign leds_o[0] = init_cmplt; //indicate the ddr init completed

endmodule