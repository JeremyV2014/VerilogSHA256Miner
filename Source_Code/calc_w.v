/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    calc_w.v
    Purpose: Module for W calculation logic
    Input: Clk - System Clock input; Round - Current hashing round;
			  WArray - W input array from previous 16 rounds
	 Output: WOut - Calculated W input value
*/

module calc_w (Clk, Round, WArray, WOut);
	input Clk;
	input [5:0] Round;
	input [15:0] [31:0] WArray;
	output reg [31:0] WOut = 32'hFF;
	
	// Rotated / Right-Shifted verisions of W from 15th last and 2nd last round
	reg [31:0]	I = 32'd0,
					J = 32'd0,
					K = 32'd0,
					P = 32'd0,
					Q = 32'd0,
					R = 32'd0,
					S0 = 32'd0, // XOR'ed w from 15th last round
					S1 = 32'd0; // XOR'ed w from 2nd last round
	
	always @ (negedge Clk) // Update w on the negative clock edge
		begin
			if (Round < 16) // Not enough rounds have passed to calculate W yet...
				begin
					WOut <= WArray[Round]; // Round input is preprocessed user input data
				end
			else
				begin
					I = {WArray[1][6:0], WArray[1][31:7]}; // RR7
					J = {WArray[1][17:0], WArray[1][31:18]}; // RR18
					K = WArray[1] >> 3; // SR 3
					P = {WArray[14][16:0], WArray[14][31:17]}; // RR17
					Q = {WArray[14][18:0], WArray[14][31:19]}; // RR19
					R = WArray[14] >> 10; // SR 10
					S0 = (I ^ J ^ K);
					S1 = (P ^ Q ^ R);
					// Current w = last round w + Rotated, Shifted, XOR'ed 15th last round w +
					// 				9th round w + Rotated, Shifted, XOR'ed 2nd last round w
					WOut = (WArray[0] + S0 + WArray[9] + S1);
				end
		end
endmodule 
// © 2017 Maxey-Vesperman, Butler