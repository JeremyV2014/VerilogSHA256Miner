/*
    2017-12-15
	Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    hash_algorithm.v
    Purpose: Performs round of SHA256 hashing on input data
    Input: Clk - System Clock input; Win - Message schedule array data (32-bit Word of user input data);
			  Kin - Round constant (defined by SHA256 standard); Ain-Hin - 32-bit Words from previous round;
	 Output: Aout-Hout - Output from current hashing round
*/

module hash_algorithm (Clk, Win, Kin, Ain, Bin, Cin, Din, Ein, Fin, Gin, Hin, Aout, Bout, Cout, Dout, Eout, Fout, Gout, Hout);
		// I/O
		input Clk;
		input [31:0] Win, Kin, Ain, Bin, Cin, Din, Ein, Fin, Gin, Hin;
		output reg [31:0] Aout, Bout, Cout, Dout, Eout, Fout, Gout, Hout;
		
		// Combinational logic interconnects for hashing algorithm compression functions
		wire [31:0] ch_out;
		wire [31:0] E1_out;
		wire [31:0] ma_out;
		wire [31:0] E0_out;
		
		// Combinational logic interconnects for 32-bit adders (Carry out bits are thrown away)
		wire [31:0] add_d; // D + (E1 + ((w + k) + H + Ch))
		wire [31:0] add_step_1; // w + k
		wire [31:0] add_step_2; // (w + k) + H + Ch
		wire [31:0] add_step_3; // E1 + ((w + k) + H + Ch)
		wire [31:0] add_step_4; // Ma + (E1 + ((w + k) + H + Ch))
		wire [31:0] add_step_5; // E0 + (Ma + (E1 + ((w + k) + H + Ch)))
		
		// 32-bit adders for hashing algorithm
		assign add_step_1 = Win + Kin; // w + k
		assign add_step_2 = add_step_1 + Hin + ch_out; // (w + k) + H + Ch
		assign add_step_3 = add_step_2 + E1_out; // E1 + ((w + k) + H + Ch)
		assign add_d = add_step_3 + Din; // D + (E1 + ((w + k) + H + Ch))
		assign add_step_4 = add_step_3 + ma_out; // Ma + (E1 + ((w + k) + H + Ch))
		assign add_step_5 = add_step_4 + E0_out; // E0 + (Ma + (E1 + ((w + k) + H + Ch)))
		
		// Instantiate compression function modules with appropriate I/O connections
		choose_function ch (Ein, Fin, Gin, ch_out);
		E1_function E1 (Ein, E1_out);
		majority_function ma (Ain, Bin, Cin, ma_out);
		E0_function E0 (Ain, E0_out);
		
		always @ (posedge Clk)
			begin
				Aout <= add_step_5; // E0 + (Ma + (E1 + ((w + k) + H + Ch)))
				Bout <= Ain; // A becomes B
				Cout <= Bin; // B becomes C
				Dout <= Cin; // C becomes D
				Eout <= add_d; // D + (E1 + ((w + k) + H + Ch))
				Fout <= Ein; // E becomes F
				Gout <= Fin; // F becomes G
				Hout <= Gin; // G becomes H
			end
endmodule

// Bitwise majority function (Array of 32 3-input, 2-bit adders)
module majority_function (A, B, C, MaOut);
	// I/O
	input [31:0] A, B, C;
	output [31:0] MaOut;
	
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)
			begin : Bitwise_Majority
				ma_1_bit ma (A[i], B[i], C[i], MaOut[i]);
			end
	endgenerate
endmodule 

// 3-input 1-bit adders module for majority function (Really its a 2-bit adder with 1-bit output... I didn't know how to name that)
module ma_1_bit (A, B, C, MaOut);
	// I/O
	input A, B, C;
	output MaOut;
	
	wire[1:0] sum;
	
	assign sum = (A + B + C); // Sum the bits
	assign MaOut = sum[1]; // Upper bit determines if there was a majority (2 or more inputs were 1)
endmodule 

// A input word Rotation and XOR function
module E0_function (A, E0Out);
	input [31:0] A;
	output [31:0] E0Out;
	
	// Interconnects
	wire [31:0] rr_2;
	wire [31:0] rr_13;
	wire [31:0] rr_22;
	
	// Create three rotated versions of input A
	assign rr_2 = {A[1:0], A[31:2]}; // RR A 2 bits
	assign rr_13 = {A[12:0], A[31:13]}; // RR A 13 bits
	assign rr_22 = {A[21:0], A[31:22]}; // RR A 22 bits
	
	// Bitwise XOR the rotated versions together
	assign E0Out = (rr_2 ^ rr_13 ^ rr_22);
endmodule

// E input word Rotation and XOR function
module E1_function (E, E1Out);
	// I/O
	input [31:0] E;
	output [31:0] E1Out;
	
	// Interconnects
	wire [31:0] rr_6;
	wire [31:0] rr_11;
	wire [31:0] rr_25;
	
	// Create three rotated versions of input E
	assign rr_6 = {E[5:0], E[31:6]}; // RR E 6 bits
	assign rr_11 = {E[10:0], E[31:11]}; // RR E 11 bits
	assign rr_25 = {E[24:0], E[31:25]}; // RR E 25 bits
	
	// Bitwise XOR the rotated versions together
	assign E1Out = (rr_6 ^ rr_11 ^ rr_25);
endmodule

// Bitwise Choose function (Array of 32 2:1 muxes (Inputs: F, G; Select: E))
module choose_function (E, F, G, ChOut);
	// I/O
	input [31:0] E, F, G;
	output [31:0] ChOut;
	
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)
			begin : Bitwise_Mux
				mux_1_bit m (E[i], {F[i], G[i]}, ChOut[i]);
			end
	endgenerate
endmodule 

// 2:1 mux module for Bitwise Choose function
module mux_1_bit (s, in, out);
	// I/O
	input s;
	input [1:0] in;
	output out;
	
	assign out = in[s];
endmodule 
// © 2017 Maxey-Vesperman, Butler