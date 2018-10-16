/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    tx_shiftr_reg_n.v
    Purpose: UART transmission shift register with fancy variable size parameter
    Input: Clk - Baud rate clock input; Reset - Asynchronous Reset; ALoad - Asynchronous parallel loading control signal
			  DataIn - 8-bit ASCII data for tranmission
	 Output: SO - Bit being shifted out; Empty - Flag to indicate that the Shift Register is empty
*/

module tx_shiftr_reg_n #(parameter BUS_WIDTH = 8) (Clk, Reset, ALoad, DataIn, SO, Empty);
	input Clk, Reset, ALoad; // Clock, Reset, and Asynchronous Load inputs
	input[BUS_WIDTH-1:0] DataIn; // Data to parallel load
	output reg SO = 1'b1; // Serial Out
	output reg Empty; // Shift Register Empty Flag
	reg[BUS_WIDTH+1:0] tmp; // START Bit + Data + STOP Bit
	reg[3:0] counter; // Maximum bits per frame = 10
	
	always @ (posedge Clk, posedge ALoad, negedge Reset)
		begin
			if (!Reset) // Active-Low reset
				begin
					tmp <= 0; // Clear the shift register
					SO <= 1'b1; // Clear the output
					counter <= (BUS_WIDTH + 4'd1);
					Empty <= 1'b1; // Set Empty flag to 1
				end
			else
				begin
					if (ALoad) // Load if Active-High Asynchronous Load asserted and Shift Register is empty
						begin
							if (Empty)
								begin
									// {STOP bit, MSB -> LSB, START bit}
									tmp <= {1'b1, DataIn[7:0], 1'b0}; // Load next set of data into shift register
									counter <= (BUS_WIDTH + 4'd1); // Load the counter
									Empty <= 1'b0; // Set Empty flag to 0
								end
						end
					else if (counter == 0) // STOP bit has been transmitted if counter = 0
						begin
							SO = tmp[0]; // Update output to Idle
							Empty = 1'b1; // Set Empty flag to 1
						end
					else // Shift right 1 if ALoad is not asserted
						begin
							SO = tmp[0]; // Output is the end bit of the shift register
							tmp = {1'b0, tmp[BUS_WIDTH+1:1]}; // Shift contents of the shift register one to the right
							counter = counter - 4'd1; // Decrement the counter
						end
				end
		end
endmodule 
// © 2017 Maxey-Vesperman, Butler