`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: spatial_filter_core (4-Stage Pipelined)
// Description:
//   A high-performance 4-stage pipelined Sobel filter core.
//   Optimized to closure timing under a 5.0 ns clock period (200 MHz+).
//////////////////////////////////////////////////////////////////////////////////

module spatial_filter_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  p00, p01, p02,
    input  wire [7:0]  p10, p11, p12,
    input  wire [7:0]  p20, p21, p22,
    output reg  [7:0]  out_pixel
);

    // ==========================================
    // STAGE 1: Row Difference Calculation
    // ==========================================
    reg signed [10:0] diff_x0_r1;
    reg signed [10:0] diff_x1_r1;
    reg signed [10:0] diff_x2_r1;
    
    reg signed [10:0] diff_y0_r1;
    reg signed [10:0] diff_y1_r1;
    reg signed [10:0] diff_y2_r1;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            diff_x0_r1 <= 11'sd0;
            diff_x1_r1 <= 11'sd0;
            diff_x2_r1 <= 11'sd0;
            diff_y0_r1 <= 11'sd0;
            diff_y1_r1 <= 11'sd0;
            diff_y2_r1 <= 11'sd0;
        end else begin
            diff_x0_r1 <= $signed({3'b0, p02}) - $signed({3'b0, p00});
            diff_x1_r1 <= $signed({3'b0, p12}) - $signed({3'b0, p10});
            diff_x2_r1 <= $signed({3'b0, p22}) - $signed({3'b0, p20});
            
            diff_y0_r1 <= $signed({3'b0, p20}) - $signed({3'b0, p00});
            diff_y1_r1 <= $signed({3'b0, p21}) - $signed({3'b0, p01});
            diff_y2_r1 <= $signed({3'b0, p22}) - $signed({3'b0, p02});
        end
    end

    // ==========================================
    // STAGE 2: Gradient Summation (Gx, Gy)
    // ==========================================
    reg signed [10:0] Gx_r2;
    reg signed [10:0] Gy_r2;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            Gx_r2 <= 11'sd0;
            Gy_r2 <= 11'sd0;
        end else begin
            // Shift operation for hardware-efficient multiplier by 2
            Gx_r2 <= diff_x0_r1 + (diff_x1_r1 << 1) + diff_x2_r1;
            Gy_r2 <= diff_y0_r1 + (diff_y1_r1 << 1) + diff_y2_r1;
        end
    end

    // ==========================================
    // STAGE 3: Absolute Value Calculation
    // ==========================================
    reg signed [10:0] abs_Gx_r3;
    reg signed [10:0] abs_Gy_r3;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            abs_Gx_r3 <= 11'sd0;
            abs_Gy_r3 <= 11'sd0;
        end else begin
            abs_Gx_r3 <= (Gx_r2 < 0) ? -Gx_r2 : Gx_r2;
            abs_Gy_r3 <= (Gy_r2 < 0) ? -Gy_r2 : Gy_r2;
        end
    end

    // ==========================================
    // STAGE 4: Magnitude Addition & Thresholding
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_pixel <= 8'h00;
        end else begin
            out_pixel <= ((abs_Gx_r3 + abs_Gy_r3) > 12'd128) ? 8'hFF : 8'h00;
        end
    end

endmodule
