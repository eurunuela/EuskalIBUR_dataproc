#!/usr/bin/env python3

import argparse
import os
import sys

import matplotlib.pyplot as plt
import nibabel as nib
import numpy as np
from brainsmash.workbench.geo import volume
from brainsmash.mapgen import Sampled


LAST_SES = 10  # 10
ATLAS_LIST = ['Mutsaerts', 'Schaefer-100']

SET_DPI = 100
FIGSIZE = (18, 10)

COLOURS = ['#2ca02cff', '#d62728ff']  # , '#1f77b4ff']
# COLOURS = ['#d62728ff', '#2ca02cff', '#ff7f0eff', '#1f77b4ff',
#            '#ff33ccff']
ATLAS_DICT = {'empty': ''}

ATLAS_FOLDER = os.path.join('CVR_reliability', 'Atlas_comparison')
LAST_SES += 1


#########
# Utils #
#########
def _get_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('-in', '--input-file',
                        dest='data_fname',
                        type=str,
                        help='The map you want to scramble',
                        required=True)
    parser.add_argument('-type', '--input-type',
                        dest='data_content',
                        type=str,
                        help='The type of data represented in the map you want '
                             'to scramble',
                        required=True)
    parser.add_argument('-wdr', '--workdir',
                        dest='wdr',
                        type=str,
                        help='Workdir.',
                        default='/data')
    parser.add_argument('-sdr', '--scriptdir',
                        dest='scriptdir',
                        type=str,
                        help='Script directory.',
                        default='/scripts')
    parser.add_argument('-overwrite', '--overwrite',
                        dest='overwrite',
                        action='store_true',
                        help='Overwrite previously computed distances.',
                        default=False)
    parser.add_argument('-nm', '--num-null-maps',
                        dest='null_maps',
                        type=int,
                        help='Number of surrogate maps to generate. '
                             'Default is 1000.',
                        default=1000)
    parser.add_argument('-pn', '--plotname',
                        dest='plot_name',
                        type=str,
                        help='Plot name. Default: plots/plot.',
                        default='plots/plot')
    # Workflows
    parser.add_argument('-ga', '--genatlas',
                        dest='genatlas',
                        action='store_true',
                        help='Generate atlas dictionary.',
                        default=False)
    parser.add_argument('-cd', '--compdist',
                        dest='compdist',
                        action='store_true',
                        help='Compute distance and create memory-mapped file.',
                        default=False)
    parser.add_argument('-gs', '--gensurr',
                        dest='gensurr',
                        action='store_true',
                        help='Generate surrogates and plots.',
                        default=False)
    parser.add_argument('-pp', '--plotparc',
                        dest='plotparc',
                        action='store_true',
                        help='Generate plots.',
                        default=False)
    return parser


def export_file(wdr, fname, ex_object):
    ex_file = os.path.join(wdr, ATLAS_FOLDER, fname)
    os.makedirs(os.path.join(wdr, ATLAS_FOLDER), exist_ok=True)
    np.savez_compressed(ex_file, ex_object)


def check_file(wdr, fname):
    in_file = os.path.join(wdr, ATLAS_FOLDER, fname)
    return os.path.isfile(in_file)


def load_file(wdr, fname):
    in_file = os.path.join(wdr, ATLAS_FOLDER, fname)
    return np.load(in_file, allow_pickle=True)


def load_nifti(data_fname):
    data_img = nib.load(f'{data_fname}.nii.gz')
    return data_img.get_fdata()


#############
# Workflows #
#############
def generate_atlas_dictionary(wdr, scriptdir):
    # Check that you really need to do this
    if args.overwrite is False or check_file(wdr, 'atlases.npz') is True:
        print(f'Found eisting atlases dictionary in {wdr}, '
              'loading instead of generating.')
        atlases = load_file(args.wdr, 'atlases.npz')
    else:
        # Create data dictionary
        atlases = dict.fromkeys(ATLAS_LIST)

        # Read atlases
        for atlas in ATLAS_LIST:
            atlas_img = nib.load(f'{scriptdir}/90.template/{atlas}.nii.gz')
            atlases[atlas] = atlas_img.get_fdata()

        # Create intersection of atlases
        atlases['intersect'] = atlases[ATLAS_LIST[0]].copy()

        for atlas in ATLAS_LIST[1:]:
            atlases['intersect'] = atlases['intersect'] + atlases[atlas]

        # Export atlases
        export_file(wdr, 'atlases', atlases)

    return atlases


def compute_distances(wdr, atlases):
    # Check that you really need to do this
    distmap = os.path.join(args.wdr, ATLAS_FOLDER, 'mmdist', 'distmap.npy')
    index = os.path.join(args.wdr, ATLAS_FOLDER, 'mmdist', 'index.npy')
    if args.overwrite is False or check_file(args.wdr, distmap) is True:
        print('Distance memory mapped file already exists. Skip computation!')
        dist_fname = {'D': distmap, 'index': index}
    else:
        coord_dir = os.path.join(wdr, ATLAS_FOLDER, 'mmdist')
        # Create folders
        os.makedirs(coord_dir, exist_ok=True)
        # Get position of the voxels in the atlas intersection
        coordinates = np.asarray(np.where(atlases['intersect'] > 0)).transpose()
        dist_fname = volume(coordinates, coord_dir)

    return dist_fname


def generate_surrogates(data_fname, atlases, dist_fname, null_maps, wdr):
    # Read data
    data = load_nifti(data_fname)

    # Extract data and feed surrogate maps
    data_masked = data[atlases['intersect'] > 0]

    gen = Sampled(x=data_masked, D=dist_fname['D'], index=dist_fname['index'])
    surrogate_maps = gen(n=null_maps)

    # Export atlases
    export_file(wdr, f'surrogates_{data_fname}', surrogate_maps)

    return surrogate_maps, data_masked


def plot_parcels(null_maps, data_content, atlases, surrogate_maps, data_masked, plot_name):
    # Plot parcel value against voxel size
    # Setup plot
    plt.figure(figsize=FIGSIZE, dpi=SET_DPI)
    plt.xlabel('Number of voxels in MNI')

    # #!# ylabel has to reflect data
    plt.ylabel(data_content)
    # plt.ylim(0, 1)

    for atlas in ATLAS_LIST:
        # Mask atlas to match data_masked
        atlas_masked = atlases[atlas][atlases['intersect'] > 0]
        # Find unique values (labels) and occurrencies (label size)
        unique, occurrencies = np.unique(atlas_masked, return_counts=True)

        # Populate the plot
        for i, label in enumerate(unique[unique > 0]):
            # Start with all surrogates
            for n in range(null_maps):
                # compute pacel average
                label_avg = surrogate_maps[n][atlas_masked == label].mean()
                plt.plot(occurrencies[i], label_avg, '.', color='#bbbbbbff')

    # New loop to be sure that real data appear on top of surrogates
    for j, atlas in ATLAS_LIST:
        # Mask atlas to match data_masked
        atlas_masked = atlases[atlas][atlases['intersect'] > 0]
        # Find unique values (labels) and occurrencies (label size)
        unique, occurrencies = np.unique(atlas_masked, return_counts=True)

        # Populate the plot
        for i, label in unique[unique > 0]:
            # Continue with real maps
            label_avg = data_masked[atlas_masked == label].mean()
            plt.plot(occurrencies[i], label_avg, '.', color=COLOURS[j])

    # #!# Adjust legend
    plt.legend(ATLAS_DICT.values())
    plt.tight_layout()

    # Save plot
    plt.savefig(f'{plot_name}_by_voxel.png', dpi=SET_DPI)
    plt.close('all')


if __name__ == '__main__':
    args = _get_parser().parse_args(sys.argv[1:])

    if args.genatlas is True:
        # Check if atlases was already computed
        if args.overwrite is True or check_file(args.wdr, 'atlases.npz') is False:
            atlases = generate_atlas_dictionary(args.wdr, args.scriptdir)
        else:
            print('Atlas already exists')

    elif args.compdist is True:

        atlases = generate_atlas_dictionary(args.wdr, args.scriptdir)
        dist_fname = compute_distances(args.wdr, atlases)

    elif args.gensurr is True:
        atlases = generate_atlas_dictionary(args.wdr, args.scriptdir)
        dist_fname = compute_distances(args.wdr, atlases)
        surrogate_maps, data_masked = generate_surrogates(args.data_fname,
                                                          atlases,
                                                          dist_fname,
                                                          args.null_maps,
                                                          args.wdr)
        plot_parcels(args.null_maps,
                     args.data_content,
                     atlases,
                     surrogate_maps,
                     data_masked,
                     args.plot_name)

    elif args.plotparc is True:
        # Check if surrogates exists, otherwise stop
        surrogate_fname = f'surrogates_{args.data_fname}'
        if check_file(args.wdr, surrogate_fname) is False:
            raise Exception('Cannot find surrogate maps: '
                            f'{surrogate_fname} in '
                            f'{os.path.join(args.wdr, ATLAS_FOLDER)}')
        else:
            atlases = generate_atlas_dictionary(args.wdr, args.scriptdir)
            surrogate_maps = load_file(args.wdr, surrogate_fname)
            # Read and extract data
            data = load_nifti(args.data_fname)
            data_masked = data[atlases['intersect'] > 0]

            plot_parcels(args.null_maps,
                         args.data_content,
                         atlases,
                         surrogate_maps,
                         data_masked,
                         args.plot_name)

    else:
        raise Exception('No workflow flag specified!')
