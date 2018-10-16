/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    uart_rx.v
    Purpose: UART Receiver Control Unit
    Input: Clk - System Clock input; Reset - Asynchronous reset; En - Enable module control input;
			  RxIn - Receiver input line
	 Output: ChunkOut - Preprocessed user input chunk data; FramingErrorOccurred - Framing error occurred flag;
				ResetDetected - Flag to indicate reset control input from user via UART;
				ChunkRcvd - Flag to indicate preprocessed chunk from user is received and available for hashing
*/

module uart_rx (Clk, Reset, En, RxIn, ChunkOut, FramingErrorOccurred, ResetDetected, ChunkRcvd);
	// States
	parameter	DISABLED				=	1'b0,
					RX_EN					=	1'b1;
					
	// I/O
	input Clk, Reset, En, RxIn;
	output FramingErrorOccurred, ResetDetected, ChunkRcvd;
	output [511:0] ChunkOut;

	// State regisers
	reg Q_present = DISABLED, Q_next = DISABLED;
	
	// Control and reset lines for shift register and baud rate clock generator
	reg brg_en = 1'b0, reset_sr = 1'b1;
	
	// Interconnect for baud rate to receiver
	wire baud_rate;
	
	// Instantiate modules with appropriate connections
	clock_50MHz_to_9600_baud brg (Clk, reset_sr, brg_en, baud_rate);
	rx_shift_reg sr (baud_rate, reset_sr, RxIn, ChunkOut, FramingErrorOccurred, ResetDetected, ChunkRcvd);
	
	always @ (posedge Clk, negedge Reset)
		begin
			if (!Reset) // Reset all registers and enter disabled state
				begin
					Q_present <= DISABLED;
					reset_sr <= 1'b0;
					brg_en <= 1'b0;
				end
			else
				begin
					case (Q_present)
						DISABLED: begin
							reset_sr <= 1'b1;
							if (En)
								begin
									brg_en <= 1'b1;
									Q_next <= RX_EN;
								end
							else
								begin
									Q_next <= DISABLED;
								end
						end
						RX_EN: begin
							if (!En)
								begin
									brg_en <= 1'b0;
									Q_next <= DISABLED;
								end
							else if (ResetDetected)
								begin
									brg_en <= 1'b0;
									Q_next <= DISABLED;
								end
							else
								begin
									Q_next <= RX_EN;
								end
						end
					endcase
				end
			Q_present <= Q_next; // Transition to next state
		end 
endmodule 
// © 2017 Maxey-Vesperman, Butler