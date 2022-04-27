
module ddr3_rw_top
(
    input                 sys_clk,
    input                 sys_rst_n,

    // DDR3
    inout   [31:0]        ddr3_dq      ,
    inout   [3:0]         ddr3_dqs_n   ,
    inout   [3:0]         ddr3_dqs_p   ,
    output  [13:0]        ddr3_addr    ,
    output  [2:0]         ddr3_ba      ,
    output                ddr3_ras_n   ,
    output                ddr3_cas_n   ,
    output                ddr3_we_n    ,
    output                ddr3_reset_n ,
    output  [0:0]         ddr3_ck_p    ,
    output  [0:0]         ddr3_ck_n    ,
    output  [0:0]         ddr3_cke     ,
    output  [0:0]         ddr3_cs_n    ,
    output  [3:0]         ddr3_dm      ,
    output  [0:0]         ddr3_odt     ,

    output                leds[3:0]
);

	//*****************************************************
	//**                    main code
	//*****************************************************

	//PLL
	wire                  clk_50, clk_200;
	wire                  locked;

    assign      leds[0] = locked;
	clk_divider u_clk_divider_0
	(
		// Clock out ports
		.clk_out1(clk_200),      // output clk_out1
		.clk_out2(clk_50),
		// Status and control signals
		.resetn(sys_rst_n),     // input resetn
		.locked(locked),        // output locked
		// Clock in ports
		.clk_in1(sys_clk)       // input clk_in1
	);
	
    // memory signals
    logic           app_rdy;              // MIG is ready to process request
    logic           app_wdf_rdy;           // MIG is ready to write data
	
    logic [2:0]     app_cmd;               // read or write cmd
    logic           app_en;                // start a cmd on mig
    logic [27:0]    app_addr;              // the address to access
    logic           app_wdf_wren;          // start the write on mig
    logic [255:0]   app_wdf_data;          // the data to write to ddr
    logic [31:0]    app_wdf_mask;          // the data mask for writing
    logic           app_wdf_end;           // the last data to write
 	
	logic           app_sr_active;       
	logic           app_ref_ack;         
	logic           app_zq_ack;         
    logic           ui_clk_sync_rst;  	
	
    logic           app_rd_data_valid;     // the data is valid in the mig
    logic [255:0]   app_rd_data;           // the data to read, each time 32 bytes
	logic           app_rd_data_end;  		
	
	logic           ui_clk;
	logic           init_calib_complete; 
	
	
	// AHB-light signals
	logic            HSEL;
	logic [31:0]     HADDR;

	logic            HWRITE;
	logic [2:0]      HSIZE;
	logic [2:0]      HBURST;
	logic [3:0]      HPROT;
	logic [1:0]      HTRANS;
	logic            HREADY; 
	logic [31:0]     HWDATA;

	logic            HRESP;
	logic            HREADYOUT;
	logic [31:0]     HRDATA;

    logic           ddr_ready;	
	assign ddr_ready = init_calib_complete;
	
    ahb_test_bench  u_ahb_test_bench_0
	(
        .led                    (leds[3]   ),
        .hclk_i                 (ui_clk    ),                  // System clock
        .hresetn_i              (ddr_ready ),                  // System reset

        // AHB-light Slave side, No prot, burst or resp
        .hsel_o                 (HSEL      ),
        .haddr_o                (HADDR     ),

        .hwrite_o               (HWRITE    ),
        .hsize_o                (HSIZE     ),
        .hburst_o               (HBURST    ),
        .hprot_o                (HPROT     ),
        .htrans_o               (HTRANS    ),
        .hready_o               (HREADY    ), // not used
        .hwdata_o               (HWDATA    ),

        .hresp_i                (HRESP     ),
        .hreadyout_i            (HREADYOUT ),
        .hrdata_i               (HRDATA    )
	);

    ila_0  ila_ahb_0
    (
        .clk(ui_clk),                    // input wire clk
        .probe0(HADDR),                  // input wire [31:0]  probe0
        .probe1(HWDATA),                 // input wire [31:0]  probe1
        .probe2(HRDATA),                 // input wire [31:0]  probe2
        .probe3(HWRITE),                 // input wire [0:0]  probe3
        .probe4(HREADYOUT),              // input wire [0:0]  probe4
        .probe5(HSEL),                   // input wire [0:0]  probe5 
	    .probe6(HREADY),                 // input wire [0:0]  probe6 
	    .probe7(HRESP),                  // input wire [0:0]  probe7 
	    .probe8(HTRANS),                 // input wire [1:0]  probe8     
		
         // ddr
        .probe9(app_rdy),                // input wire [0:0]  probe3
        .probe10(app_wdf_rdy),           // input wire [0:0]  probe4
        .probe11(app_rd_data_valid),     // input wire [0:0]  probe5 
	    .probe12(app_en),                // input wire [0:0]  probe6 
	    .probe13(app_wdf_wren),          // input wire [0:0]  probe7 
	    .probe14(app_wdf_end),           // input wire [0:0]  probe8  
        .probe15(app_cmd),		         // logic [2:0]     app_cmd
		
		.probe16(app_addr),              // logic [27:0]
	    .probe17(app_wdf_mask),          // input wire [31:0]  probe7   
		.probe18(app_wdf_data),          // app_wdf_data [255:0]
		.probe19(app_rd_data),           // [255:0]
		.probe20(app_rd_data_end),
		.probe21(1'b0)
    );

	
	

  	ahb2ddr  u_ahb2ddr
	(
        .hclk_i               (ui_clk),                   // System clock
        .hrstn_i              (ddr_ready),                // System reset

        // AHB-light Slave side,No prot, burst or resp
        .hsel_i               (HSEL),
        .haddr_i              (HADDR),
						     
        .hwrite_i             (HWRITE),
        .hsize_i              (HSIZE),
        .hburst_i             (HBURST),
        .hprot_i              (HPROT),
        .htrans_i             (HTRANS),
        .hready_i             (HREADY),                 // not used
        .hwdata_i             (HWDATA),
						     
        .hresp_o              (HRESP),
        .hreadyout_o          (HREADYOUT),
        .hrdata_o             (HRDATA),

         //mig status
		.app_rdy              (app_rdy),                 // MIG is ready to process request
		.app_wdf_rdy          (app_wdf_rdy),             // MIG is ready to write data

		.app_cmd              (app_cmd),		         // read or write cmd
		.app_en               (app_en),                  // start a cmd on mig
		.app_addr             (app_addr),                // the address to access

		//write
		.app_wdf_wren         (app_wdf_wren),            // start the write on mig
		.app_wdf_data         (app_wdf_data),            // the data to write to ddr
        .app_wdf_mask         (app_wdf_mask),            // the data mask for writing
 		.app_wdf_end          (app_wdf_end),             // the last data to write

        // read
		.app_rd_data_valid    (app_rd_data_valid),       // the data is valid for reading in the mig
		.app_rd_data          (app_rd_data)              // the data to read, each time 32 bytes
	);
	
   // clock domain crossing
	/*
	cdc u_cdc
	(
		.ui_clk               (ui_clk),                  // the ui clk from ddr mig
		.ui_clk_sync_rst      (ui_clk_sync_rst),         // the reset from ddr mig
		.init_calib_complete  (init_calib_complete),     // DDR3 init completed, signal from mig
	);
    */



	//MIG IP
	mig_7series_0 u_mig_7series_0
	(
		// Memory interface ports
		.ddr3_addr                      (ddr3_addr),           // output [14:0]	ddr3_addr
		.ddr3_ba                        (ddr3_ba),             // output [2:0]	ddr3_ba
		.ddr3_cas_n                     (ddr3_cas_n),          // output		ddr3_cas_n
		.ddr3_ck_n                      (ddr3_ck_n),           // output [0:0]	ddr3_ck_n
		.ddr3_ck_p                      (ddr3_ck_p),           // output [0:0]	ddr3_ck_p
		.ddr3_cke                       (ddr3_cke),            // output [0:0]	ddr3_cke
		.ddr3_ras_n                     (ddr3_ras_n),          // output		ddr3_ras_n
		.ddr3_reset_n                   (ddr3_reset_n),        // output		ddr3_reset_n
		.ddr3_we_n                      (ddr3_we_n),           // output		ddr3_we_n
		.ddr3_dq                        (ddr3_dq),             // inout [31:0]	ddr3_dq
		.ddr3_dqs_n                     (ddr3_dqs_n),          // inout [3:0]	ddr3_dqs_n
		.ddr3_dqs_p                     (ddr3_dqs_p),          // inout [3:0]	ddr3_dqs_p
		.init_calib_complete            (init_calib_complete), // output, init_calib_complete

		.ddr3_cs_n                      (ddr3_cs_n),           // output [0:0]	ddr3_cs_n
		.ddr3_dm                        (ddr3_dm),             // output [3:0]	ddr3_dm
		.ddr3_odt                       (ddr3_odt),            // output [0:0]	ddr3_odt

		// Application interface ports
		.app_addr                       (app_addr),            // input [28:0]	app_addr
		.app_cmd                        (app_cmd),             // input [2:0]	app_cmd
		.app_en                         (app_en),              // input			app_en
		.app_wdf_data                   (app_wdf_data),        // input [255:0] app_wdf_data
		.app_wdf_end                    (app_wdf_end),         // input         app_wdf_end
		.app_wdf_wren                   (app_wdf_wren),        // input	        app_wdf_wren
		.app_rd_data                    (app_rd_data),         // output [255:0]app_rd_data
		.app_rd_data_end                (app_rd_data_end),     // output	    app_rd_data_end
		.app_rd_data_valid              (app_rd_data_valid),   // output	    app_rd_data_valid
		.app_rdy                        (app_rdy),             // output	    app_rdy
		.app_wdf_rdy                    (app_wdf_rdy),         // output	    app_wdf_rdy
		.app_sr_req                     (1'b0 ),               // input	        app_sr_req
		.app_ref_req                    (1'b0 ),               // input	        app_ref_req
		.app_zq_req                     (1'b0 ),               // input	        app_zq_req
		.app_sr_active                  (app_sr_active),       // output	    app_sr_active
		.app_ref_ack                    (app_ref_ack),         // output	    app_ref_ack
		.app_zq_ack                     (app_zq_ack),          // output	    app_zq_ack
		.ui_clk                         (ui_clk),              // output	    ui_clk
		.ui_clk_sync_rst                (ui_clk_sync_rst),     // output        ui_clk_sync_rst
		.app_wdf_mask                   (32'b0   ),     // input [31:0]	app_wdf_mask         // app_wdf_mask
		.sys_clk_i                      (clk_200),             // System Clock Ports
		.clk_ref_i                      (clk_200),             // Reference Clock Ports
		.sys_rst                        (sys_rst_n)            // input         sys_rst
	);
	
endmodule
