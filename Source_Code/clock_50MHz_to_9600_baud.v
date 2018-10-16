/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    clock_50MHz_to_9600_baud.v
    Purpose: Generates clock signal for UART Tx/Rx
    Input: Clk - System Clock input; Reset - Asynchronous Reset; En - Enable/Disable output
	 Output: ClkOut - Appropriately scaled clock signal
*/

module clock_50MHz_to_9600_baud (ClkIn, Reset, En, ClkOut);
	parameter MAX_CNT = 12'd2603; // 9600 baud // Set to 12'd1 for simulation purposes
	
	// I/O
	input ClkIn, Reset, En;
	output reg ClkOut = 1'b0;
	
	// Count down from 2604 for toggle (~ 2x baud rate)
	reg [11:0] counter = MAX_CNT;
	
	always @(posedge ClkIn, negedge Reset)
		begin
			if (!Reset)
				begin
					counter <= MAX_CNT; // reset counter
					ClkOut <= 1'b0; // reset output
				end
			else
				begin
					if (!En)
						begin
							counter <= MAX_CNT; // reset counter
							ClkOut <= 1'b0; // reset output
						end
					// If counter has reached zero... time to toggle and reset counter
					else if (counter == 0)
						begin
							counter <= MAX_CNT;
							ClkOut <= ~ClkOut;
						end
					// Otherwise... decrement counter
					else
						begin
							counter <= counter - 12'd1;
						end
				end
		end
endmodule 
// © 2017 Maxey-Vesperman, Butler