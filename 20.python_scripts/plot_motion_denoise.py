#!/usr/bin/env python3
import os
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


SUB_LIST = ['001', '002', '003', '004', '007', '008', '009']
LAST_SES = 10  # 10

SET_DPI = 100
FIGSIZE_1 = (9, 5)
FIGSIZE_2 = (12, 10)
FIGSIZE_3 = (6, 10)
BH_LEN = 39
BH_TRIALS = 8

FTYPE_LIST = ['pre', 'echo-2', 'optcom', 'meica-aggr', 'meica-orth',
              'meica-cons']
COLOURS = ['#663300ff', '#d62728ff', '#2ca02cff', '#ff7f0eff', '#1f77b4ff',
           '#ff33ccff']
FTYPE_DICT = {'pre': 'SE-PRE', 'echo-2': 'SE-MPR', 'optcom': 'OC-MPR',
              'meica-aggr': 'ME-AGG', 'meica-orth': 'ME-MOD',
              'meica-cons': 'ME-CON'}

# Compute derivate constants

TIME = np.asarray(range(BH_LEN))

TOT_TRIALS = LAST_SES*BH_TRIALS
DIST_TICKS = range(0, TOT_TRIALS, BH_TRIALS)

LAST_SES += 1


# 01. Make scatterplots of DVARS vs FD
def plot_DVARS_vs_FD(data, ftypes=FTYPE_LIST, subjects=SUB_LIST):
    for sub in subjects:
        plt.figure(figsize=FIGSIZE_1, dpi=SET_DPI)

        plot_title = f'DVARS vs FD, subject {sub}'
        plt.title(plot_title)

        for ses in range(1, LAST_SES):
            x_col = f'{sub}_{ses:02g}_fd'
            # loop for ftype
            for i, ftype in enumerate(ftypes):
                y_col = f'{sub}_{ses:02g}_dvars_{ftype}'
                sns.regplot(x=data[x_col], y=data[y_col], fit_reg=True,
                            label=FTYPE_DICT[ftype], color=COLOURS[i],
                            robust=True, ci=None, scatter_kws={'s': 5},
                            line_kws={'lw': 1})

            if ses == 1:
                plt.legend()

        plt.xlabel('FD')
        plt.xlim(-.01, 1.2)
        plot_ylabel = 'DVARS'
        plt.ylabel(plot_ylabel)
        plt.ylim(10, 1250)
        plt.tight_layout()
        fig_name = f'/data/plots/{sub}_DVARS_vs_FD.png'
        plt.savefig(fig_name, dpi=SET_DPI)
        plt.clf()
        plt.close()

    plt.figure(figsize=FIGSIZE_1, dpi=SET_DPI)
    plot_title = 'DVARS vs FD, all subjects'
    plt.title(plot_title)

    for i, ftype in enumerate(ftypes):
        x_data = np.empty(0)
        y_data = np.empty(0)
        for sub in subjects:
            for ses in range(1, LAST_SES):
                x_col = f'{sub}_{ses:02g}_fd'
                x_data = np.append(x_data, data[x_col])
                y_col = f'{sub}_{ses:02g}_dvars_{ftype}'
                y_data = np.append(y_data, data[y_col])

        sns.regplot(x=x_data, y=y_data, scatter=False,
                    fit_reg=True,  label=FTYPE_DICT[ftype],
                    color=COLOURS[i], ci=100)

    for i, ftype in enumerate(ftypes):
        for sub in subjects:
            x_col = f'{sub}_{ses:02g}_fd'
            for ses in range(1, LAST_SES):
                y_col = f'{sub}_{ses:02g}_dvars_{ftype}'
                sns.regplot(x=data[x_col], y=data[y_col], scatter=False,
                            fit_reg=True,
                            color=COLOURS[i], robust=True, ci=None,
                            line_kws={'alpha': 0.05})

    plt.legend(FTYPE_DICT.values())
    plt.xlabel('FD')
    plt.xlim(-.01, 1.2)
    plot_ylabel = 'DVARS'
    plt.ylabel(plot_ylabel)
    plt.ylim(10, 1250)
    plt.tight_layout()
    fig_name = '/data/plots/allsubs_DVARS_vs_FD.png'
    plt.savefig(fig_name, dpi=SET_DPI)
    plt.clf()
    plt.close()


# 02. Helping function for the next one
def read_and_shape(filename, ftypes=FTYPE_LIST, norm=True):
    # responses is ftype*ses*trials*BH_LEN
    responses = np.empty((len(ftypes), (LAST_SES - 1), BH_TRIALS, BH_LEN))
    for n, ftype in enumerate(ftypes):
        for ses in range(1, LAST_SES):
            data = np.genfromtxt(filename.format(ftype=ftype, ses=f'{ses:02g}'))
            if norm:
                data = (data - data.mean()) / data.mean() * 100
            for bh in range(BH_TRIALS):
                responses[n, ses-1, bh, :] = data[12+BH_LEN*bh:12+BH_LEN*(bh+1)]

    return responses.reshape((len(ftypes), (LAST_SES - 1)*BH_TRIALS, BH_LEN),
                             order='C')


# 03. Make timeseries plots
def plot_timeseries_and_BOLD_vs_FD(sub, ftypes=FTYPE_LIST, subjects=SUB_LIST):
    # Read and prepare files
    fd_response = read_and_shape(f'sub-{sub}/{{ftype}}_sub-{sub}_'
                                 f'ses-{{ses}}.1D', ['fd', ], norm=False)
    dvars_responses = read_and_shape(f'sub-{sub}/dvars_{{ftype}}_sub-'
                                     f'{sub}_ses-{{ses}}.1D')
    bold_responses = read_and_shape(f'sub-{sub}/'
                                    f'avg_GM_{{ftype}}_sub-'
                                    f'{sub}_ses-{{ses}}.1D')

    # Compute averages
    avg_b = bold_responses.mean(axis=1)
    avg_d = dvars_responses.mean(axis=1)

    # Compute trial distance from average
    dist_avg = np.empty((len(ftypes), TOT_TRIALS))
    for n in range(TOT_TRIALS):
        dist_avg[:, n] = np.abs(avg_b -
                                np.squeeze(bold_responses
                                           [:, :(n+1), :].mean(axis=1))
                                ).mean(axis=1)

    # Create response plot
    bh_plot = plt.figure(figsize=FIGSIZE_2, dpi=SET_DPI)
    bh_plot.suptitle(f'BreathHold response, subject {sub}')

    height_ratios = [1] * (len(ftypes)+2)
    height_ratios[-2] = .3
    gs = bh_plot.add_gridspec(nrows=len(ftypes)+2, ncols=2,
                              height_ratios=height_ratios)

    # Work with dictionary of subplots
    bh_splt = {}

    # Add FD on both columns
    for col in range(2):
        bh_splt[f'fd_{col}'] = bh_plot.add_subplot(gs[len(ftypes)+1, col])

        bh_splt[f'fd_{col}'].plot(TIME, fd_response[0, :, :].T,
                                  color='#000000ff', alpha=.05)

        bh_splt[f'fd_{col}'].plot(TIME, fd_response.mean(axis=(0, 1)),
                                  color='#000000ff')
        bh_splt[f'fd_{col}'].grid(True, axis='x', markevery='5')

        bh_splt[f'fd_{col}'].set_title("FD")
        # bh_splt[f'fd_{col}'].set_ylabel("FD")
        bh_splt[f'fd_{col}'].yaxis.set_label_position('right')
        bh_splt[f'fd_{col}'].set_xlabel('Timepoints')
        bh_splt[f'fd_{col}'].set_xlim(0, BH_LEN-1)
        bh_splt[f'fd_{col}'].set_ylim(0, np.percentile(fd_response, 98))
        # Also add empty subplot above the FD
        bh_splt[f'empty_{col}'] = bh_plot.add_subplot(gs[len(ftypes), col])
        bh_splt[f'empty_{col}'].axis('off')

    for i, ftype in enumerate(ftypes):
        # Set plot row
        if i == 0:
            # Set base dvars, bold plot for axes
            bh_splt[f'dvars_{ftype}'] = bh_plot.add_subplot(gs[i, 0],
                                                            sharex=bh_splt['fd_0'])
            bh_splt[f'bold_{ftype}'] = bh_plot.add_subplot(gs[i, 1],
                                                           sharex=bh_splt['fd_1'])
            # Set various axes properties
            bh_splt[f'dvars_{ftype}'].set_ylim(np.percentile(dvars_responses, 1),
                                               np.percentile(dvars_responses, 98))
            bh_splt[f'bold_{ftype}'].set_ylim(np.percentile(bold_responses, 1),
                                              np.percentile(bold_responses, 99))
            bh_splt[f'bold_{ftype}'].set_title("% BOLD")
            bh_splt[f'dvars_{ftype}'].set_title("% DVARS")
            # bh_splt[f'bold_{ftype}'].axes.get_yaxis().set_ticks([-.05, 0, .05])
        else:
            # Recover y axis from base dvars and bold
            key = {'d': f'dvars_{ftypes[0]}', 'b': f'bold_{ftypes[0]}'}
            bh_splt[f'dvars_{ftype}'] = bh_plot.add_subplot(gs[i, 0],
                                                            sharex=bh_splt['fd_0'],
                                                            sharey=bh_splt[key['d']])
            bh_splt[f'bold_{ftype}'] = bh_plot.add_subplot(gs[i, 1],
                                                           sharex=bh_splt['fd_1'],
                                                           sharey=bh_splt[key['b']])

        # Add DVARS plots in first column
        bh_splt[f'dvars_{ftype}'].plot(TIME, dvars_responses[i, :, :].T,
                                       label='',
                                       color=COLOURS[i], alpha=.05,)
        bh_splt[f'dvars_{ftype}'].plot(TIME, avg_d[i, :],
                                       label=FTYPE_DICT[ftype],
                                       color=COLOURS[i])

        # bh_splt[f'dvars_{ftype}'].set_ylabel('% DVARS')
        plt.setp(bh_splt[f'dvars_{ftype}'].get_xticklabels(), visible=False)
        bh_splt[f'dvars_{ftype}'].grid(True, axis='x', markevery='5')
        bh_splt[f'dvars_{ftype}'].yaxis.set_label_position('right')

        # Add BOLD plots in second column
        bh_splt[f'bold_{ftype}'].plot(TIME, bold_responses[i, :, :].T,
                                      label='',
                                      color=COLOURS[i], alpha=.05)
        bh_splt[f'bold_{ftype}'].plot(TIME, avg_b[i, :],
                                      label=FTYPE_DICT[ftype],
                                      color=COLOURS[i])

        # bh_splt[f'bold_{ftype}'].set_ylabel('% BOLD')
        plt.setp(bh_splt[f'bold_{ftype}'].get_xticklabels(), visible=False)
        bh_splt[f'bold_{ftype}'].grid(True, axis='x', markevery='5')
        bh_splt[f'bold_{ftype}'].yaxis.set_label_position('right')

        bh_splt[f'bold_{ftype}'].legend(loc=1, prop={'size': 8})

    for key in ['bold', 'dvars']:
        for tic in bh_splt[f'bold_{FTYPE_LIST[-1]}'].xaxis.get_major_ticks():
            tic.tick1On = tic.tick2On = False

    gs.tight_layout(bh_plot)
    gs.update(top=0.93, hspace=0)

    bh_plot.savefig(f'/data/plots/{sub}_BOLD_time.png', dpi=SET_DPI)

    plt.close('all')


# 04. Make distfromavg plots
def plot_distance_from_avg(ftypes=FTYPE_LIST, subjects=SUB_LIST):
    # BOLD is for all subjects
    bold_responses = dict.fromkeys(subjects, '')
    dist_avg = dict.fromkeys(subjects, '')
    avg_b = dict.fromkeys(subjects, '')

    for sub in subjects:
        bold_responses[sub] = read_and_shape(f'sub-{sub}/'
                                             f'avg_GM_{{ftype}}_sub-'
                                             f'{sub}_ses-{{ses}}.1D')
        # Compute trial distance from average
        avg_b[sub] = bold_responses[sub].mean(axis=1)
        dist_avg[sub] = np.empty((len(ftypes), TOT_TRIALS))
        for n in range(TOT_TRIALS):
            dist_avg[sub][:, n] = np.abs(avg_b[sub] -
                                         np.squeeze(bold_responses[sub]
                                                    [:, :(n+1), :].mean(axis=1))
                                         ).mean(axis=1)
            # Divide by maximum
            # dist_avg[sub] = dist_avg[sub] / dist_avg[sub].max()

    # Create response plot
    bh_plot = plt.figure(figsize=FIGSIZE_3, dpi=SET_DPI)
    bh_plot.suptitle('Normalised distance from average')

    gs = bh_plot.add_gridspec(nrows=len(subjects), ncols=1)

    # Work with dictionary of subplots
    bh_splt = {}

    for i, sub in reversed(list(enumerate(subjects))):
        # Set plot row
        if i == len(subjects)-1:
            # Set base dvars, bold and dist plot for axes
            bh_splt[f'dist_{sub}'] = bh_plot.add_subplot(gs[i, 0])
            # Set various axes properties
            bh_splt[f'dist_{sub}'].axes.get_xaxis().set_ticks(DIST_TICKS)
            bh_splt[f'dist_{sub}'].set_xlim(0, TOT_TRIALS-1)
        else:
            # Recover y axis from base dvars and bold
            key = f'dist_{subjects[-1]}'
            bh_splt[f'dist_{sub}'] = bh_plot.add_subplot(gs[i, 0],
                                                         sharex=bh_splt[key])
            plt.setp(bh_splt[f'dist_{sub}'].get_xticklabels(), visible=False)

        # Add distance to average plot
        # Plot all subjects
        for j, ftype in enumerate(ftypes):
            if ftype == 'optcom':
                bh_splt[f'dist_{sub}'].plot(dist_avg[sub][j, :], '-',
                                            label=FTYPE_DICT[ftype],
                                            color=COLOURS[j], linewidth=1.1)
            else:
                bh_splt[f'dist_{sub}'].plot(dist_avg[sub][j, :], '-.',
                                            label=FTYPE_DICT[ftype],
                                            color=COLOURS[j], linewidth=1.1)

        # bh_splt[f'dist_{sub}'].set_ylim(0, 1.1)
        bh_splt[f'dist_{sub}'].set_ylabel('avg dist')
        bh_splt[f'dist_{sub}'].set_ylim(bottom=0)
        bh_splt[f'dist_{sub}'].grid(True, axis='x', markevery='8')
        bh_splt[f'dist_{sub}'].axes.get_xaxis().set_ticks(DIST_TICKS)
        # bh_splt[f'dist_{sub}'].axes.get_yaxis().set_ticks([0, .5, 1])
        bh_splt[f'dist_{sub}'].yaxis.set_label_position('right')
        bh_splt[f'dist_{sub}'].set_title(f'Subject {sub}', fontsize=10)

    bh_splt['dist_009'].legend(bbox_to_anchor=(0, -.5, 1, .102),
                               loc='upper left', ncol=3,
                               mode='expand', borderaxespad=0)
    gs.tight_layout(bh_plot)
    gs.update(top=0.93, bottom=0.08, hspace=.4)

    bh_plot.savefig('/data/plots/distance_from_avg.png', dpi=SET_DPI)

    plt.close('all')


if __name__ == '__main__':
    cwd = os.getcwd()

    os.chdir('/data/ME_Denoising')

    data = pd.read_csv('sub_table.csv')

    plot_DVARS_vs_FD(data)
    for sub in SUB_LIST:
        plot_timeseries_and_BOLD_vs_FD(sub)
    plot_distance_from_avg()

    os.chdir(cwd)
