#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from tqdm import tqdm
import numpy as np
from scipy.integrate import solve_ivp
import h5py

gammas = [0.4, 0.9, 1.5]
t_final = 30
times = np.linspace(0.0, t_final, 1000)

# Grid of initial conditions, recast as an iterable object 'ics'
y0m, y0mx = -10, 10
y1m, y1mx = -6, 6
Y0, Y1 = np.mgrid[y0m:y0mx:10j, y1m:y1mx:10j]
ics = np.vstack([Y0.ravel(), Y1.ravel()]).T

def func(t, y, g):
    y0, y1 = y
    dy0dt = y1 
    dy1dt = -y0 - g * y1
    return np.array([dy0dt, dy1dt])

gammas=[0.1, 0.8, 1.2]

print("Phase Space Plots for Van der Pol Oscillator:")
filename = 'vdp_data.h5'
hf = h5py.File(filename, 'w')

for g in tqdm((gammas)):
#for g in gammas:
    gi_group = hf.create_group('gamma='+str(g))
    for j,p in enumerate(ics):
        soln = solve_ivp(func, (0, t_final), p, t_eval=times, method='RK23',\
                         args=(g,))
        gi_group.create_dataset(str(j),data=soln.y)

print("Data dropped into " + filename)
hf.close()
