///usr/bin/env -S gcc -gdwarf-4 -fno-omit-frame-pointer -ldl -o demo "$0" -o /tmp/demo && exec /tmp/demo "$@"

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

    fprintf(out, "%f\n", (*cosine)(2.0));
    dlclose(handle);
  }
}
