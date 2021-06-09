#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Fri Oct 26 15:50:57 2018
@author: izpilab, gaudee, ehu
Description: 
    Given a csv the particles position and velocities, graph pos vs vel
"""


import numpy as np
import pandas as pd
import sys
from matplotlib import pyplot as plt

if __name__ == "__main__":
  if len(sys.argv) == 2:
    filename = sys.argv[1]
  else:
    sys.exit("Filename required.")


''' USER DEFINED PARAMS'''
radius = 2 
endpos = 900

''' END OF USER DEFINED PARAMS'''

data = pd.read_csv (filename, skiprows=1)

# remove particles that don't reach the end
data = data[ data[' endposx (mm)'] > endpos ]
 
# Plot pos and vel
fig, ax1 = plt.subplots(nrows=1, ncols=2)
ax1[0].set_xlabel('y (mm)')
ax1[0].set_ylabel('z (mm)')
ax1[0].scatter(data[' endposy (mm)'],data[' endposz (mm)'], s = 0.2)
ax1[1].set_xlabel('y (mm)')
ax1[1].set_ylabel('vel y (mm/msec)')
ax1[1].scatter(data[' endposy (mm)'],data[' endvely (mm/usec)'], s = 0.2)

plt.show ()


