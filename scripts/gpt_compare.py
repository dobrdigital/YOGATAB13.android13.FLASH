#!/usr/bin/env python3
"""Parse UFS primary GPT dumps (4096-byte sectors) and compare the device layout with a firmware package.

  python gpt_compare.py --device backups/gpt --package firmware/S510234
  python gpt_compare.py --device backups/gpt --dump-layout backups/gpt/device_layout.json

Device files: dev_gpt_main<N>.bin (6 sectors read from LBA 0). Package files: gpt_main<N>.bin.
Expected result for YT-K606F: exactly one difference, LUN0 'userdata' end LBA (package placeholder, fixed by patch0.xml).
"""
import argparse, json, os, struct, sys

SS = 4096
SENSITIVE = ('persist', 'fpinfo', 'frp', 'keystore', 'misc', 'ssd', 'lenovocust', 'lenovoraw', 'cdt', 'ddr',
             'devinfo', 'secdata', 'modemst1', 'modemst2', 'fsg', 'fsc')


def parse(path):
    b = open(path, 'rb').read()
    hdr = b[SS:SS + 92]
    if hdr[:8] != b'EFI PART':
        sys.exit(f'{path}: no GPT header at LBA1 (sector size {SS})')
    ent_lba, count, esz = struct.unpack_from('<QII', hdr, 72)
    parts = []
    for i in range(count):
        e = b[ent_lba * SS + i * esz: ent_lba * SS + (i + 1) * esz]
        if len(e) < esz or e[:16] == b'\0' * 16:
            continue
        first, last = struct.unpack_from('<QQ', e, 32)
        parts.append((e[56:128].decode('utf-16le').rstrip('\0'), first, last))
    return parts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--device', required=True, help='folder with dev_gpt_main0..5.bin')
    ap.add_argument('--package', help='unzipped firmware folder with gpt_main0..5.bin')
    ap.add_argument('--dump-layout', help='write device layout JSON {lun: [[name, first, last], ...]}')
    a = ap.parse_args()

    layout = {lun: parse(os.path.join(a.device, f'dev_gpt_main{lun}.bin')) for lun in range(6)}
    if a.dump_layout:
        json.dump(layout, open(a.dump_layout, 'w'), indent=1)

    for lun, parts in layout.items():
        for n, f, l in parts:
            if n in SENSITIVE:
                print(f'LUN{lun} {n:12s} start={f:<9} sectors={l - f + 1}')

    if not a.package:
        return
    all_diffs = []
    for lun in range(6):
        dev = {n: (f, l) for n, f, l in layout[lun]}
        pkg = {n: (f, l) for n, f, l in parse(os.path.join(a.package, f'gpt_main{lun}.bin'))}
        diffs = [(lun, n, dev.get(n), pkg.get(n)) for n in sorted(set(dev) | set(pkg)) if dev.get(n) != pkg.get(n)]
        all_diffs += diffs
        print(f'LUN{lun}: device {len(dev)} / package {len(pkg)} partitions, differences: {len(diffs)}')
        for d in diffs:
            print('   DIFF', d)
    # userdata is the last LUN0 partition; the package stores a placeholder end LBA that patch0.xml fixes.
    ok = all(lun == 0 and n == 'userdata' and d and p and d[0] == p[0] for lun, n, d, p in all_diffs)
    print('RESULT:', 'OK' if ok else 'STOP - layouts differ')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
