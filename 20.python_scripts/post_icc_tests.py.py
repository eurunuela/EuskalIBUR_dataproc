#!/usr/bin/env python3

import os
from itertools import combinations

import numpy as np
import pandas as pd
import statsmodel.api as sm
from scipy.stats import ttest_rel
from statsmodels.formula.api import ols

P_VALS = [0.05, 0.01, 0.001]

SUB_LIST = ['001', '002', '003', '004', '007', '008', '009']
FTYPE_LIST = ['echo-2', 'optcom', 'meica-aggr', 'meica-orth', 'meica-cons',
              'all-orth']


def test_and_export(t_df, f_dict, filename):
    # Prepare pandas dataframes
    t_df = pd.DataFrame(columns=['ftype1', 'ftype2', 't', 'p'])

    # Run t-test and append results to the df
    for ftype_one, ftype_two in list(combinations(FTYPE_LIST, 2)):
        t, p = ttest_rel(f_dict[ftype_one], f_dict[ftype_two])
        t_df = t_df.append({'ftype1': ftype_one, 'ftype2': ftype_two,
                            't': t, 'p': p}, ignore_index=True)

    # Threshold t-tests and export them
    t_mask = dict.fromkeys(P_VALS, t_df.copy(deep=True))
    for p_val in P_VALS:
        # Compute Sidak correction
        p_corr = 1-(1-p_val)**(1/len(list(combinations(FTYPE_LIST, 2))))
        t_mask[p_val]['p'] = t_mask[p_val]['p'].mask(t_mask[p_val]['p'] > p_corr)
        t_mask[p_val].to_csv(filename.format(p_val=p_val))


# THIS IS MAIN
cwd = os.getcwd()
os.chdir('/data/CVR_reliability/tests')

# Prepare dictionaries
icc = {'cvr': {}, 'lag': {}}
t_icc = {'cvr': {}, 'lag': {}}

d = dict.fromkeys(SUB_LIST, {})
cov = {'cvr': d, 'lag': d}
t_cov = {'cvr': d, 'lag': d}


for map in ['cvr', 'lag']:
    # Read files and import ICC and CoV values
    for ftype in FTYPE_LIST:
        icc[map][ftype] = np.genfromtxt(f'val/ICC2_{map}_masked_{ftype}.txt')[3]

        for sub in SUB_LIST:
            cov[map][sub][ftype] = np.genfromtxt(f'val/CoV_{sub}_{map}_masked_{ftype}.txt')[3]

    # T-test and threshold
    t_mask = test_and_export(t_icc[map], icc[map],
                             f'Ttests_ICC_{map.upper()}_{{p_val}}.csv')

    for sub in SUB_LIST:
        t_mask = test_and_export(t_cov[map][sub], cov[map][sub],
                                 f'Ttests_CoV_{sub}_{map.upper()}_{{p_val}}.csv')


os.chdir(cwd)
