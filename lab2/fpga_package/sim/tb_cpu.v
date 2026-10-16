`timescale 1ns / 1ps
// Exhaustive ISA regression: 256 opcodes x 16 R0 x 16 R1, both profiles.
// Independent reference state and memory are checked after every microcycle.
module tb_cpu;
    reg clk = 0, reset_n = 1, clk_enable = 0;
    wire [3:0] address [0:1];
    reg [7:0] read_data [0:1];
    wire [7:0] write_data [0:1];
    wire we [0:1];
    wire [1:0] state [0:1];
    wire [3:0] r0 [0:1], r1 [0:1], pc [0:1];
    reg [7:0] memory0 [0:15];
    reg [7:0] memory1 [0:15];
    reg [7:0] reference_memory [0:31];
    integer ref_state [0:1], ref_pc [0:1], ref_r0 [0:1], ref_r1 [0:1];
    integer ref_address [0:1], ref_write [0:1], ref_opcode [0:1], ref_we [0:1];
    integer tests = 0, microcycles = 0;
    integer opcode_test, a_test, b_test, p, i, n, value, op_hi, operand, product;

    cpu #(.ISA_LAB2(0), .USE_CLK_ENABLE(1)) python_isa (
        .clk(clk), .reset_n(reset_n), .clk_enable(clk_enable),
        .mem_address(address[0]), .mem_data_r(read_data[0]),
        .mem_data_w(write_data[0]), .mem_we(we[0]), .dbg_state(state[0]),
        .dbg_r0(r0[0]), .dbg_r1(r1[0]), .dbg_pc(pc[0])
    );
    cpu #(.ISA_LAB2(1), .USE_CLK_ENABLE(1)) lab2_isa (
        .clk(clk), .reset_n(reset_n), .clk_enable(clk_enable),
        .mem_address(address[1]), .mem_data_r(read_data[1]),
        .mem_data_w(write_data[1]), .mem_we(we[1]), .dbg_state(state[1]),
        .dbg_r0(r0[1]), .dbg_r1(r1[1]), .dbg_pc(pc[1])
    );
    // WRITE_FIRST, one-cycle synchronous RAM with no optional output register.
    always @(negedge clk) begin
        if (we[0]) begin
            memory0[address[0]] <= write_data[0];
            read_data[0] <= write_data[0];
        end else read_data[0] <= memory0[address[0]];
        if (we[1]) begin
            memory1[address[1]] <= write_data[1];
            read_data[1] <= write_data[1];
        end else read_data[1] <= memory1[address[1]];
    end

    task reset_case;
        begin
            reset_n = 0;
            clk_enable = 0;
            #1;
            for (p = 0; p < 2; p = p + 1) begin
                ref_state[p] = 0; ref_pc[p] = 0;
                ref_r0[p] = 0; ref_r1[p] = 0;
                ref_address[p] = 0; ref_write[p] = 0;
                ref_opcode[p] = 0; ref_we[p] = 0;
            end
            reset_n = 1;
        end
    endtask

    task reference_step;
        input integer profile;
        begin
            ref_we[profile] = 0;
            if (clk_enable) begin
                case (ref_state[profile])
                    0: ref_address[profile] = ref_pc[profile];
                    1: begin
                        ref_opcode[profile] = reference_memory[16*profile + ref_address[profile]];
                        ref_pc[profile] = (ref_pc[profile] + 1) & 15;
                    end
                    2: begin
                        op_hi = ref_opcode[profile] >> 4;
                        operand = ref_opcode[profile] & 15;
                        case (op_hi)
                            0: ref_pc[profile] = operand;
                            2: ref_r0[profile] = (ref_r0[profile] + ref_r1[profile]) & 15;
                            3: if (profile == 1)
                                ref_r1[profile] = (ref_r0[profile] + ref_r1[profile]) & 15;
                            else begin
                                product = ref_r0[profile] * ref_r1[profile];
                                ref_r0[profile] = product & 15;
                                ref_r1[profile] = (product >> 4) & 15;
                            end
                            4: ref_r0[profile] = (ref_r0[profile] - ref_r1[profile]) & 15;
                            5: if (profile == 1) begin
                                product = ref_r0[profile] * ref_r1[profile];
                                ref_r0[profile] = product & 15;
                                ref_r1[profile] = (product >> 4) & 15;
                            end
                            8: ref_r0[profile] = operand;
                            9: ref_r1[profile] = operand;
                            10: ref_r0[profile] = ref_r1[profile];
                            11: ref_r1[profile] = ref_r0[profile];
                            12, 13: ref_address[profile] = operand;
                            14: begin
                                ref_address[profile] = operand;
                                ref_write[profile] = ref_r0[profile];
                            end
                            15: begin
                                ref_address[profile] = operand;
                                ref_write[profile] = ref_r1[profile];
                            end
                        endcase
                    end
                    3: begin
                        case (ref_opcode[profile] >> 4)
                            12: ref_r0[profile] = reference_memory[16*profile + ref_address[profile]] & 15;
                            13: ref_r1[profile] = reference_memory[16*profile + ref_address[profile]] & 15;
                            14, 15: begin
                                reference_memory[16*profile + ref_address[profile]] = ref_write[profile];
                                ref_we[profile] = 1;
                            end
                        endcase
                    end
                endcase
                ref_state[profile] = (ref_state[profile] + 1) & 3;
            end
        end
    endtask

    task tick;
        input integer enabled;
        begin
            clk_enable = enabled;
            #4; clk = 1;
            reference_step(0);
            reference_step(1);
            #1;
            for (p = 0; p < 2; p = p + 1) begin
                if (state[p] !== ref_state[p][1:0] || pc[p] !== ref_pc[p][3:0] ||
                    r0[p] !== ref_r0[p][3:0] || r1[p] !== ref_r1[p][3:0] ||
                    address[p] !== ref_address[p][3:0] || write_data[p] !== ref_write[p][7:0] ||
                    we[p] !== ref_we[p][0]) begin
                    $display("FAIL profile=%0d op=%02x inputs=%x,%x cycle=%0d", p, opcode_test, a_test, b_test, microcycles);
                    $display("actual c=%x pc=%x r0=%x r1=%x A=%x W=%x we=%x", state[p],pc[p],r0[p],r1[p],address[p],write_data[p],we[p]);
                    $display("expect c=%x pc=%x r0=%x r1=%x A=%x W=%x we=%x", ref_state[p],ref_pc[p],ref_r0[p],ref_r1[p],ref_address[p],ref_write[p],ref_we[p]);
                    $fatal(1, "Architectural mismatch");
                end
            end
            #4; clk = 0; #1;
            for (i = 0; i < 16; i = i + 1)
                if (memory0[i] !== reference_memory[i] || memory1[i] !== reference_memory[16+i])
                    $fatal(1, "Memory mismatch address=%0d", i);
            microcycles = microcycles + 1;
        end
    endtask

    initial begin
        for (opcode_test = 0; opcode_test < 256; opcode_test = opcode_test + 1)
            for (a_test = 0; a_test < 16; a_test = a_test + 1)
                for (b_test = 0; b_test < 16; b_test = b_test + 1) begin
                    for (n = 0; n < 16; n = n + 1) begin
                        value = 16*n + ((15-n) & 15);
                        if (n == 0) value = 8'h80 + a_test;
                        if (n == 1) value = 8'h90 + b_test;
                        if (n == 2) value = opcode_test;
                        memory0[n] = value;
                        memory1[n] = value;
                        reference_memory[n] = value;
                        reference_memory[16+n] = value;
                    end
                    reset_case;
                    for (n = 0; n < 12; n = n + 1) begin
                        tick(1);
                        // Pauses exercise hold behavior and one-master write pulse.
                        tick(0);
                    end
                    tests = tests + 1;
                end
        // PC rollover is deliberately hardware-defined (Python lacks its mask).
        for (n = 0; n < 16; n = n + 1) begin
            memory0[n] = 8'h80;
            memory1[n] = 8'h80;
            reference_memory[n] = 8'h80;
            reference_memory[16+n] = 8'h80;
        end
        reset_case;
        for (n = 0; n < 64; n = n + 1) tick(1);
        if (pc[0] !== 0 || pc[1] !== 0) $fatal(1, "PC did not wrap after address F");
        // Reset at a nonzero cycle must clear state AND externally visible buses.
        tick(1); tick(1); tick(1);
        reset_case;
        if (state[0] !== 0 || pc[0] !== 0 || r0[0] !== 0 || r1[0] !== 0 ||
            address[0] !== 0 || write_data[0] !== 0 || we[0] !== 0)
            $fatal(1, "Asynchronous reset failed");
        $display("PASS tb_cpu: %0d opcode/register cases x 2 ISA profiles, %0d master cycles; PC rollover, pauses, reset", tests, microcycles);
        $finish;
    end
endmodule
