// SPDX-License-Identifier: MIT
// Adapted from SCS teaching kit, Copyright (c) 2021 Ada Brzoza; see ../LICENSE.
`timescale 1ns / 1ps
// SCS four-cycle CPU. ISA_LAB2=0 matches lab1/cpu.py.
// ISA_LAB2=1: 0x3? ADD -> R1 and 0x5? MUL -> R1:R0.
module cpu #(
    parameter integer ISA_LAB2 = 0,
    parameter integer USE_CLK_ENABLE = 0
)(
    input wire clk,
    input wire reset_n,
    input wire clk_enable,
    output reg [3:0] mem_address,
    input wire [7:0] mem_data_r,
    output reg [7:0] mem_data_w,
    output reg mem_we,
    output wire [1:0] dbg_state,
    output wire [3:0] dbg_r0,
    output wire [3:0] dbg_r1,
    output wire [3:0] dbg_pc
);
    reg [1:0] state;
    reg [3:0] pc, r0, r1;
    reg [7:0] opcode;
    // Explicit widening avoids losing the upper half of the product.
    wire [7:0] product = {4'b0000, r0} * {4'b0000, r1};
    assign dbg_state = state;
    assign dbg_r0 = r0;
    assign dbg_r1 = r1;
    assign dbg_pc = pc;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= 0;
            pc <= 0;
            r0 <= 0;
            r1 <= 0;
            opcode <= 0;
            mem_address <= 0;
            mem_data_w <= 0;
            mem_we <= 0;
        end else begin
            // A write pulse lasts one MASTER clock, even while CPU is paused.
            // Memory port A is clocked on the opposite edge in toplevel.v.
            mem_we <= 0;
            if (!USE_CLK_ENABLE || clk_enable) begin
                case (state)
                    0: begin
                        mem_address <= pc;
                        state <= 1;
                    end
                    1: begin
                        opcode <= mem_data_r;
                        pc <= pc + 4'd1;
                        state <= 2;
                    end
                    2: begin
                        state <= 3;
                        case (opcode[7:4])
                            4'h0: pc <= opcode[3:0];
                            4'h2: r0 <= r0 + r1;
                            4'h3: begin
                                if (ISA_LAB2) r1 <= r0 + r1;
                                else begin
                                    r0 <= product[3:0];
                                    r1 <= product[7:4];
                                end
                            end
                            4'h4: r0 <= r0 - r1;
                            4'h5: if (ISA_LAB2) begin
                                r0 <= product[3:0];
                                r1 <= product[7:4];
                            end
                            4'h8: r0 <= opcode[3:0];
                            4'h9: r1 <= opcode[3:0];
                            4'hA: r0 <= r1;
                            4'hB: r1 <= r0;
                            4'hC, 4'hD: mem_address <= opcode[3:0];
                            4'hE: begin
                                mem_address <= opcode[3:0];
                                mem_data_w <= {4'b0000, r0};
                            end
                            4'hF: begin
                                mem_address <= opcode[3:0];
                                mem_data_w <= {4'b0000, r1};
                            end
                            default: begin end // Undefined: no architectural effect.
                        endcase
                    end
                    3: begin
                        state <= 0;
                        case (opcode[7:4])
                            4'hC: r0 <= mem_data_r[3:0];
                            4'hD: r1 <= mem_data_r[3:0];
                            4'hE, 4'hF: mem_we <= 1;
                            default: begin end
                        endcase
                    end
                endcase
            end
        end
    end
endmodule
