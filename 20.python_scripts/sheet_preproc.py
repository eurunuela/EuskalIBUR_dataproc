#!/usr/bin/env python3

import sys
import os
import pandas as pd

from numpy import savetxt

sub = sys.argv[1]
LAST_SES = 10

cwd = os.getcwd()

os.chdir('/data')

xl = pd.ExcelFile('MEICA.xlsx')

if not os.path.exists('decomp'):
    os.mkdir('decomp')

os.chdir('decomp')

sub_table = pd.read_excel(xl, sub)
# Uncomment this for fsl_regfilt
# sub_table.index += 1

LAST_SES += 1
for ses in range(1, LAST_SES):
    col = f'ses-{ses:02d}'
    # net = sub_table.index[sub_table[col] == 'N'].tolist()
    vas = sub_table.index[sub_table[col] == 'V'].tolist()
    acc = sub_table.index[sub_table[col] == 'A'].tolist()
    rej = sub_table.index[sub_table[col] == 'R'].tolist()

    px = f'sub-{sub}_ses-{ses:02d}'
    savetxt(f'{px}_accepted_list.1D', acc, fmt='%d', delimiter=',', newline=',')
    savetxt(f'{px}_rejected_list.1D', rej, fmt='%d', delimiter=',', newline=',')
    savetxt(f'{px}_vessels_list.1D', vas, fmt='%d', delimiter=',', newline=',')
    # savetxt(f'{px}_networks_list.1D', net, fmt='%d', delimiter=',', newline=',')

os.chdir(cwd)
