/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    uart_tx.v
    Purpose: UART Transmitter Control Unit
    Input: Clk - System Clock input; Reset - Asynchronous Reset; DigestReady - Enable/Disable control
			  Digest - 256-bit digest value
	 Output: TxOut - UART Transmission line; TxDone - Flag to indicate that transmission is complete
*/

module uart_tx (Clk, Reset, DigestReady, Digest, TxOut, TxDone);
	// States
	parameter	WAIT_FOR_DIGEST	=	4'b0000,	// Wait for digest to be calculated
					GET_NEXT_DIGEST	=	4'b0001,	// Access next hex value in the digest register
					GET_ASCII			=	4'b0010,	// Convert Hex to ASCII value
					LOAD_TX_SR			=	4'b0011,	// Load the ASCII value into the shift register
					TX_SHIFT_OUT		=	4'b0100,	// Shift out everything in register
					TX_SR_EMPTY			=	4'b0101,	// Shift register is empty
					TX_CR					=	4'b0110,	// Send Carriage Return
					TX_LF					=	4'b0111,	// Send Line Feed
					TX_COMPLETE			=	4'b1000;	// Transmission is complete
	
	// I/O
	input Clk, Reset, DigestReady;
	input [255:0] Digest;
	output TxOut;
	output reg TxDone;
	
	// Reset control for baud rate
	reg reset_brg = 1'b0;
	
	// State registers
	reg [3:0] Q_present, Q_next;
	
	// Control signals
	reg next_hex, next_ascii, send_cr, send_lf, load_sr, brg_en;
	
	// Flag signals
	wire hex_available, ascii_available, cr_sent, lf_sent, sr_empty, last_hex;
	
	// Baud rate clock
	wire baud_rate;
	
	// Data interconnects
	wire [3:0] hex_data;
	wire [7:0] ascii_data;
	
	// Instantiate modules with appropriate interconnects
	clock_50MHz_to_9600_baud brg (Clk, reset_brg, brg_en, baud_rate);
	get_digest_hex gdh (Clk, Reset, next_hex, Digest, hex_data, hex_available, last_hex);
	hex_to_ASCII hta (Clk, Reset, next_ascii, send_cr, send_lf, hex_data, ascii_data, ascii_available, cr_sent, lf_sent);
	tx_shiftr_reg_n sr (baud_rate, Reset, load_sr, ascii_data, TxOut, sr_empty);
	
	always @ (posedge Clk, negedge Reset)
		begin
			if (!Reset)
				begin 
					Q_present <= WAIT_FOR_DIGEST;
					next_hex <= 0;
					next_ascii <= 0;
					send_cr <= 0;
					send_lf <= 0;
					load_sr <= 0;
					brg_en <= 0;
					TxDone <= 0;
				end
			else
				begin
					case (Q_present)
						WAIT_FOR_DIGEST: begin
							TxDone <= 0;
							reset_brg <= 1'b0;
						end
						GET_NEXT_DIGEST: begin
							next_hex <= 1;
						end
						GET_ASCII: begin
							next_hex <= 0;
							next_ascii <= 1;
						end
						LOAD_TX_SR: begin
							next_ascii <= 0;
							load_sr <= 1;
							reset_brg <= 1'b1;
						end
						TX_SHIFT_OUT: begin
							load_sr <= 0;
							brg_en <= 1;
						end
						TX_SR_EMPTY: begin
							brg_en <= 0;
						end
						TX_CR: begin
							send_cr <= 1;
						end
						TX_LF: begin
							send_lf <= 1;
						end
						TX_COMPLETE: begin
							send_cr <= 0;
							send_lf <= 0;
							TxDone <= 1;
						end
					endcase
					Q_present <= Q_next;
				end
		end

	// Don't ask me what made me think I should do it this way...
	// Too tired to combine this with the other always block... it works...
	always @ (Reset, Q_present)
		begin
			if (!Reset)
				begin
					Q_next = WAIT_FOR_DIGEST;
				end
			else
				begin
					// Determine Next State
					case (Q_present)
						WAIT_FOR_DIGEST: begin // Wait
							if (DigestReady)
								begin
									Q_next = GET_NEXT_DIGEST;
								end
							else
								begin
									Q_next = WAIT_FOR_DIGEST;
								end
						end
						GET_NEXT_DIGEST:	begin // Get HEX
							if (hex_available)
								begin
									Q_next = GET_ASCII;
								end
							else
								begin
									Q_next = GET_NEXT_DIGEST;
								end
						end
						GET_ASCII: begin // Get ASCII
							if (ascii_available)
								begin
									Q_next = LOAD_TX_SR;
								end
							else
								begin
									Q_next = GET_ASCII;
								end
						end
						LOAD_TX_SR: begin // Load SR
							if (!sr_empty)
								begin
									Q_next = TX_SHIFT_OUT;
								end
							else
								begin
									Q_next = LOAD_TX_SR;
								end
						end
						TX_SHIFT_OUT: begin // Shift Out
							if (sr_empty)
								begin
									Q_next = TX_SR_EMPTY;
								end
							else
								begin
									Q_next = TX_SHIFT_OUT;
								end
						end
						TX_SR_EMPTY: begin // SR Empty
							if (last_hex)
								begin
									Q_next = TX_CR;
								end
							else
								begin
									Q_next = GET_NEXT_DIGEST;
								end
						end
						TX_CR: begin // Send Carriage Return
							if (cr_sent)
								begin
									Q_next <= TX_LF;
								end
							else
								begin
									Q_next <= GET_ASCII;
								end
						end
						TX_LF: begin // Send Line Feed
							if (lf_sent)
								begin
									Q_next <= TX_COMPLETE;
								end
							else
								begin
									Q_next <= GET_ASCII;
								end
						end
						TX_COMPLETE: begin // TX complete
							Q_next = TX_COMPLETE;
						end
					endcase
				end
		end
	
endmodule 
// © 2017 Maxey-Vesperman, Butler