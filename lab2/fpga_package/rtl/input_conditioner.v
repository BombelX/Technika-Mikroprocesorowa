// SPDX-License-Identifier: MIT
// Adapted from SCS teaching kit, Copyright (c) 2021 Ada Brzoza; see ../LICENSE.
`timescale 1ns / 1ps
// Two-flop synchronizer followed by a stable-level debounce counter.
module input_conditioner #(
    parameter integer STABLE_CYCLES = 1250000
)(
    input wire clk,
    input wire reset_n,
    input wire in,
    output reg level,
    output reg rise
);
    (* ASYNC_REG = "TRUE" *) reg meta, synced;
    reg [31:0] stable_count;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            meta <= 0;
            synced <= 0;
            level <= 0;
            rise <= 0;
            stable_count <= 0;
        end else begin
            meta <= in;
            synced <= meta;
            rise <= 0;
            if (synced == level) stable_count <= 0;
            else if (stable_count >= STABLE_CYCLES - 1) begin
                level <= synced;
                rise <= synced;
                stable_count <= 0;
            end else stable_count <= stable_count + 1;
        end
    end
endmodule
