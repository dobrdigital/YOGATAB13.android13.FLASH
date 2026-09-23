#!/usr/bin/env python3
"""Inspect (and optionally patch a COPY of) the Lenovo `fpinfo` partition dump of YT-K606F.

  python fpinfo_inspect.py fpinfo.bin
  python fpinfo_inspect.py fpinfo.bin --set-region 01 --out fpinfo_row.bin

Region lock byte at 0xE9: 00 = unbound, 01 = ROW, 02 = CN/ZUI.
Serial number and MACs are masked in the output so it can be pasted publicly.
The input file is never modified.
"""
import argparse, hashlib, sys

REGION_OFF = 0xE9
REGION = {0x00: 'unbound (00)', 0x01: 'ROW (01)', 0x02: 'CN/ZUI (02)'}


def cstr(b, off, n):
    return b[off:off + n].split(b'\0', 1)[0].decode('ascii', 'replace')


def mask(s, keep=4):
    return s[:keep] + '*' * max(0, len(s) - keep)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('fpinfo')
    ap.add_argument('--set-region', choices=['00', '01', '02'])
    ap.add_argument('--out')
    a = ap.parse_args()

    b = open(a.fpinfo, 'rb').read()
    if len(b) < 0x100:
        sys.exit('file too small')
    country = cstr(b, 0x00, 8)
    model = cstr(b, 0x14, 30)
    fp = cstr(b, 0x32, 120)
    serial = cstr(b, 0xAA, 30)
    if not model.startswith('Lenovo') or 'K606F' not in model:
        print(f'WARNING: unexpected model field {model!r} — layout may differ; do not patch.')
    print(f'country code (0x00): {country}')
    print(f'model        (0x14): {model}')
    print(f'fingerprint  (0x32): {fp}')
    print(f'serial       (0xAA): {mask(serial)}')
    print(f'flag         (0xC7): {b[0xC7]:02x}   (01 on both CN and ROW units - not the region)')
    print(f'MACs    (0xDB/0xE2): {b[0xDB]:02x}:{b[0xDC]:02x}:**:**:**:** / {b[0xE2]:02x}:{b[0xE3]:02x}:**:**:**:**')
    r = b[REGION_OFF]
    print(f'REGION       (0xE9): {r:02x}  -> {REGION.get(r, "UNKNOWN - stop")}')
    print(f'sha256: {hashlib.sha256(b).hexdigest()}')

    if a.set_region:
        if not a.out:
            sys.exit('--out is required with --set-region')
        nb = bytearray(b)
        nb[REGION_OFF] = int(a.set_region, 16)
        diff = [i for i in range(len(b)) if b[i] != nb[i]]
        if len(diff) > 1 or (diff and diff[0] != REGION_OFF):
            sys.exit(f'unexpected diff {diff}')
        open(a.out, 'wb').write(nb)
        print(f'wrote {a.out}: {len(diff)} byte(s) changed at {[hex(d) for d in diff]}, sha256 {hashlib.sha256(nb).hexdigest()}')


if __name__ == '__main__':
    main()
