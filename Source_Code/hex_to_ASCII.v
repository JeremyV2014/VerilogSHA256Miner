/*
    2017-12-15
    Jeremy Maxey-Vesperman
    Zach Butler
    CE-412 Digital Systems II
    Professor Girma Tewolde, Ph.D.
    Final Project - SHA256 Hasher w/ UART I/O Implemented on an FPGA
    hex_to_ASCII.v
    Purpose: Converts hex value into ASCII for transmission via UART
    Input: Clk - System Clock input; Reset - Asynchronous Reset; En - Enable/Disable control
			  SendCR - Control signal to generate Carriage Return; SendLF - Control signal to generate Line Feed;
			  HexIn - Input hex value that needs conversion
	 Output: ASCIIOut - ASCII output; ASCIIAvailable - Flag to indicate ASCII value is available for transmission;
				CRSent - Flag to indicate that Carriage Return ASCII has been generated;
				LFSent - Flag to indicate that Line Feed ASCII has been generated
*/

module hex_to_ASCII(Clk, Reset, En, SendCR, SendLF, HexIn, ASCIIOut, ASCIIAvailable, CRSent, LFSent);
	// I/O
	input Clk, Reset, En, SendCR, SendLF;
	input [3:0] HexIn; // Hexadecimal input value
	output reg ASCIIAvailable, CRSent, LFSent;
	output reg [7:0] ASCIIOut; // ASCII representation output
	
	always @ (posedge Clk, negedge Reset)
		begin
			if (!Reset)
				begin
					ASCIIOut <= 8'b0;
					ASCIIAvailable <= 1'b0;
					CRSent <= 1'b0;
					LFSent <= 1'b0;
				end
			else
				begin
					if (!En)
						begin
							ASCIIAvailable <= 1'b0;
						end
					else if (SendLF)
					begin
						ASCIIOut <= 8'd10; // Line Feed Character
						ASCIIAvailable <= 1'b1;
						LFSent <= 1'b1;
					end
					else if (SendCR)
						begin
							ASCIIOut <= 8'd13; // Carriage Return Character
							ASCIIAvailable <= 1'b1;
							CRSent <= 1'b1;
						end
					else if (HexIn > 9)
						begin
							ASCIIOut <= (HexIn + 8'd87); // Lowercase letter
							ASCIIAvailable <= 1'b1;
						end
					else
						begin
							ASCIIOut <= (HexIn + 8'd48); // Numeral
							ASCIIAvailable <= 1'b1;
						end
				end
		end
endmodule 
// © 2017 Maxey-Vesperman, Butler