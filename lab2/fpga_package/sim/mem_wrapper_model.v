`timescale 1ns / 1ps
// SIMULATION ONLY. Never add with the generated Block Design mem_wrapper.
module mem_wrapper (
    input wire [3:0] BRAM_PORTA_0_addr,
    input wire BRAM_PORTA_0_clk,
    input wire [7:0] BRAM_PORTA_0_din,
    output reg [7:0] BRAM_PORTA_0_dout,
    input wire BRAM_PORTA_0_we,
    input wire [3:0] BRAM_PORTB_0_addr,
    input wire BRAM_PORTB_0_clk,
    input wire [7:0] BRAM_PORTB_0_din,
    output reg [7:0] BRAM_PORTB_0_dout,
    input wire BRAM_PORTB_0_we
);
    reg [7:0] memory [0:15];
    integer i;
    initial begin
        for (i=0; i<16; i=i+1) memory[i]=0;
        // The required section 3.5 program; data RAM[13]=5.
        memory[0]=8'h80; memory[1]=8'h90; memory[2]=8'hee;
        memory[3]=8'h86; memory[4]=8'hdd; memory[5]=8'h20;
        memory[6]=8'hee; memory[7]=8'h00; memory[13]=8'h05;
    end
    always @(posedge BRAM_PORTA_0_clk) begin
        if (BRAM_PORTA_0_we) begin
            memory[BRAM_PORTA_0_addr] <= BRAM_PORTA_0_din;
            BRAM_PORTA_0_dout <= BRAM_PORTA_0_din;
        end else BRAM_PORTA_0_dout <= memory[BRAM_PORTA_0_addr];
    end
    always @(posedge BRAM_PORTB_0_clk)
        BRAM_PORTB_0_dout <= memory[BRAM_PORTB_0_addr];
endmodule
