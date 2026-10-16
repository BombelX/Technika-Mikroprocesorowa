#!/usr/bin/env python3
"""Create a portable source ZIP, excluding generated Vivado projects and caches."""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
destination = ROOT.parent / 'fpga_package.zip'
with ZipFile(destination, 'w', compression=ZIP_DEFLATED) as archive:
    for path in sorted(ROOT.rglob('*')):
        relative = path.relative_to(ROOT)
        if not path.is_file() or any(p in {'build','__pycache__','.Xil'} for p in relative.parts):
            continue
        if path.suffix in {'.vvp','.vcd','.jou','.log','.str'} or path.name == '.DS_Store':
            continue
        archive.write(path, Path(ROOT.name)/relative)
print(destination)
