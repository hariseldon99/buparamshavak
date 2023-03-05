#!/usr/bin/env python
from multiprocessing import Pool
# The multiprocessing python module helps parallelize programs

import sys

"""
Example: python ./square.py 8

Calculates the squares of numbers [0,1,2,3,4,5,6,7] with 8 processes in parallel

"""

def square(x):
    square = x * x
    return square


if __name__ == "__main__":
    N = int(sys.argv[1])
    with Pool(N) as pool:
        a = pool.imap(square, range(0, N))
        pool.close()
        pool.join()
    print([i for i in a])
