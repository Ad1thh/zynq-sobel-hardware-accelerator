`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_spatial_filter
// Description:
//   An updated testbench to simulate and verify the 4-stage pipelined 
//   spatial_filter_core. Generates clock/reset signals and accounts for 
//   the 4-cycle pipeline propagation delay.
//////////////////////////////////////////////////////////////////////////////////

module tb_spatial_filter;

    // Clock and Reset signals
    reg clk;
    reg rst_n;

    // Inputs
    reg [7:0] p00, p01, p02;
    reg [7:0] p10, p11, p12;
    reg [7:0] p20, p21, p22;

    // Outputs
    wire [7:0] out_pixel;

    // Instantiate the Unit Under Test (UUT)
    spatial_filter_core uut (
        .clk(clk),
        .rst_n(rst_n),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .out_pixel(out_pixel)
    );

    // Clock Generation: 100 MHz clock (10 ns period)
    always #5 clk = ~clk;

    // Helper task to apply inputs, wait for pipeline latency, and display results
    task check_case(
        input [7:0] val00, input [7:0] val01, input [7:0] val02,
        input [7:0] val10, input [7:0] val11, input [7:0] val12,
        input [7:0] val20, input [7:0] val21, input [7:0] val22,
        input [80*8:1] label
    );
        begin
            p00 = val00; p01 = val01; p02 = val02;
            p10 = val10; p11 = val11; p12 = val12;
            p20 = val20; p21 = val21; p22 = val22;
            
            // Wait for 4 clock cycles (pipeline depth) for outputs to settle
            repeat (4) @(posedge clk);
            #1; // Wait 1 ns after clock edge for print accuracy
            
            $display("--- Test Case: %s ---", label);
            $display("  [%d\t%d\t%d]", p00, p01, p02);
            $display("  [%d\t%d\t%d]", p10, p11, p12);
            $display("  [%d\t%d\t%d]", p20, p21, p22);
            $display("Calculated Gx = %d, Gy = %d", uut.Gx_r2, uut.Gy_r2);
            $display("Total Gradient Magnitude = %d", (uut.abs_Gx_r3 + uut.abs_Gy_r3));
            $display("Output Pixel = 8'h%h (%s)\n", out_pixel, (out_pixel == 8'hFF) ? "EDGE" : "NO EDGE");
        end
    endtask

    initial begin
        $display("====================================================");
        $display("STARTING PIPELINED SOBEL ACCELERATOR SIMULATION");
        $display("====================================================\n");

        // Initialize signals
        clk = 0;
        rst_n = 0;
        
        // Hold reset for 20 ns
        #20;
        rst_n = 1;
        #10;

        // Case 1: Homogeneous Region (Flat background, no gradient)
        check_case(
            8'd100, 8'd100, 8'd100,
            8'd100, 8'd100, 8'd100,
            8'd100, 8'd100, 8'd100,
            "Flat Uniform Region (No Edge)"
        );

        // Case 2: Strong Vertical Edge Transition (Left side dark, Right side bright)
        check_case(
            8'd10,  8'd10,  8'd240,
            8'd10,  8'd10,  8'd240,
            8'd10,  8'd10,  8'd240,
            "Strong Vertical Edge"
        );

        // Case 3: Strong Horizontal Edge Transition (Top side dark, Bottom side bright)
        check_case(
            8'd10,  8'd10,  8'd10,
            8'd10,  8'd10,  8'd10,
            8'd240, 8'd240, 8'd240,
            "Strong Horizontal Edge"
        );

        // Case 4: Weak Edge (Under Threshold)
        check_case(
            8'd100, 8'd100, 8'd110,
            8'd100, 8'd100, 8'd110,
            8'd100, 8'd100, 8'd110,
            "Weak Edge (Under Threshold 128)"
        );

        $display("SIMULATION COMPLETE");
        $finish;
    end

endmodule
