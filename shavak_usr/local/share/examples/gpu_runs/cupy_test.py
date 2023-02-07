# Python program to
# demonstrate speed comparison
# between cupy and numpy
 
def matmult_numpy(N):
    import numpy as np
    m1 = np.random.random((N,N))
    m2 = np.random.random((N,N))
    return m1 @ m2

def matmult_cupy(N):
    import cupy as cp
    m1 = cp.random.random((N,N))
    m2 = cp.random.random((N,N))
    return m1 @ m2

def eigvals_numpy(N):
    import numpy as np
    m1 = np.random.random((N,N))
    return np.linalg.eigvalsh(m1+m1.T)

def eigvals_cupy(N):
    import cupy as cp
    m1 = cp.random.random((N,N))
    return cp.linalg.eigvalsh(m1+m1.T)

if __name__ == '__main__':
    from timeit import Timer
    mysetup = 'from __main__ import matmult_numpy, matmult_cupy, eigvals_numpy, eigvals_cupy'
    
    N = 50#00
    defnum = 10

    print(f"Test Numpy Matrix Multiplication, size {N}:")
    o = Timer(setup=mysetup, stmt=f"matmult_numpy({N})")
    print("Running over a loop of %d" % (defnum))
    print("Fastest runtime per execution = ", min(o.repeat(number=defnum)) * 1e6 / defnum, " mus")

    print(f"Test CuPy  Matrix Multiplication, size {N}:")
    o = Timer(setup=mysetup, stmt=f"matmult_cupy({N})")
    print("Running over a loop of %d" % (defnum))
    print("Fastest runtime per execution = ", min(o.repeat(number=defnum)) * 1e6 / defnum, " mus")
    
    N = 50#00
    defnum = 1

    print(f"Test Numpy Matrix Diagonalization, size {N}:")
    o = Timer(setup=mysetup, stmt=f"eigvals_numpy({N})")
    print("Running over a loop of %d" % (defnum))
    print("Fastest runtime per execution = ", min(o.repeat(number=defnum)) * 1e6 / defnum, " mus")

    print(f"Test Cupy Matrix Diagonalization, size {N}:")
    o = Timer(setup=mysetup, stmt=f"eigvals_cupy({N})")
    print("Running over a loop of %d" % (defnum))
    print("Fastest runtime per execution = ", min(o.repeat(number=defnum)) * 1e6 / defnum, " mus")
