///usr/bin/env -S gcc -std=c99 -Wall -ldl -o demo "$0" -o /tmp/demo && exec /tmp/demo "$@"

#include <dlfcn.h>
#include <gnu/lib-names.h>
#include <stdio.h>
#include <stdlib.h>

int main(void) {
  FILE *out = fopen("/dev/null", "w");
  for (;;) {
    void *handle;
    double (*cosine)(double);
    char *error;
    double cos1, cos2;

    handle = dlopen(LIBM_SO, RTLD_LAZY);
    if (!handle) {
      fprintf(stderr, "%s\n", dlerror());
      exit(EXIT_FAILURE);
    }

    dlerror();

    cosine = (double (*)(double))dlsym(handle, "cos");
    error = dlerror();
    if (error != NULL) {
      fprintf(stderr, "%s\n", error);
      exit(EXIT_FAILURE);
    }

    cos1 = cosine(2.0);
    cos2 = cosine(cos1);

    fprintf(out, "%f\n", cos2);
    dlclose(handle);
  }
}
