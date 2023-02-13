#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
from tqdm import tqdm
import numpy as np
from scipy.integrate import solve_ivp
import h5py
from multiprocessing.pool import Pool
nprocs = int(sys.argv[1])
gammas = [0.4, 0.9, 1.5]
t_final = 30
times = np.linspace(0.0, t_final, 1000)

# Grid of initial conditions, recast as an iterable object 'ics'
y0m, y0mx = -10, 10
y1m, y1mx = -6, 6
Y0, Y1 = np.mgrid[y0m:y0mx:22j, y1m:y1mx:22j]
ics = np.vstack([Y0.ravel(), Y1.ravel()]).T

chunk = int(len(ics)/nprocs)

def func(t, y, g):
    y0, y1 = y
    dy0dt = y1 
    dy1dt = -y0 - g * y1
    return np.array([dy0dt, dy1dt])

def evolve_vdp(g, ic):
    return solve_ivp(func, (0, t_final), ic, t_eval=times, method='RK23',\
                     args=(g,))

gammas=[0.1, 0.8, 1.2]

print("Phase Space Plots for Van der Pol Oscillator:")
filename = 'vdp_data.h5'
hf = h5py.File(filename, 'w')

for g in tqdm((gammas)):
    gi_group = hf.create_group('gamma='+str(g))
    with Pool(nprocs) as pool:
        inputs = [(g, ic) for ic in ics]
        sols = pool.starmap(evolve_vdp, inputs, chunksize=chunk)
        for j, soln in enumerate(sols):
            gi_group.create_dataset(str(j),data=soln.y)

print("Data dropped into " + filename)
hf.close()
