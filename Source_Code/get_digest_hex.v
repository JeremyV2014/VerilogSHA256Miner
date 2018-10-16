/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    get_digest_hex.v
    Purpose: Retrieves next hex value from digest register for transmission
    Input: Clk - System Clock input; Reset - Asynchronous Reset; En - Enable/Disable control
			  DigestReg - 256-bit digest register
	 Output: HexOut - Hex value retrieved from digest register; HexAvailble - Hex value is available flag;
				EndOfDigest - Flag to indicate that this is the last hex value from digest
*/

module get_digest_hex(Clk, Reset, En, DigestReg, HexOut, HexAvailable, EndOfDigest);
	// I/O
	input Clk, Reset, En;
	input [255:0] DigestReg;
	output reg HexAvailable, EndOfDigest;
	output reg [3:0] HexOut;
	
	// Index register - Starts at Most Significant Word
	reg [5:0] idx = 6'd63; // 64 iterations to get all of digest
	
	always @ (posedge Clk, negedge Reset)
		begin
			if (!Reset)
				begin	
					EndOfDigest <= 1'b0;
					HexAvailable <= 1'b0;
					idx <= 6'd63;
				end
			else
				begin
					if (!En)
						begin
							HexAvailable <= 1'b0;
						end
					else if (!HexAvailable && (idx == 0)) // We've reached the end!
						begin
							HexOut <= DigestReg[4*idx +: 4];
							HexAvailable <= 1'b1;
							EndOfDigest <= 1'b1;
						end
					else if (!HexAvailable)
						begin
							HexOut = DigestReg[4*idx +: 4];
							HexAvailable <= 1'b1;
							idx = idx - 1'b1;
						end
				end
		end
endmodule 
// © 2017 Maxey-Vesperman, Butler