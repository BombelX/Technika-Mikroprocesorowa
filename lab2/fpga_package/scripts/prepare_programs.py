#!/usr/bin/env python3
"""Rebuild COE/HEX files and expected traces from the bundled lab1 snapshot.

Only the lists are parsed from scs.py; its POSIX-only terminal code is not imported.
The original Cpu is executed for Python ISA. The two lab2 opcodes are adapted here.
"""
import ast
import contextlib
import csv
import importlib.util
import io
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def get_programs():
    tree = ast.parse((ROOT / 'reference/scs.py').read_text())
    result = {}
    for node in tree.body:
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id.endswith('_program'):
                    result[target.id.removesuffix('_program')] = ast.literal_eval(node.value)
    result['overflow'] = [0x8F, 0x91, 0x20, 0xEE, 0x00] + [0] * 11
    result['sub_underflow'] = [0x83, 0x95, 0x40, 0xEE, 0x00] + [0] * 11
    result['lab2_add_r1'] = [0x80, 0x90, 0xEE, 0x86, 0xDD, 0x30, 0xFE, 0x00] + [0] * 5 + [5, 0x11, 0]
    result['lab2_mul'] = result['mul'].copy()
    result['lab2_mul'][2] = 0x50
    return result


def get_cpu():
    spec = importlib.util.spec_from_file_location('lab1_reference_cpu', ROOT / 'reference/cpu.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.Cpu


def step(cpu, lab2=False):
    # No PC masking is added: the original Python model remains the oracle.
    original = cpu.opcode
    add_r1 = lab2 and cpu.state == 2 and original >> 4 == 3
    mul50 = lab2 and cpu.state == 2 and original >> 4 == 5
    old_r0, old_r1 = cpu.r0, cpu.r1
    if add_r1:
        cpu.opcode = 0x20
    elif mul50:
        cpu.opcode = 0x30
    with contextlib.redirect_stdout(io.StringIO()):
        cpu.next_cycle()
    if add_r1:
        cpu.r0, cpu.r1 = old_r0, (old_r0 + old_r1) & 15
    if add_r1 or mul50:
        cpu.opcode = original


def trace(program, lab2, count):
    cpu = get_cpu()(program.copy())
    rows = []
    for cycle in range(1, count * 4 + 1):
        step(cpu, lab2)
        rows.append(dict(cycle=cycle, instruction=(cycle+3)//4,
                         state=cpu.state, r0=cpu.r0, r1=cpu.r1, pc=cpu.pc,
                         address=cpu.mem_address, write=cpu.mem_data_w,
                         memory=cpu.mem.copy()))
    return rows


def main():
    programs = get_programs()
    counts = dict(base=6, load_store=8, undefined=9, mul=6, sub=5,
                  overflow=5, sub_underflow=5, lab2_add_r1=8, lab2_mul=6)
    manifest = {}
    for name, data in programs.items():
        assert len(data) == 16 and all(0 <= b < 256 for b in data)
        folder = ROOT / 'programs'
        folder.mkdir(exist_ok=True)
        (folder / f'{name}.coe').write_text('memory_initialization_radix=16;\nmemory_initialization_vector=\n' + ',\n'.join(f'{b:02X}' for b in data) + ';\n')
        (folder / f'{name}.hex').write_text('\n'.join(f'{b:02X}' for b in data) + '\n')
        rows = trace(data, name.startswith('lab2_'), counts[name])
        (folder / f'{name}.trace.json').write_text('[\n' + ',\n'.join(json.dumps(row) for row in rows) + '\n]\n')
        with (folder / f'{name}.instructions.csv').open('w', newline='') as f:
            writer = csv.writer(f, lineterminator='\n')
            writer.writerow(['instruction', 'cycle', 'state', 'pc_hex', 'r0_hex', 'r1_hex', 'address_hex', 'write_hex', 'memory_hex'])
            for row in rows[3::4]:
                writer.writerow([row['instruction'], row['cycle'], row['state'], *[f"{row[k]:X}" for k in ('pc','r0','r1','address','write')], ' '.join(f'{b:02X}' for b in row['memory'])])
        manifest[name] = dict(isa_lab2=int(name.startswith('lab2_')), instructions=counts[name], bytes=[f'{b:02X}' for b in data])
    (ROOT / 'programs/manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Prepared {len(programs)} programs and Python reference traces.')


if __name__ == '__main__':
    main()
