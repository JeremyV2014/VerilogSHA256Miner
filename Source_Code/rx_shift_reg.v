/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
	 rx_shift_reg.v
    Purpose: Rx Shift register for accepting / preprocessing chunk data for message schedule array
    Input: Clk - System Clock input; Reset - Asynchronous Reset; Rx - incoming UART data
	 Output: ChunkOut - Preprocessed Chunk Data; FramingError - UART Framing Error flag
				ResetRcvd - Reset character received flag; ChunkReady - Chunk received and processed flag
*/

module rx_shift_reg (Clk, Reset, Rx, ChunkOut, FramingError, ResetRcvd, ChunkReady);
	// States
	parameter	WAIT_FOR_EOF			=	3'b000, // Used for realigning receiver with UART frames
					START_BIT_DETECT		=	3'b001,
					RECEIVE_BYTE			=	3'b010,
					STOP_BIT_DETECT		=	3'b011,
					FRAMING_ERROR			=	3'b100,
					RESET_DETECTED			=	3'b101,
					CR_DETECTED				=	3'b110,
					CHUNK_READY				=	3'b111;
	
	// I/O
	input Clk, Reset, Rx;
	output reg FramingError, ResetRcvd, ChunkReady;
	output reg [511:0] ChunkOut;
	
	// State registers
	reg [2:0] Q_present = WAIT_FOR_EOF, Q_next = WAIT_FOR_EOF;
	
	// Register for assembling ASCII from incoming data stream
	reg [7:0] ascii_in = 8'd0;
	
	// Counters
	reg [3:0] bit_counter = 4'd0; // Used for determining if a full frame has been received yet
	reg [8:0] msg_bit_length = 9'd0; // Used for keeping track of message length (Needed for preprocessing w/o using multiplier)
	reg [5:0] frame_counter = 6'd0; // Used for tracking if we've reached the maximum input characters for current chunk
	
	always @ (posedge Clk, negedge Reset)
		begin
			if (!Reset)
				begin
					ascii_in <= 8'd0; // Clear the ascii shift register
					bit_counter <= 4'd0; // Clear the bit counter
					msg_bit_length <= 9'd0; // Clear the message length counter
					frame_counter <= 6'd0; // Clear the frame counter
					FramingError <= 1'b0; // Clear Framing Error flag
					ResetRcvd <= 1'b0; // Clear Reset Received flag
					ChunkReady <= 1'b0; // Clear Chunk Ready flag
					ChunkOut <= 512'd0; // Clear the hex shift register
					Q_present <= START_BIT_DETECT; // Wait for START bit
					Q_next <= START_BIT_DETECT;
				end
			else
				begin
					case (Q_present)
						// Wait for silence
						WAIT_FOR_EOF: begin
							if (Rx)
								begin
									if (bit_counter == 4'd8) // One frame's length of silence has passed
										begin
											Q_next <= START_BIT_DETECT; // Transition to listening for 
										end
									else
										begin
											bit_counter = bit_counter + 4'd1; // Increment bit counter
											Q_next <= WAIT_FOR_EOF;
										end
								end
							else // Otherwise... Data is still being transmitted
								begin
									bit_counter <= 4'd0; // Reset the bit counter
									Q_next <= WAIT_FOR_EOF;
								end
						end
						START_BIT_DETECT: begin
							if (!Rx) // START bit detected
								begin
									ascii_in <= 8'd0; // Clear the ascii shift register
									bit_counter <= 4'd0; // Clear the frame bit counter
									Q_next <= RECEIVE_BYTE;
								end
							else
								begin
									Q_next <= START_BIT_DETECT;
								end
						end
						RECEIVE_BYTE: begin // Receiving data in current frame
							if (bit_counter == 3'd7)
								begin
									ascii_in = ascii_in >> 1; // Shift everything right by 1
									ascii_in[7] <= Rx; // Shift in next bit
									Q_next <= STOP_BIT_DETECT;
								end
							else
								begin
									ascii_in = ascii_in >> 1; // Shift everything right by 1
									ascii_in[7] <= Rx; // Shift in next bit
									bit_counter = bit_counter + 4'd1;
									Q_next <= RECEIVE_BYTE;
								end
						end
						STOP_BIT_DETECT: begin // Look for STOP bit
							if (!Rx) // 10th bit of frame is LOW... something is wrong
								begin
									Q_next <= FRAMING_ERROR; // Throw framing error
								end
							else if ((ascii_in == (8'b01110010)) || (ascii_in == (8'b01010010))) // Reset character detected ('r' or 'R')
								begin
									Q_next <= RESET_DETECTED;
								end
							else if (ChunkReady) // If we haven't detected a control input and the chunk is already complete...
								begin
									Q_next <= START_BIT_DETECT; // Ignore input and go back to listening for input
								end
							else // Otherwise... we are looking for chunk input
								begin
									if (ascii_in == (8'b00001101)) // Carriage return character detected
										begin
											ChunkOut = ChunkOut << 8; // Shift chunk register 8 bits to the left
											ChunkOut[7:0] = 8'h80; // Append 0x80 (part of preprocessing for SHA256)
											Q_next <= CR_DETECTED;
										end
									else if (!ChunkReady & (frame_counter == 6'd55)) // Max-length chunk detected
										begin
											ChunkOut = ChunkOut << 80; // Shift chunk register 80 bits to the left
											ChunkOut[79:0] <= {ascii_in, 8'h80, 55'd0, (msg_bit_length + 9'd8)}; // Insert last hex value, 0x80, and length (part of preprocessing for SHA256) into the register
											Q_next <= CHUNK_READY;
										end
									else if (!ChunkReady) // Wait for next frame
										begin
											ChunkOut = ChunkOut << 8; // Shift chunk register 8 bits to the left
											ChunkOut[7:0] <= ascii_in; // Insert next ascii value into the register
											msg_bit_length <= msg_bit_length + 9'd8; // Increment msg length in bits
											frame_counter = frame_counter + 6'd1;
											Q_next <= START_BIT_DETECT;
										end
								end
						end
						FRAMING_ERROR: begin // Framing error detected
							FramingError <= 1'b1; // Set Framing Error flag
							bit_counter <= 4'd0; // Clear the bit counter
							Q_next <= WAIT_FOR_EOF; // Realign receiver
						end
						RESET_DETECTED: begin
							ResetRcvd <= 1'b1; // Set Reset Received flag
							Q_next <= RESET_DETECTED;
						end
						CR_DETECTED: begin
							if (frame_counter == 6'd55) // Everything has been shifted over enough. Chunk is ready
								begin
									ChunkOut <= ChunkOut << 64; // Shift everything 64 bits to insert length
									ChunkOut[63:0] <= {55'd0, msg_bit_length}; // Append length of message to the end of chunk
									Q_next <= CHUNK_READY;
								end
							else
								begin // Not done shifting everything over
									ChunkOut = ChunkOut << 8; // Shift chunk register 8 bits to the left to pad the chunk
									frame_counter <= frame_counter + 6'd1;
									Q_next <= CR_DETECTED;
								end
						end
						CHUNK_READY: begin
							ChunkReady <= 1'b1; // Set Chunk Ready flag
							Q_next <= START_BIT_DETECT; // Go back to listening for control inputs
						end
					endcase
				end
				Q_present <= Q_next; // Transition to next state
		end
endmodule 
// © 2017 Maxey-Vesperman, Butler