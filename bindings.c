#include <stdio.h>
#include <stdlib.h>

struct value_t {
	int type_tag;
	long int_val;
	int bool_val:1;
	char *string_val;
	struct value_t *array_val;
};

extern struct value_t *println(struct value_t *v) {
	struct value_t *ret;
	switch(v->type_tag) {
	case 1:
		printf("(int) %ld\n", v->int_val);
		break;
	case 2:
		printf("(bool) %s\n", !v->bool_val ? "false" : "true");
		break;
	case 3:
		printf("(string) %s\n", v->string_val);
		break;
	default:
		printf("Don't know how to print type %d\n", v->type_tag);
		exit(1);
	}
	ret = malloc(sizeof(struct value_t));
	ret->int_val = 5;
	return ret;
}

