// SPDX-License-Identifier: MIT
// Adapted from SCS teaching kit, Copyright (c) 2021 Ada Brzoza; see ../LICENSE.
`timescale 1ns / 1ps
// One clock domain, 115200 baud by default, 8 data bits, no parity, 1 stop.
module uart_tx #(
    parameter integer CLOCK_HZ = 125000000,
    parameter integer BAUD = 115200
)(
    input wire clk,
    input wire reset_n,
    input wire start,
    input wire [7:0] data,
    output reg bsy,
    output reg txline
);
    localparam integer CLKS_PER_BIT = (CLOCK_HZ + BAUD / 2) / BAUD;
    reg [31:0] divider;
    reg [3:0] bit_index;
    reg [9:0] frame;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            bsy <= 0;
            txline <= 1;
            divider <= 0;
            bit_index <= 0;
            frame <= 10'h3ff;
        end else if (!bsy) begin
            txline <= 1;
            if (start) begin
                frame <= {1'b1, data, 1'b0};
                txline <= 0;
                divider <= CLKS_PER_BIT - 1;
                bit_index <= 0;
                bsy <= 1;
            end
        end else if (divider != 0) divider <= divider - 1;
        else if (bit_index == 9) begin
            bsy <= 0;
            txline <= 1;
        end else begin
            divider <= CLKS_PER_BIT - 1;
            bit_index <= bit_index + 1;
            frame <= {1'b1, frame[9:1]};
            txline <= frame[1];
        end
    end
endmodule
