`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2026 20:08:49
// Design Name: 
// Module Name: tx_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tx_tb;

// Parameters
parameter BAUD_PERIOD = 416667; // 1/2400 in ns

// Inputs
reg baud_clk;
reg rst;
reg xmit_H;
reg [7:0] xmit_data;

// Outputs
wire xmit_active;
wire uart_xmit_data_H;
wire xmit_done;

// Instantiate DUT
u_xmit dut (
    .rst              (rst),
    .baud_clk         (baud_clk),
    .xmit_H           (xmit_H),
    .xmit_data        (xmit_data),
    .uart_xmit_data_H (uart_xmit_data_H),
    .xmit_active      (xmit_active),
    .xmit_done        (xmit_done)
);

// Clock generation
initial baud_clk = 0;
always #(BAUD_PERIOD/2) baud_clk = ~baud_clk;

// Stimulus
initial begin
    // Initialize
    rst       = 0;
    xmit_H    = 0;
    xmit_data = 8'h00;

    // Release reset
    repeat(3) @(posedge baud_clk);
    rst = 1;
    repeat(2) @(posedge baud_clk);

    // Test 1: Send 0x55
    xmit_data = 8'h55;
    xmit_H    = 1;
    @(posedge baud_clk);
    xmit_H = 0;
    repeat(200) @(posedge baud_clk);

    // Test 2: Send 0xA5
    xmit_data = 8'hA5;
    xmit_H    = 1;
    @(posedge baud_clk);
    xmit_H = 0;
    repeat(200) @(posedge baud_clk);

    // Test 3: Send 0xFF
    xmit_data = 8'hFF;
    xmit_H    = 1;
    @(posedge baud_clk);
    xmit_H = 0;
    repeat(200) @(posedge baud_clk);

    $finish;
end

// Waveform dum

initial begin
    $dumpfile("tx_tb.vcd");
    $dumpvars(0, tx_tb);
end

endmodule


