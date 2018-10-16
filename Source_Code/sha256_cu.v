/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    sha256_cu.v
    Purpose: SHA256 Control Unit for orchestrating UART Rx, SHA256 Hasher, and UART Tx
    Input: Clk - Clock Input; Reset - Asynchronous Reset; Rx - Chunk data
	 Output: Tx - Digest; FramingErrorOccurred - UART Framing Error Detected Flag;
				ChunkRcvd - Chunk Received Flag; DigestReady - Digest Ready Flag;
				DigestTransmitted - Digest Transmitted Flag;
				
				WOut - Current calculated W value from input data (For testing purposes)
				CurrentHash - Current output from hashing round (For testing purposes)
*/

module sha256_cu (Clk, Reset, Rx, Tx, FramingErrorOccurred, ChunkRcvd, DigestReady, DigestTransmitted, WOut, CurrentHash);
	// States
	parameter 	RESET	=	2'b00,
					RX		=	2'b01,
					HASH	=	2'b10,
					TX		=	2'b11;
	
	// I/O
	input Clk, Reset, Rx;
	output Tx;
	output FramingErrorOccurred, ChunkRcvd, DigestReady, DigestTransmitted;
	output [31:0] WOut;
	output [255:0] CurrentHash;
	
	// State registers
	reg [1:0] Q_present = RESET, Q_next = RESET;
	
	// Module control signals
	reg ctrl_receive = 1'b0, ctrl_start_hashing = 1'b0, ctrl_transmit = 1'b0;
	// Module reset signals
	reg reset_rx = 1'b1, reset_sha = 1'b1, reset_tx = 1'b1;
	
	// Interconnect for UART Rx Reset Detected Flag (Indicates that user transmitted a reset control signal ('r' or 'R'))
	wire flag_reset_detected;
	
	// Interconnects for chunk and digest data
	wire [511:0] chunk;
	wire [255:0] digest;
	
	// Instantiate Rx, Hasher, and Tx modules and connect I/O appropriately
	uart_rx rx (Clk, reset_rx, ctrl_receive, Rx, chunk, FramingErrorOccurred, flag_reset_detected, ChunkRcvd);
	sha256 sha256 (Clk, reset_sha, ctrl_start_hashing, chunk, digest, DigestReady, WOut, CurrentHash);
	uart_tx tx (Clk, reset_tx, ctrl_transmit, digest, Tx, DigestTransmitted);
	
	always @ (posedge Clk)
		begin
			if (!Reset)
				begin
					Q_next <= RESET;
				end
			else
				begin
					case (Q_present)
						// State for reseting control and reset signals to the modules
						RESET : begin
							reset_rx <= 1'b0;
							reset_tx <= 1'b0;
							reset_sha <= 1'b0;
						
							ctrl_receive <= 1'b1;
							ctrl_start_hashing <= 1'b0;
							ctrl_transmit <= 1'b0;
							
							Q_next <= RX; // Default to listening for more data
						end
						// UART Rx State (listen and receive chunk data or reset key)
						RX : begin
							// De-assert reset signals
							reset_rx <= 1'b1;
							reset_tx <= 1'b1;
							reset_sha <= 1'b1;
							
							// If user sent reset key... reset the modules
							if (flag_reset_detected)
								begin
									Q_next <= RESET;
								end
							// If chunk received... hash it
							else if (ChunkRcvd)
								begin
									reset_tx <= 1'b0;
								
									ctrl_receive <= 1'b0; // De-assert receive control signal
									ctrl_start_hashing <= 1'b1; // Assert hasher control signal
									Q_next <= HASH; // Next state is hashing
								end
							else
								begin
									Q_next <= RX; // Otherwise... continue receiving or listening
								end
						end
						// Hashing state
						HASH : begin
							// If we've finished hashing...
							if (DigestReady)
								begin
									reset_rx <= 1'b0; // Reset Rx to clear the chunk register (data no longer needed)
									reset_tx <= 1'b1; // De-assert transmitter disable signal
									
									ctrl_start_hashing <= 1'b0; // De-assert hasher control signal
									ctrl_transmit <= 1'b1; // Assert transmitter control signal
									Q_next <= TX; // Next state is transmission
								end
							else
								begin
									Q_next <= HASH; // Continue hashing...
								end
						end
						// UART Transmission state
						TX : begin
							// If we've finished transmitting...
							if (DigestTransmitted)
								begin
									Q_next <= RESET; // Tranisition to Reset state to prepare for another round
								end
							else
								begin
									Q_next <= TX; // Continue transmitting
								end
						end
					endcase
				end
			Q_present <= Q_next; // Transition to next state
		end
	
endmodule 
// © 2017 Maxey-Vesperman, Butler