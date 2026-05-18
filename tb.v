`timescale 1ns/1ps

module tb;

    parameter WORD_LEN = 8;
    parameter XTAL_CLK = 50_000_000;
    parameter BAUD     = 115200;

    reg sys_clk;
    reg sys_rst_l;

    // TX SIDE INPUTS
    reg xmitH;
    reg [WORD_LEN-1:0] xmit_dataH;

    // RX SIDE INPUT
    reg uart_REC_dataH;

    // UART OUTPUTS
    wire uart_XMIT_dataH;

    wire xmit_doneH;
    wire xmit_active
    wire [WORD_LEN-1:0] rec_dataH;
    wire rec_readyH;
    wire rec_busy;

    // ---------------------------------
    // DUT
    // ---------------------------------
    uart #(
        .data_width (WORD_LEN),
        .xtal_clk (XTAL_CLK),
        .baud (BAUD)
    ) U_UART (
        .sys_clk         (sys_clk),
        .sys_rst_l       (sys_rst_l),
        .xmitH           (xmitH),
        .xmit_data     (xmit_dataH),
        .uart_xmit_data_H (uart_XMIT_dataH),
        .xmit_done(xmit_doneH),
        .xmit_active     (xmit_active),
        .uart_rec_dataH  (uart_REC_dataH),
        .rec_data_H       (rec_dataH),
        .rec_ready      (rec_readyH),
        .rec_busy        (rec_busy)
    );

    // ---------------------------------
    // SYSTEM CLOCK
    // ---------------------------------
    initial begin
        sys_clk = 0;
        forever #10 sys_clk = ~sys_clk;
    end

    // ---------------------------------
    // UART BIT TIME
    // ---------------------------------
    localparam BIT_TIME = 8680; // ns for 115200 baud

    // ---------------------------------
    // TASK : SEND TX DATA
    // ---------------------------------
    task send_tx_byte(input [7:0] data);
    begin
        @(posedge sys_clk);

        xmit_dataH = data;
        xmitH      = 1'b1;

        #5000;

        xmitH = 1'b0;
    end
    endtask

    // ---------------------------------
    // TASK : DRIVE RX SERIAL DATA
    // ---------------------------------
    task send_rx_byte(input [7:0] data);

        integer i;

        begin

            // IDLE
            uart_REC_dataH = 1'b1;
            #(BIT_TIME);

            // START BIT
            uart_REC_dataH = 1'b0;
            #(BIT_TIME);

            // DATA BITS (LSB FIRST)
            for(i=0; i<8; i=i+1) begin
                uart_REC_dataH = data[i];
                #(BIT_TIME);
            end

            // STOP BIT
            uart_REC_dataH = 1'b1;
            #(BIT_TIME);

        end
    endtask

    // ---------------------------------
    // MAIN TEST
    // ---------------------------------
    initial begin

        $dumpfile("tb.vcd");

        $dumpvars(0, tb);
        $dumpvars(0, tb.U_UART.U_XMIT);
        $dumpvars(0, tb.U_UART.U_REC);

        // INIT
        sys_rst_l  = 0;

        xmitH      = 0;
        xmit_dataH = 0;

        uart_REC_dataH    = 1'b1;

        #200;

        sys_rst_l = 1;

        #100000;

        // =====================================
        // TX TEST
        // =====================================

        $display("================================");
        $display("TX TEST");
        $display("================================");

        send_tx_byte(8'hA5);

        wait(xmit_doneH);

        $display("TX DONE : uart_tx waveform generated");

        #100000;
        
        

        // =====================================
        // RX TEST
        // =====================================

        $display("================================");
        $display("RX TEST");
        $display("================================");

        send_rx_byte(8'hA5);

        wait(rec_readyH);

        if(rec_dataH == 8'hA5)
            $display("[PASS] RX received = 0x%02X", rec_dataH);
        else
            $display("[FAIL] RX received = 0x%02X", rec_dataH);

        #100000;

        $finish;

    end

endmodule
