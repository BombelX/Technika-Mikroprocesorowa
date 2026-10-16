#!/usr/bin/env python3
"""Portable test entry point, Python3 + Icarus Verilog; no third-party Python modules."""
import argparse
import subprocess
import sys
import tempfile
from pathlib import Path
from prepare_programs import ROOT


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--iverilog', default='iverilog')
    parser.add_argument('--vvp', default='vvp')
    args = parser.parse_args()
    tests = {
        'tb_cpu': [ROOT/'rtl/cpu.v', ROOT/'sim/tb_cpu.v'],
        'tb_toplevel': [*sorted((ROOT/'rtl').glob('*.v')), ROOT/'sim/mem_wrapper_model.v', ROOT/'sim/tb_toplevel.v'],
    }
    for name, files in tests.items():
        with tempfile.TemporaryDirectory(prefix=f'scs_{name}_') as temp:
            executable = Path(temp)/'test.vvp'
            subprocess.run([args.iverilog, '-g2012', '-Wall', '-s', name, '-o', str(executable), *map(str,files)], check=True)
            subprocess.run([args.vvp,str(executable)],check=True)
    subprocess.run([sys.executable, str(ROOT/'scripts/verify_python.py'), '--iverilog',args.iverilog,'--vvp',args.vvp],check=True)


if __name__ == '__main__':
    main()
