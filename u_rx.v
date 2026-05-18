module u_rx #(parameter data_width=8) (baud_clk,uart_rec_data_H,rec_data_H, rec_ready, rec_busy,rx_en,ready_clr);

input baud_clk;
input uart_rec_data_H;//serial input receiving dat 
output reg [7:0] rec_data_H;
output reg rec_ready;
output reg rec_busy;
input rx_en;
input ready_clr;

reg [3:0]sample=0;
reg [7:0] temp_data= 8'b0;
reg [1:0] state ;

parameter start=2'b00;
parameter r_data= 2'b01;
parameter stop = 2'b10;

reg [2:0] bit_pos;

reg rxd_ff1, rxd_ff2;
always @(posedge baud_clk) begin
    rxd_ff1 <= uart_rec_data_H;
    rxd_ff2 <= rxd_ff1;
end

always @(posedge baud_clk)
        begin
		if (ready_clr) rec_ready <= 1'b0;
		
		if (rx_en) begin
			rec_busy <=1'b1;
			sample <= sample+4'd1;
                case(state)
                        start : begin//sample at 2 times 
				if (sample ==4'd0) begin 
					if (rxd_ff2 !=1'b0) begin 
						sample <=4'd0;
					end
				end 

				else if (sample ==4'd8) begin 
					if (rxd_ff2 != 1'b0) begin 
						state<=start;
						sample <= 4'd0;
					end 
				end 

                                else if (sample ==4'd15) begin
                                        state<=r_data;
                                        sample <= 4'b0;
                                        temp_data <= 8'b0;
                                        bit_pos <=3'd0;
                                end
			end 

                        r_data : begin
				sample <= sample +1;
                                if (sample ==8 ) begin
                                        temp_data[bit_pos]<= rxd_ff2;
                                        bit_pos<= bit_pos+1;
				end 
				if (bit_pos ==8 && sample ==15 ) 
					state <= stop;
			end 

			stop: begin 
				if (sample ==15 ||(sample >=8 && !rxd_ff2)) begin 
					state <= start;
					rec_data_H <= temp_data;
					rec_ready <= 1'b1;
					sample <= 4'd0;
					rec_busy <= 1'b0;
		
				end 
				else sample <= sample +1;
			end 

			default : begin 
				state <= start ;
			end 
		endcase 
	end 
	end 
endmodule  
