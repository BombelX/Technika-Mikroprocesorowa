// SPDX-License-Identifier: MIT
// Adapted from SCS teaching kit, Copyright (c) 2021 Ada Brzoza; see ../LICENSE.
`timescale 1ns / 1ps
// ZYBO (original Zynq-7010 board): all control/CPU/UART logic uses CLK_IN.
module toplevel #(
    parameter integer ISA_LAB2 = 0,
    parameter integer CLOCK_HZ = 125000000,
    parameter integer BAUD = 115200,
    parameter integer DEBOUNCE_CYCLES = CLOCK_HZ / 100,
    parameter integer STEP_PERIOD_CYCLES = CLOCK_HZ / 20
)(
    input wire CLK_IN,
    output wire [3:0] LD,
    input wire [3:0] SW,
    input wire [3:0] BTN,
    output wire [7:0] je
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_sync = 0;
    wire reset_n = reset_sync[1];
    always @(posedge CLK_IN or posedge BTN[0]) begin
        if (BTN[0]) reset_sync <= 0;
        else reset_sync <= {reset_sync[0], 1'b1};
    end
    (* ASYNC_REG = "TRUE" *) reg [3:0] sw_meta, sw_sync;
    always @(posedge CLK_IN or negedge reset_n) begin
        if (!reset_n) begin sw_meta <= 0; sw_sync <= 0; end
        else begin sw_meta <= SW; sw_sync <= sw_meta; end
    end
    wire btn1_level, btn1_rise, btn2_level, btn2_rise;
    input_conditioner #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) btn1 (
        .clk(CLK_IN), .reset_n(reset_n), .in(BTN[1]),
        .level(btn1_level), .rise(btn1_rise)
    );
    input_conditioner #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) btn2 (
        .clk(CLK_IN), .reset_n(reset_n), .in(BTN[2]),
        .level(btn2_level), .rise(btn2_rise)
    );
    reg [31:0] step_counter;
    reg [1:0] burst_remaining;
    reg [1:0] previous_mode;
    reg step_tick, step_led;
    always @(posedge CLK_IN or negedge reset_n) begin
        if (!reset_n) begin
            step_counter <= 0;
            burst_remaining <= 0;
            previous_mode <= 0;
            step_tick <= 0;
            step_led <= 0;
        end else begin
            previous_mode <= sw_sync[1:0];
            step_tick <= 0;
            if (step_tick) step_led <= ~step_led;
            if (previous_mode != sw_sync[1:0]) begin
                step_counter <= 0;
                burst_remaining <= 0;
            end else if (sw_sync[1]) begin
                if (step_counter >= CLOCK_HZ - 1) begin
                    step_counter <= 0;
                    step_tick <= 1;
                end else step_counter <= step_counter + 1;
            end else if (burst_remaining != 0) begin
                if (step_counter == 0) begin
                    step_tick <= 1;
                    burst_remaining <= burst_remaining - 1;
                    step_counter <= STEP_PERIOD_CYCLES - 1;
                end else step_counter <= step_counter - 1;
            end else if (btn2_rise) begin
                step_tick <= 1;
                if (!sw_sync[0]) begin
                    burst_remaining <= 3;
                    step_counter <= STEP_PERIOD_CYCLES - 1;
                end
            end
        end
    end

    wire [7:0] mem_port_a_rd, mem_port_a_wr, mem_port_b_rd;
    wire [3:0] mem_port_a_addr, mem_port_b_addr;
    wire mem_port_a_we;
    wire [1:0] dbg_state;
    wire [3:0] dbg_r0, dbg_r1, dbg_pc;
    // Port A runs continuously on falling master edges. The CPU's registered
    // address/data settle for half a period before each BRAM transaction.
    mem_wrapper mem1 (
        .BRAM_PORTA_0_addr(mem_port_a_addr),
        .BRAM_PORTA_0_clk(~CLK_IN),
        .BRAM_PORTA_0_din(mem_port_a_wr),
        .BRAM_PORTA_0_dout(mem_port_a_rd),
        .BRAM_PORTA_0_we(mem_port_a_we),
        .BRAM_PORTB_0_addr(mem_port_b_addr),
        .BRAM_PORTB_0_clk(CLK_IN),
        .BRAM_PORTB_0_din(8'b0),
        .BRAM_PORTB_0_dout(mem_port_b_rd),
        .BRAM_PORTB_0_we(1'b0)
    );
    cpu #(.ISA_LAB2(ISA_LAB2), .USE_CLK_ENABLE(1)) cpu1 (
        .clk(CLK_IN), .reset_n(reset_n), .clk_enable(step_tick),
        .mem_address(mem_port_a_addr), .mem_data_r(mem_port_a_rd),
        .mem_data_w(mem_port_a_wr), .mem_we(mem_port_a_we),
        .dbg_state(dbg_state), .dbg_r0(dbg_r0), .dbg_r1(dbg_r1), .dbg_pc(dbg_pc)
    );
    // Delay automatic dump until registers and the falling-edge STR settle.
    reg [1:0] dump_delay;
    always @(posedge CLK_IN or negedge reset_n) begin
        if (!reset_n) dump_delay <= 0;
        else dump_delay <= {dump_delay[0], step_tick};
    end
    wire dbg_busy, serial_out;
    wire dbg_trigger = sw_sync[2] ? dump_delay[1] : btn1_rise;
    dbgu #(.CLOCK_HZ(CLOCK_HZ), .BAUD(BAUD)) dbgu1 (
        .clk_in(CLK_IN), .clk_ser_in(1'b0), .reset_n(reset_n),
        .trig(dbg_trigger), .s_out(serial_out), .bsy(dbg_busy), .p_out(),
        .dbg_r0(dbg_r0), .dbg_r1(dbg_r1), .dbg_pc(dbg_pc),
        .dbg_istate({1'b0, dbg_state}), .dbg_mem_a(mem_port_a_addr),
        .dbg_mem_dr(mem_port_a_rd), .dbg_mem_dw(mem_port_a_wr),
        .mem_a(mem_port_b_addr), .mem_d(mem_port_b_rd), .mem_clk(),
        .uart_state(), .uart_buf(), .dbg_acntr()
    );
    assign je = {2'b00, serial_out, 5'b00000}; // JE[5], physical PMOD pin 8.
    assign LD = {ISA_LAB2 != 0, btn2_level, dbg_busy, step_led};
endmodule
