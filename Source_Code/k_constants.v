/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    k_constants.v
    Purpose: SHA256 K constants RAM module
    Input: Addr - Asynchronous address input to RAM module;
	 Output: K - Selected K constant value
*/

module k_constants (Addr, K);
	// I/O
	input [5:0] Addr;
	output [31:0] K;
	
	reg [31:0] current_k;
	assign K = current_k;

	always @ (Addr)
		begin : addr_mux
			case(Addr)
			  00: current_k = 32'h428a2f98;
			  01: current_k = 32'h71374491;
			  02: current_k = 32'hb5c0fbcf;
			  03: current_k = 32'he9b5dba5;
			  04: current_k = 32'h3956c25b;
			  05: current_k = 32'h59f111f1;
			  06: current_k = 32'h923f82a4;
			  07: current_k = 32'hab1c5ed5;
			  08: current_k = 32'hd807aa98;
			  09: current_k = 32'h12835b01;
			  10: current_k = 32'h243185be;
			  11: current_k = 32'h550c7dc3;
			  12: current_k = 32'h72be5d74;
			  13: current_k = 32'h80deb1fe;
			  14: current_k = 32'h9bdc06a7;
			  15: current_k = 32'hc19bf174;
			  16: current_k = 32'he49b69c1;
			  17: current_k = 32'hefbe4786;
			  18: current_k = 32'h0fc19dc6;
			  19: current_k = 32'h240ca1cc;
			  20: current_k = 32'h2de92c6f;
			  21: current_k = 32'h4a7484aa;
			  22: current_k = 32'h5cb0a9dc;
			  23: current_k = 32'h76f988da;
			  24: current_k = 32'h983e5152;
			  25: current_k = 32'ha831c66d;
			  26: current_k = 32'hb00327c8;
			  27: current_k = 32'hbf597fc7;
			  28: current_k = 32'hc6e00bf3;
			  29: current_k = 32'hd5a79147;
			  30: current_k = 32'h06ca6351;
			  31: current_k = 32'h14292967;
			  32: current_k = 32'h27b70a85;
			  33: current_k = 32'h2e1b2138;
			  34: current_k = 32'h4d2c6dfc;
			  35: current_k = 32'h53380d13;
			  36: current_k = 32'h650a7354;
			  37: current_k = 32'h766a0abb;
			  38: current_k = 32'h81c2c92e;
			  39: current_k = 32'h92722c85;
			  40: current_k = 32'ha2bfe8a1;
			  41: current_k = 32'ha81a664b;
			  42: current_k = 32'hc24b8b70;
			  43: current_k = 32'hc76c51a3;
			  44: current_k = 32'hd192e819;
			  45: current_k = 32'hd6990624;
			  46: current_k = 32'hf40e3585;
			  47: current_k = 32'h106aa070;
			  48: current_k = 32'h19a4c116;
			  49: current_k = 32'h1e376c08;
			  50: current_k = 32'h2748774c;
			  51: current_k = 32'h34b0bcb5;
			  52: current_k = 32'h391c0cb3;
			  53: current_k = 32'h4ed8aa4a;
			  54: current_k = 32'h5b9cca4f;
			  55: current_k = 32'h682e6ff3;
			  56: current_k = 32'h748f82ee;
			  57: current_k = 32'h78a5636f;
			  58: current_k = 32'h84c87814;
			  59: current_k = 32'h8cc70208;
			  60: current_k = 32'h90befffa;
			  61: current_k = 32'ha4506ceb;
			  62: current_k = 32'hbef9a3f7;
			  63: current_k = 32'hc67178f2;
			endcase
		end
endmodule 
// © 2017 Maxey-Vesperman, Butler