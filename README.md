# Verilog SHA256 Miner

<b>Summary</b>: Verilog SHA256 Miner is a final project completed for my Digital Systems II class at Kettering University. It is a Verilog implementation of the SHA256 hashing algorithm with UART Transceiver. The device is able to take in any string input via UART and return the generated hash also via UART. This project was designed with the eventual goal of developing a rudimentary (and impractical) Bitcoin miner on Altera's DE2 FPGA development board. Essentially, an intermediary computer would provide the input to the hasher as well as the difficulty so that the FPGA could run until it either found a valid output or the computer provided new input.

<b>Contributors</b>: Jeremy Maxey-Vesperman, Zach Butler, Dr. Girma Tewolde
