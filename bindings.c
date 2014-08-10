#include <stdio.h>
#include <stdlib.h>

struct value_t {
	int type;
	long int_val;
	int bool_val:1;
	char *string_val;
	struct value_t *array_val;
};

extern struct value_t *println(struct value_t *v) {
	struct value_t *ret;
	printf("Hello! %ld\n", v->int_val);
	ret = malloc(sizeof(struct value_t));
	ret->int_val = 5;
	return ret;
}

