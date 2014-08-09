#include <stdio.h>

struct value_t {
	int int_val;
	int bool_val:1;
	char *string_val;
	int *vector_val;
	struct value_t *array_val;
};

extern int hi (struct value_t *v) {
  printf("Hello! %x", v->int_val);
  return 5;
}

