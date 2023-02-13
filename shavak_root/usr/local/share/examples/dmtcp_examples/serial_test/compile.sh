#!/bin/bash
gcc -Wall -O3 gsl_eigenrand.c -lgsl -lgslcblas -lopenblas -o gsl_eigenrand
