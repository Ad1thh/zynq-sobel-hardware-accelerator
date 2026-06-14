`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: sobel_axi_wrapper
// Description:
//   AXI4-Lite Slave wrapper mapping 4 configuration registers and interfacing 
//   with the pipelined spatial_filter_core module.
//////////////////////////////////////////////////////////////////////////////////

module sobel_axi_wrapper # (
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY
);

    reg [C_S_AXI_ADDR_WIDTH-1 : 0]     axi_awaddr;
    reg      axi_awready;
    reg      axi_wready;
    reg [1 : 0]     axi_bresp;
    reg      axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]     axi_araddr;
    reg      axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]     axi_rdata;
    reg [1 : 0]     axi_rresp;
    reg      axi_rvalid;

    localparam integer ADDR_LSB = 2;
    localparam integer OPT_MEM_ADDR_BITS = 1;

    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0]    slv_reg2;

    integer byte_index;

    assign S_AXI_AWREADY    = axi_awready;
    assign S_AXI_WREADY     = axi_wready;
    assign S_AXI_BRESP      = axi_bresp;
    assign S_AXI_BVALID     = axi_bvalid;
    assign S_AXI_ARREADY    = axi_arready;
    assign S_AXI_RDATA      = axi_rdata;
    assign S_AXI_RRESP      = axi_rresp;
    assign S_AXI_RVALID     = axi_rvalid;

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
          axi_awready <= 1'b0;
      end else begin    
          if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
              axi_awready <= 1'b1;
          end else begin
              axi_awready <= 1'b0;
          end
      end
    end       

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
          axi_awaddr <= 0;
      end else begin    
          if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
              axi_awaddr <= S_AXI_AWADDR;
          end
      end
    end       

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
          axi_wready <= 1'b0;
      end else begin    
          if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID) begin
              axi_wready <= 1'b1;
          end else begin
              axi_wready <= 1'b0;
          end
      end
    end       

    wire slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
          slv_reg0 <= 32'h0;
          slv_reg1 <= 32'h0;
          slv_reg2 <= 32'h0;
      end else begin
          if (slv_reg_wren) begin
              case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
                2'h0: begin
                  for ( byte_index = 0; byte_index <= 3; byte_index = byte_index+1 )
                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                      slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                end
                2'h1: begin
                  for ( byte_index = 0; byte_index <= 3; byte_index = byte_index+1 )
                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                      slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                end
                2'h2: begin
                  for ( byte_index = 0; byte_index <= 3; byte_index = byte_index+1 )
                    if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                      slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                end
                default : begin
                  slv_reg0 <= slv_reg0;
                  slv_reg1 <= slv_reg1;
                  slv_reg2 <= slv_reg2;
                end
              endcase
          end
      end
    end

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
          axi_bvalid  <= 1'b0;
          axi_bresp   <= 2'b0;
      end else begin    
          if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
              axi_bvalid <= 1'b1;
              axi_bresp  <= 2'b0;
          end else begin
              if (S_AXI_BREADY && axi_bvalid) begin
                  axi_bvalid <= 1'b0;
              end  
          end
      end
    end

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
          axi_arready <= 1'b0;
          axi_araddr  <= 32'b0;
      end else begin    
          if (~axi_arready && S_AXI_ARVALID) begin
              axi_arready <= 1'b1;
              axi_araddr  <= S_AXI_ARADDR;
          end else begin
              axi_arready <= 1'b0;
          end
      end
    end

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
          axi_rvalid <= 1'b0;
          axi_rresp  <= 2'b0;
      end else begin    
          if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
              axi_rvalid <= 1'b1;
              axi_rresp  <= 2'b0;
          end else if (axi_rvalid && S_AXI_RREADY) begin
              axi_rvalid <= 1'b0;
          end
      end
    end

    // Instantiate Pipelined Sobel Core
    wire [7:0] out_pixel;
    
    spatial_filter_core core_inst (
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        .p00(slv_reg0[7:0]),
        .p01(slv_reg0[15:8]),
        .p02(slv_reg0[23:16]),
        .p10(slv_reg1[7:0]),
        .p11(slv_reg1[15:8]),
        .p12(slv_reg1[23:16]),
        .p20(slv_reg2[7:0]),
        .p21(slv_reg2[15:8]),
        .p22(slv_reg2[23:16]),
        .out_pixel(out_pixel)
    );

    wire [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    
    assign reg_data_out = (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0) ? slv_reg0 :
                          (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h1) ? slv_reg1 :
                          (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) ? slv_reg2 :
                          (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h3) ? {24'h000000, out_pixel} :
                          32'h00000000;

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
          axi_rdata  <= 32'h0;
      end else begin    
          if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
              axi_rdata <= reg_data_out;
          end   
      end
    end

endmodule
