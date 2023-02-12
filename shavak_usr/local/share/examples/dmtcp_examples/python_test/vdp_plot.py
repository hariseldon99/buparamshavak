#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import h5py
import matplotlib.pyplot as plt
plt.rcParams['figure.figsize'] = (8,6)
plt.rcParams['font.size'] = 20

#filename = 'vdp_data.h5'
filename = sys.argv[1]
plot_filename = "vdp_phaseplots.png"
hf = h5py.File(filename, 'r')

gammas = hf.keys()
plt.rcParams['figure.figsize'] = (len(gammas)*6,6)
for i, (name,group) in enumerate(hf.items()):
    plt.subplot(1,len(gammas),i+1)
    g = float(name.split("=")[-1])
    plt.title(f"Phase Space for g={g:1.1f}")
    plt.xlabel('x')
    plt.ylabel('dxdt', rotation=0)
    
    for dataset in group.items():
        y = dataset[-1][:]    
        plt.plot(y[0], y[1], "b-")
hf.close()
plt.savefig(plot_filename)
print("Data plotted from " + filename + " into file " + plot_filename)
