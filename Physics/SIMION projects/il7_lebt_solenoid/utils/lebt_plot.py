#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Fri Oct 26 15:50:57 2018
@author: izpilab, gaudee, ehu
Description: 
    Given a csv with the statisticos of pit30_einzel simulations
    this script prints the best result regarding a cost function based
    on the min span in y and z axes and the beam loss.
    It aslo exports a csv file with the electrodes conifguration and the
    resuts of the cost function.
"""


import numpy as np
import pandas as pd
import re
from matplotlib import pyplot as plt

''' USER DEFINED PARAMS'''

FILENAME = "../stats/stats_stack_40000parts.csv"

''' END OF USER DEFINED PARAMS'''

def get_list_of_cols_by_name_pattern (df,colpattern):
    ''' '''
    regex = re.compile(colpattern) # Create a wildcard for matching
    # get a list of the items that contain "colpattern*" in stats columns
    return [string for string in list(df) if re.match(regex, string)]

def get_min_of_cols_by_name_pattern (df,colpattern):
    ''' '''
    min_list = get_list_of_cols_by_name_pattern (df,colpattern)
    # get the min of all columns
    return stats.loc[:,min_list].min(axis = 1)

def get_max_of_cols_by_name_pattern (df,colpattern):
    ''' '''
    max_list = get_list_of_cols_by_name_pattern (df,colpattern)
    # get the min of all columns
    return stats.loc[:,max_list].max(axis = 1)

# Read the csv into a pandas dataframe
#stats = pd.read_csv ('stats_raw.csv', delimiter=',', encoding="utf-8-sig")
stats = pd.read_csv (FILENAME)

'''
************* Update the dataframe with the necessary columns *************
'''
 
stats_15k = stats[stats['extractevolt(V)'] == 15000]
stats_15k_18_5A = stats_15k[stats_15k['sol1ITotal(A)'] == 18500]
stats_16k = stats[stats['extractevolt(V)'] == 16000]
stats_16k_18_5A = stats_16k[stats_16k['sol1ITotal(A)'] == 18500]
stats_15k_20A = stats_15k[stats_15k['sol1ITotal(A)'] == 20000]
stats_16k_20A = stats_16k[stats_16k['sol1ITotal(A)'] == 20000]

fig, (ax1, ax2) = plt.subplots(nrows=2, ncols=4)
ax1[0].set_xlabel('sol2I (A)')
ax1[0].set_ylabel('#parts in FC')
ax1[0].plot(stats_15k_18_5A['sol2I (A)'],stats_15k_18_5A['#parts in FC'])
ax1[1].set_xlabel('sol2I (A)')
ax1[1].set_ylabel('pep1_vel_rms_y')
ax1[1].plot(stats_15k_18_5A['sol2I (A)'],stats_15k_18_5A['pep1_vel_rms_y'])
# ax1[1].set_xlabel('sol1I (A)')
# ax1[1].set_ylabel('pep1_norm_emitt_y (mm*mrad)')
# ax1[1].plot(stats_15k['sol1I (A)'],stats_15k['pep1_norm_emitt_y (mm*mrad)'])
# ax1[2].set_xlabel('sol1I (A)')
# ax1[2].set_ylabel('lebt_norm_emitt_y (mm*mrad)')
# ax1[2].plot(stats_16k['sol1I (A)'],stats_16k['lebt_norm_emitt_y (mm*mrad)'])
# ax1[3].set_xlabel('sol1I (A)')
# ax1[3].set_ylabel('pep1_norm_emitt_y (mm*mrad)')
# ax1[3].plot(stats_16k['sol1I (A)'],stats_16k['pep1_norm_emitt_y (mm*mrad)'])
ax1[2].set_xlabel('sol2I (A)')
ax1[2].set_ylabel('#parts in FC')
ax1[2].plot(stats_16k_18_5A['sol2I (A)'],stats_16k_18_5A['#parts in FC'])
ax1[3].set_xlabel('sol2I (A)')
ax1[3].set_ylabel('pep1_vel_rms_y')
ax1[3].plot(stats_16k_18_5A['sol2I (A)'],stats_16k_18_5A['pep1_vel_rms_y'])
# ax2[0].set_xlabel('sol1I (A)')
# ax2[0].set_ylabel('lebt_vel_rms_y')
# ax2[0].plot(stats_15k['sol1I (A)'],stats_15k['lebt_vel_rms_y'])
# ax2[1].set_xlabel('sol1I (A)')
# ax2[1].set_ylabel('pep1_vel_rms_y')
# ax2[1].plot(stats_15k['sol1I (A)'],stats_15k['pep1_vel_rms_y'])
# ax2[2].set_xlabel('sol1I (A)')
# ax2[2].set_ylabel('lebt_vel_rms_y')
# ax2[2].plot(stats_16k['sol1I (A)'],stats_16k['lebt_vel_rms_y'])
# ax2[3].set_xlabel('sol1I (A)')
# ax2[3].set_ylabel('pep1_vel_rms_y')
# ax2[3].plot(stats_16k['sol1I (A)'],stats_16k['pep1_vel_rms_y'])
ax2[0].set_xlabel('sol2I (A)')
ax2[0].set_ylabel('#parts in FC')
ax2[0].plot(stats_15k_20A['sol2I (A)'],stats_15k_20A['#parts in FC'])
ax2[1].set_xlabel('sol2I (A)')
ax2[1].set_ylabel('pep1_vel_rms_y')
ax2[1].plot(stats_15k_20A['sol2I (A)'],stats_15k_20A['pep1_vel_rms_y'])
ax2[2].set_xlabel('sol2I (A)')
ax2[2].set_ylabel('#parts in FC')
ax2[2].plot(stats_16k_20A['sol2I (A)'],stats_16k_20A['#parts in FC'])
ax2[3].set_xlabel('sol2I (A)')
ax2[3].set_ylabel('pep1_vel_rms_y')
ax2[3].plot(stats_16k_20A['sol2I (A)'],stats_16k_20A['pep1_vel_rms_y'])

plt.show ()


