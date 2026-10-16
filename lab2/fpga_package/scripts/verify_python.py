#!/usr/bin/env python3
"""Compare real lab1 Cpu execution against RTL after every enabled CPU cycle."""
import argparse
import json
import subprocess
import tempfile
from pathlib import Path
from prepare_programs import ROOT, get_programs, trace

TB = r'''
`timescale 1ns/1ps
module tb_reference;
reg clk=0, reset_n=1;
wire [3:0] a, r0, r1, pc;
wire [1:0] state;
wire [7:0] dw;
wire we;
reg [7:0] dr;
reg [7:0] memory [0:15];
integer f, n, i, row, cycle, es, e0, e1, epc, ea, ew, em;
cpu #(.ISA_LAB2(PROFILE), .USE_CLK_ENABLE(1)) dut(
 .clk(clk), .reset_n(reset_n), .clk_enable(1'b1),
 .mem_address(a), .mem_data_r(dr), .mem_data_w(dw), .mem_we(we),
 .dbg_state(state), .dbg_r0(r0), .dbg_r1(r1), .dbg_pc(pc));
always @(negedge clk) begin
 if(we) begin memory[a] <= dw; dr <= dw; end
 else dr <= memory[a];
end
initial begin
 $readmemh("program.hex",memory);
 f=$fopen("expected.txt","r");
 if (!f) $fatal(1,"Missing expected trace");
 reset_n=0; #2; reset_n=1;
 for(row=0;row<ROWS;row=row+1) begin
  #3;clk=1;#5;clk=0;#1;
  n=$fscanf(f,"%d %h %h %h %h %h %h",cycle,es,e0,e1,epc,ea,ew);
  if(n!=7) $fatal(1,"Bad reference row %0d",row);
  if(state!==es[1:0] || r0!==e0[3:0] || r1!==e1[3:0] ||
     pc!==epc[3:0] || a!==ea[3:0] || dw!==ew[7:0])
     $fatal(1,"cycle=%0d actual c=%h r0=%h r1=%h pc=%h A=%h W=%h expected c=%h r0=%h r1=%h pc=%h A=%h W=%h",cycle,state,r0,r1,pc,a,dw,es,e0,e1,epc,ea,ew);
  for(i=0;i<16;i=i+1) begin
   n=$fscanf(f," %h",em);
   if(n!=1 || memory[i]!==em[7:0]) $fatal(1,"Memory mismatch cycle=%0d address=%h got=%h expected=%h",cycle,i,memory[i],em);
  end
 end
 $display("PASS reference cycles=%0d",ROWS);
 $finish;
end
endmodule
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--iverilog', default='iverilog')
    parser.add_argument('--vvp', default='vvp')
    args = parser.parse_args()
    manifest = json.loads((ROOT / 'programs/manifest.json').read_text())
    cycles = 0
    for name, program in get_programs().items():
        profile = manifest[name]['isa_lab2']
        rows = trace(program, profile, manifest[name]['instructions'] * 3)
        with tempfile.TemporaryDirectory(prefix='scs_reference_') as temp:
            cwd = Path(temp)
            (cwd / 'program.hex').write_text('\n'.join(f'{b:02x}' for b in program))
            (cwd / 'expected.txt').write_text('\n'.join(' '.join([str(r['cycle']), *[f"{r[k]:x}" for k in ('state','r0','r1','pc','address','write')], *[f'{b:x}' for b in r['memory']]]) for r in rows))
            (cwd / 'tb.v').write_text(TB.replace('PROFILE',str(profile)).replace('ROWS',str(len(rows))))
            subprocess.run([args.iverilog, '-g2012', '-s', 'tb_reference', '-o', str(cwd/'test.vvp'), str(ROOT/'rtl/cpu.v'), str(cwd/'tb.v')], check=True, cwd=cwd)
            result = subprocess.run([args.vvp,str(cwd/'test.vvp')], check=True, cwd=cwd, text=True, capture_output=True)
            print(name, f'ISA_LAB2={profile}', result.stdout.strip().splitlines()[0])
            cycles += len(rows)
    print(f'PASS: 9 programs, 3 loops each, {cycles} microcycles; registers, state, PC, address, write data and all RAM bytes match.')
    print('R bus intentionally excluded: Python latches a read, BRAM continuously reads the selected address.')


if __name__ == '__main__':
    main()
