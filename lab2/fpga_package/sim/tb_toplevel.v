`timescale 1ns / 1ps
// Integration: real conditioning/control/CPU/debug/UART, model BRAM only.
module tb_toplevel;
    reg CLK_IN = 0;
    always #5 CLK_IN = ~CLK_IN;
    reg [3:0] BTN = 0, SW = 0;
    wire [3:0] LD;
    wire [7:0] je;
    integer step_count = 0, before_count, j, k;
    reg [7:0] line [0:85];
    reg [7:0] byte_value;
    toplevel #(
        .CLOCK_HZ(1000000), .BAUD(100000),
        .DEBOUNCE_CYCLES(3), .STEP_PERIOD_CYCLES(12000)
    ) dut (.CLK_IN(CLK_IN), .LD(LD), .SW(SW), .BTN(BTN), .je(je));
    always @(posedge CLK_IN) if (dut.reset_n && dut.step_tick) step_count = step_count + 1;

    task cycles;
        input integer count;
        begin repeat (count) @(negedge CLK_IN); end
    endtask
    task click;
        input integer button_index;
        begin
            BTN[button_index] = 1; cycles(20);
            BTN[button_index] = 0; cycles(20);
        end
    endtask
    task instruction;
        begin
            before_count = step_count;
            click(2);
            cycles(36050);
            if (step_count != before_count + 4 || dut.dbg_state !== 0)
                $fatal(1, "Instruction button must generate exactly four CPU enables");
        end
    endtask
    task receive_byte;
        output [7:0] data;
        integer bit_number;
        begin
            @(negedge je[5]);
            #150; // Middle of bit 0 (clock 10 ns, divider 10 clocks per bit).
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                data[bit_number] = je[5];
                #100;
            end
            if (je[5] !== 1) $fatal(1, "UART stop bit invalid");
            #40;
        end
    endtask

    initial begin
        // Explicit physical reset, just as in the lab procedure.
        BTN[0] = 1; cycles(5); BTN[0] = 0; cycles(20);
        if (dut.dbg_pc !== 0 || dut.dbg_state !== 0 || je[5] !== 1)
            $fatal(1, "Power/reset state invalid");
        instruction; // 80
        instruction; // 90
        instruction; // EE -> RAM[E]=0
        if (dut.mem1.memory[14] !== 0) $fatal(1, "STR clear failed");
        instruction; // 86
        if (dut.dbg_r0 !== 6) $fatal(1, "MOV immediate failed");
        instruction; // DD
        if (dut.dbg_r1 !== 5) $fatal(1, "LDR from BRAM failed");
        instruction; // 20
        if (dut.dbg_r0 !== 11) $fatal(1, "ADD failed");
        instruction; // EE -> RAM[E]=B
        if (dut.mem1.memory[14] !== 11) $fatal(1, "STR result failed");
        instruction; // 00
        if (dut.dbg_pc !== 0) $fatal(1, "Loop JMP failed");

        // A held/bouncing button must not repeat steps after debouncing.
        SW = 1; cycles(20); before_count = step_count;
        BTN[2] = 1; cycles(1); BTN[2] = 0; cycles(1);
        BTN[2] = 1; cycles(100); BTN[2] = 0; cycles(20);
        if (step_count != before_count + 1 || dut.dbg_state !== 1)
            $fatal(1, "Single-cycle button/bounce behavior invalid");
        for (j=0; j<3; j=j+1) click(2);
        if (dut.dbg_state !== 0 || dut.dbg_pc !== 1)
            $fatal(1, "Single-cycle mode did not finish instruction");

        // Manual debugger, decode the actual UART signal and verify snapshot.
        fork
            begin click(1); end
            begin
                for (k=0; k<86; k=k+1) receive_byte(line[k]);
            end
        join
        if (line[0] !== 8'h0d || line[1] !== 8'h0a || line[2] !== "c" ||
            line[4] !== "0" || line[9] !== "0" || line[14] !== "5" || line[19] !== "1" ||
            line[35] !== "M" || line[36] !== ":" ||
            line[80] !== "0" || line[81] !== "B")
            $fatal(1, "UART dump differs from captured CPU/RAM");
        cycles(50);
        if (LD[1] !== 0) $fatal(1, "Debugger busy flag stuck");

        // Automatic dump must describe the state AFTER the requested step.
        SW = 5; cycles(20);
        fork
            begin click(2); end
            begin
                for (k=0; k<86; k=k+1) receive_byte(line[k]);
            end
        join
        if (line[4] !== "1" || line[9] !== "0" || line[14] !== "5" || line[19] !== "1")
            $fatal(1, "Automatic debug trigger captured the wrong CPU step");
        cycles(50);

        // BTN0 resets registers only; RAM is restored only by reprogramming.
        click(0);
        if (dut.dbg_pc !== 0 || dut.dbg_r0 !== 0 || dut.dbg_r1 !== 0 ||
            dut.mem1.memory[14] !== 11) $fatal(1, "Reset/RAM retention failed");
        SW = 2; cycles(20); before_count = step_count;
        cycles(1000010);
        if (step_count != before_count + 1) $fatal(1, "Automatic 1 Hz mode invalid");
        $display("PASS tb_toplevel: 3.5 program, 4/1-step controls, debounce, manual/automatic UART decoded, reset RAM retention, automatic timer");
        $finish;
    end
    initial begin
        #20000000;
        $fatal(1, "Integration timeout");
    end
endmodule
