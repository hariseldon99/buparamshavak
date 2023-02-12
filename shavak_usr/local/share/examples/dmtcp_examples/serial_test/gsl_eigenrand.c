#include <stdio.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_eigen.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>

int main(void) {
  // Set the size of the matrix
  size_t N = 800;

  // Allocate memory for the matrix
  gsl_matrix *A = gsl_matrix_alloc(N, N);

  // Set up a random number generator
  const gsl_rng_type *T;
  gsl_rng *r;
  gsl_rng_env_setup();
  T = gsl_rng_default;
  r = gsl_rng_alloc(T);

  // Fill the matrix with random numbers
  for (size_t i = 0; i < N; i++) {
    for (size_t j = 0; j < N; j++) {
      gsl_matrix_set(A, i, j, gsl_ran_gaussian(r, 1.0));
    }
  }

  // Allocate memory for the eigenvectors and eigenvalues
  gsl_vector *eval = gsl_vector_alloc(N);
  gsl_matrix *evec = gsl_matrix_alloc(N, N);

  // Compute the eigenvalues and eigenvectors of the matrix
  gsl_eigen_symmv_workspace *w = gsl_eigen_symmv_alloc(N);
  gsl_eigen_symmv(A, eval, evec, w);
  gsl_eigen_symmv_free(w);

  // Sort the eigenvalues and eigenvectors
  gsl_eigen_symmv_sort(eval, evec, GSL_EIGEN_SORT_VAL_ASC);

  // Print the first 5 eigenvalues
  printf("First 5 eigenvalues:\n");
  for (size_t i = 0; i < 5; i++) {
    printf("%g\n", gsl_vector_get(eval, i));
  }

  // Clean up
  gsl_matrix_free(A);
  gsl_vector_free(eval);
  gsl_matrix_free(evec);
  gsl_rng_free(r);

  return 0;
}
