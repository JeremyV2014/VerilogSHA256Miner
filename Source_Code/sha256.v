/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    sha256.v
    Purpose: SHA256 hashing algorithm control unit
    Input: Clk - System Clock input; Reset - Asynchrounous reset; Start - Control input for starting hashing rounds;
			  Chunk - User input data
	 Output: Digest - 256-bit hashed output; DigestReady - Flag to indicate that hashing is complete;
				
				WOut - Current calculated W value (For testing purposes)
				CurrentHash - Current round output (For testing purposes)
*/

module sha256 (Clk, Reset, Start, Chunk, Digest, DigestReady, WOut, CurrentHash);
	// Initial round constants (defined by SHA256 standard)
	parameter	SHA256_A0	=	32'h6a09e667;
	parameter	SHA256_B0	=	32'hbb67ae85;
	parameter	SHA256_C0 	=	32'h3c6ef372;
	parameter	SHA256_D0 	=	32'ha54ff53a;
	parameter	SHA256_E0 	=	32'h510e527f;
	parameter	SHA256_F0 	=	32'h9b05688c;
	parameter	SHA256_G0 	=	32'h1f83d9ab;
	parameter	SHA256_H0 	=	32'h5be0cd19;
	
	// States
	parameter	DISABLED			=	2'b00,
					HASHING			=	2'b01,
					DIGEST_READY	=	2'b10;
					
	// I/O
	input Clk, Reset, Start;
	input [511:0] Chunk;
	output reg DigestReady = 1'b0;
	output reg [255:0] Digest = 256'b0;
	
	// State registers
	reg [1:0] Q_present = DISABLED, Q_next = DISABLED;
	
	reg [31:0]	a_in = SHA256_A0, // Input to hashing round
					b_in = SHA256_B0, 
					c_in = SHA256_C0, 
					d_in = SHA256_D0, 
					e_in = SHA256_E0, 
					f_in = SHA256_F0, 
					g_in = SHA256_G0, 
					h_in = SHA256_H0;
	
	wire [31:0]	a_out, // Output from hashing round
					b_out,
					c_out,
					d_out,
					e_out,
					f_out,
					g_out,
					h_out;
	
	reg [5:0] round = 6'd0; // Counter for tracking how many rounds have been performed
	
	reg [15:0] [31:0] w_array = {16{32'd0}}; // Array of registers for tracking w (needed because W is determined from W of the past 16 rounds)
	
	wire [31:0] k, w; // interconnects for K constant and W input for hashing algorithm
	
	output [31:0] WOut; assign WOut = w; // For testing purposes
	output [255:0] CurrentHash; assign CurrentHash = {a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out}; // For testing purposes
	
	// Instantiate K constant RAM module, W calculation module, and SHA256 hashing algorithm module with appropriate connections
	k_constants(round, k);
	calc_w (Clk, round, w_array, w);
	hash_algorithm(Clk, w, k, a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in, a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out);
	
	// Update round input from round output on the falling edge
	always @ (negedge Clk, negedge Reset)
		begin
			// Reset round words to initial constants
			if (!Reset)
				begin
					a_in <= SHA256_A0;
					b_in <= SHA256_B0; 
					c_in <= SHA256_C0; 
					d_in <= SHA256_D0; 
					e_in <= SHA256_E0; 
					f_in <= SHA256_F0; 
					g_in <= SHA256_G0; 
					h_in <= SHA256_H0;
				end
			else if ((Q_present == HASHING) && (round != 0))
				begin
					a_in <= a_out;
					b_in <= b_out;
					c_in <= c_out;
					d_in <= d_out;
					e_in <= e_out;
					f_in <= f_out;
					g_in <= g_out;
					h_in <= h_out;
				end
		end
	
	always @ (posedge Clk, negedge Reset)
		begin
			if (!Reset)
				begin // Clear all registers and transition to disabled state
					round <= 6'd0;
					
					w_array <= {16{32'd0}};
					
					Digest <= 256'd0;
					DigestReady <= 1'b0;
					
					Q_present <= DISABLED;
					Q_next <= DISABLED;
				end
			else
				begin
					case (Q_present)
						DISABLED : begin
							// Load preprocessed chunk data into the message schedule array
							if (Start)
								begin
									w_array[0] <= Chunk[511:480];
									w_array[1] <= Chunk[479:448];
									w_array[2] <= Chunk[447:416];
									w_array[3] <= Chunk[415:384];
									w_array[4] <= Chunk[383:352];
									w_array[5] <= Chunk[351:320];
									w_array[6] <= Chunk[319:288];
									w_array[7] <= Chunk[287:256];
									w_array[8] <= Chunk[255:224];
									w_array[9] <= Chunk[223:192];
									w_array[10] <= Chunk[191:160];
									w_array[11] <= Chunk[159:128];
									w_array[12] <= Chunk[127:96];
									w_array[13] <= Chunk[95:64];
									w_array[14] <= Chunk[63:32];
									w_array[15] <= Chunk[31:0];
									Q_next <= HASHING;
								end
							else
								begin
									Q_next <= DISABLED;
								end
						end
						HASHING : begin
							if (round == 6'd63) // Final round completed
								begin									
									Q_next <= DIGEST_READY;
								end
							else
								begin						
									round <= round + 6'd1; // increment round counter
									
									if (round > 15) // User input has gone into hashing algorithm... begin calculating new w values
										begin
											w_array = w_array >> 32; // Shift out the oldest w value
											w_array[15] = w; // Shift in the latest calculated w value
										end
										
									Q_next <= HASHING;
								end
						end
						DIGEST_READY : begin // Hashing complete. Calculate intermediate hash by summing the output words with initial round constants and concatenate into one digest register
							Digest <= {(a_out + SHA256_A0), (b_out + SHA256_B0), (c_out + SHA256_C0), (d_out + SHA256_D0), (e_out + SHA256_E0), (f_out + SHA256_F0), (g_out + SHA256_G0), (h_out + SHA256_H0)}; // Put together the digest with post-pricessing
							DigestReady <= 1'b1; // Assert Digest Ready flag
							
							Q_next <= DIGEST_READY; // Stay in this state until reset
						end
					endcase
				end
			Q_present <= Q_next; // Transition to next state
		end
endmodule
// © 2017 Maxey-Vesperman, Butler