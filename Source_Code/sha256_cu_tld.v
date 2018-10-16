/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    sha256_cu_tld.v
    Purpose: Hardware driver instantiating a SHA256 Hasher w/ UART I/O on the
             Altera DE2 board, Cyclone II EP 2C 35 F6 72 C6
    Input: CLOCK_50 - 50MHz clock; KEY[3] - Asynchronous Reset; UART_RXD - Chunk data
	 Output: UART_TXD - Digest; LEDR[0] - UART Framing Error Detected Indicator
				LEDG[0] - Chunk Received Indicator; LEDG[1] Digest Ready Indicator;
				LEDG[2] - Digest Transmitted Indicator
*/

module sha256_cu_tld (CLOCK_50, KEY, UART_RXD, UART_TXD, LEDR, LEDG);
	// I/O
	input CLOCK_50, UART_RXD;
	input [3:0] KEY;
	output UART_TXD;
	output [17:0] LEDR;
	output [8:0] LEDG;
	
	// Instantiate control module
	sha256_cu(CLOCK_50, KEY[3], UART_RXD, UART_TXD, LEDR[0], LEDG[0], LEDG[1], LEDG[2]);
endmodule 
// © 2017 Maxey-Vesperman, Butler