// SPDX-License-Identifier: MIT
// Adapted from SCS teaching kit, Copyright (c) 2021 Ada Brzoza; see ../LICENSE.
`timescale 1ns / 1ps
// Snapshot debugger. Retains the teaching kit's data/memory interface.
// clk_in is now the 125 MHz master; clk_ser_in is retained but unused.
module dbgu #(
    parameter integer CLOCK_HZ = 125000000,
    parameter integer BAUD = 115200
)(
    input wire clk_in,
    input wire clk_ser_in,
    input wire reset_n,
    input wire trig,
    output wire s_out,
    output reg bsy,
    output reg [7:0] p_out,
    input wire [3:0] dbg_r0, dbg_r1, dbg_pc,
    input wire [2:0] dbg_istate,
    input wire [7:0] dbg_mem_dr, dbg_mem_dw,
    input wire [3:0] dbg_mem_a,
    output reg [3:0] mem_a,
    input wire [7:0] mem_d,
    output wire mem_clk,
    output wire [4:0] uart_state,
    output wire [7:0] uart_buf,
    output wire [2:0] dbg_acntr
);
    reg [3:0] snap_r0, snap_r1, snap_pc, snap_a;
    reg [2:0] snap_state;
    reg [7:0] snap_dr, snap_dw;
    reg [7:0] snapshot [0:15];
    reg [1:0] phase;
    reg scan_wait;
    reg [6:0] char_index;
    reg [1:0] tx_phase;
    reg tx_start;
    wire tx_busy;
    assign mem_clk = clk_in;
    assign uart_state = {3'b000, tx_phase};
    assign uart_buf = p_out;
    assign dbg_acntr = 0;

    function [7:0] hex_char;
        input [3:0] value;
        begin hex_char = value < 10 ? 8'h30 + value : 8'h41 + value - 10; end
    endfunction

    function [7:0] dump_char;
        input [6:0] index;
        integer cell_index;
        begin
            case (index)
                0: dump_char = 8'h0d;
                1: dump_char = 8'h0a;
                2: dump_char = "c";
                3: dump_char = "=";
                4: dump_char = hex_char({1'b0, snap_state});
                5: dump_char = " ";
                6: dump_char = "r";
                7: dump_char = "0";
                8: dump_char = "=";
                9: dump_char = hex_char(snap_r0);
                10: dump_char = " ";
                11: dump_char = "r";
                12: dump_char = "1";
                13: dump_char = "=";
                14: dump_char = hex_char(snap_r1);
                15: dump_char = " ";
                16: dump_char = "p";
                17: dump_char = "c";
                18: dump_char = "=";
                19: dump_char = hex_char(snap_pc);
                20: dump_char = " ";
                21: dump_char = "A";
                22: dump_char = "=";
                23: dump_char = hex_char(snap_a);
                24: dump_char = " ";
                25: dump_char = "R";
                26: dump_char = "=";
                27: dump_char = hex_char(snap_dr[7:4]);
                28: dump_char = hex_char(snap_dr[3:0]);
                29: dump_char = " ";
                30: dump_char = "W";
                31: dump_char = "=";
                32: dump_char = hex_char(snap_dw[7:4]);
                33: dump_char = hex_char(snap_dw[3:0]);
                34: dump_char = " ";
                35: dump_char = "M";
                36: dump_char = ":";
                37: dump_char = " ";
                default: begin
                    // Constant comparisons unroll at synthesis; no run-time
                    // integer divider/modulo circuit in the character path.
                    dump_char = " ";
                    for (cell_index = 0; cell_index < 16; cell_index = cell_index + 1) begin
                        if (index == 38 + 3*cell_index)
                            dump_char = hex_char(snapshot[cell_index][7:4]);
                        if (index == 39 + 3*cell_index)
                            dump_char = hex_char(snapshot[cell_index][3:0]);
                    end
                end
            endcase
        end
    endfunction

    uart_tx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(BAUD)) serial (
        .clk(clk_in), .reset_n(reset_n), .start(tx_start),
        .data(p_out), .bsy(tx_busy), .txline(s_out)
    );

    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            bsy <= 0;
            phase <= 0;
            mem_a <= 0;
            scan_wait <= 0;
            char_index <= 0;
            tx_phase <= 0;
            tx_start <= 0;
            p_out <= 0;
            snap_r0 <= 0; snap_r1 <= 0; snap_pc <= 0; snap_a <= 0;
            snap_state <= 0; snap_dr <= 0; snap_dw <= 0;
        end else begin
            tx_start <= 0;
            case (phase)
                0: if (trig) begin
                    bsy <= 1;
                    snap_r0 <= dbg_r0; snap_r1 <= dbg_r1; snap_pc <= dbg_pc;
                    snap_a <= dbg_mem_a; snap_state <= dbg_istate;
                    snap_dr <= dbg_mem_dr; snap_dw <= dbg_mem_dw;
                    mem_a <= 0;
                    scan_wait <= 0;
                    phase <= 1;
                end
                1: begin
                    // Two master cycles per address for synchronous port-B read.
                    if (!scan_wait) scan_wait <= 1;
                    else begin
                        snapshot[mem_a] <= mem_d;
                        scan_wait <= 0;
                        if (mem_a == 15) begin
                            phase <= 2;
                            char_index <= 0;
                            tx_phase <= 0;
                        end else mem_a <= mem_a + 1;
                    end
                end
                2: case (tx_phase)
                    0: begin
                        p_out <= dump_char(char_index);
                        tx_start <= 1;
                        tx_phase <= 1;
                    end
                    1: if (tx_busy) tx_phase <= 2;
                    2: if (!tx_busy) begin
                        if (char_index == 85) begin
                            bsy <= 0;
                            phase <= 0;
                        end else begin
                            char_index <= char_index + 1;
                            tx_phase <= 0;
                        end
                    end
                    default: tx_phase <= 0;
                endcase
                default: phase <= 0;
            endcase
        end
    end
endmodule
