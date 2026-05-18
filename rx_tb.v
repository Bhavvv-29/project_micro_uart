
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.05.2026 12:56:28
// Design Name: 
// Module Name: rx_tb
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


module rx_tb;


   // -------------------------------------------------------------------------
    // Parameters - must match DUT
    // -------------------------------------------------------------------------
    parameter DATA_WIDTH  = 8;
    parameter CLK_PERIOD  = 20;    // 50 MHz clock
    parameter BAUD_CYCLES = 16;    // 1 baud = 16 clock cycles

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    reg  baud_clk;
    reg  rst;
    reg  uart_rec_data_H;
    reg  rx_en;
    reg  ready_clr;

    wire [DATA_WIDTH-1:0] rec_data_H;
    wire rec_ready;
    wire rec_busy;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    u_rec #(.data_width(DATA_WIDTH)) DUT (
        .rst             (rst),
        .baud_clk        (baud_clk),
        .uart_rec_data_H (uart_rec_data_H),
        .rec_data_H      (rec_data_H),
        .rec_ready       (rec_ready),
        .rec_busy        (rec_busy),
        .rx_en           (rx_en),
        .ready_clr       (ready_clr)
    );

    // -------------------------------------------------------------------------
    // Clock generation
    // -------------------------------------------------------------------------
    initial baud_clk = 0;
    always #(CLK_PERIOD/2) baud_clk = ~baud_clk;

    // -------------------------------------------------------------------------
    // Task : wait N clock edges
    // -------------------------------------------------------------------------
    task wait_clk;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge baud_clk);
        end
    endtask

    // -------------------------------------------------------------------------
    // Task : send one UART frame
    //   - 1 start bit (LOW)
    //   - 8 data bits LSB first
    //   - 1 stop bit (HIGH)
    // -------------------------------------------------------------------------
    task send_uart_byte;
        input [DATA_WIDTH-1:0] data;
        integer i;
        begin
            // Start bit
            uart_rec_data_H = 1'b0;
            wait_clk(BAUD_CYCLES);

            // Data bits - LSB first
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin
                uart_rec_data_H = data[i];
                wait_clk(BAUD_CYCLES);
            end

            // Stop bit
            uart_rec_data_H = 1'b1;
            wait_clk(BAUD_CYCLES);
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        // Initialise all inputs
        rst             = 1'b0;   // active-LOW reset - assert first
        uart_rec_data_H = 1'b1;   // idle line is HIGH
        rx_en           = 1'b0;
        ready_clr       = 1'b0;

        // Apply reset for 5 clocks then release
        wait_clk(5);
        rst   = 1'b1;             // release reset
        rx_en = 1'b1;             // enable receiver
        wait_clk(3);

        // =================================================================
        // TEST 1 : Send 0x55 (01010101 - alternating bits)
        // =================================================================
        $display("TEST 1 : Sending 0x55");
        send_uart_byte(8'h55);
        wait_clk(2);
        if (rec_data_H == 8'h55 && rec_ready == 1'b1)
            $display("  PASS : received 0x%02X", rec_data_H);
        else
            $display("  FAIL : expected 0x55, got 0x%02X  ready=%b",
                     rec_data_H, rec_ready);
        // Clear ready
        ready_clr = 1'b1; wait_clk(1); ready_clr = 1'b0;
        wait_clk(5);

        // =================================================================
        // TEST 2 : Send 0xA3 (random byte)
        // =================================================================
        $display("TEST 2 : Sending 0xA3");
        send_uart_byte(8'hA3);
        wait_clk(2);
        if (rec_data_H == 8'hA3 && rec_ready == 1'b1)
            $display("  PASS : received 0x%02X", rec_data_H);
        else
            $display("  FAIL : expected 0xA3, got 0x%02X  ready=%b",
                     rec_data_H, rec_ready);
        ready_clr = 1'b1; wait_clk(1); ready_clr = 1'b0;
        wait_clk(5);

        // =================================================================
        // TEST 3 : Send 0x00 (all zeros)
        // =================================================================
        $display("TEST 3 : Sending 0x00");
        send_uart_byte(8'h00);
        wait_clk(2);
        if (rec_data_H == 8'h00 && rec_ready == 1'b1)
            $display("  PASS : received 0x%02X", rec_data_H);
        else
            $display("  FAIL : expected 0x00, got 0x%02X  ready=%b",
                     rec_data_H, rec_ready);
        ready_clr = 1'b1; wait_clk(1); ready_clr = 1'b0;
        wait_clk(5);

        // =================================================================
        // TEST 4 : Send 0xFF (all ones)
        // =================================================================
        $display("TEST 4 : Sending 0xFF");
        send_uart_byte(8'hFF);
        wait_clk(2);
        if (rec_data_H == 8'hFF && rec_ready == 1'b1)
            $display("  PASS : received 0x%02X", rec_data_H);
        else
            $display("  FAIL : expected 0xFF, got 0x%02X  ready=%b",
                     rec_data_H, rec_ready);
        ready_clr = 1'b1; wait_clk(1); ready_clr = 1'b0;
        wait_clk(5);

        // =================================================================
        // TEST 5 : Back-to-back - 0x12 then 0x34
        // =================================================================
        $display("TEST 5 : Back-to-back 0x12 then 0x34");
        send_uart_byte(8'h12);
        wait_clk(2);
        if (rec_data_H == 8'h12 && rec_ready == 1'b1)
            $display("  PASS : first byte 0x%02X", rec_data_H);
        else
            $display("  FAIL : expected 0x12, got 0x%02X", rec_data_H);
        ready_clr = 1'b1; wait_clk(1); ready_clr = 1'b0;

        send_uart_byte(8'h34);
        wait_clk(2);
        if (rec_data_H == 8'h34 && rec_ready == 1'b1)
            $display("  PASS : second byte 0x%02X", rec_data_H);
        else
            $display("  FAIL : expected 0x34, got 0x%02X", rec_data_H);
        ready_clr = 1'b1; wait_clk(1); ready_clr = 1'b0;
        wait_clk(5);

        $display("Simulation done.");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Watchdog - stops infinite simulation
    // -------------------------------------------------------------------------
    initial begin
        #5_000_000;
        $display("TIMEOUT");
        $finish;
    end
    
endmodule

