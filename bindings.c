#include <stdio.h>
#include <stdlib.h>

struct value_t {
	int type_tag;
	long int_val;
	int bool_val:1;
	char *string_val;
	struct value_t *array_val;
	int array_len;
};

extern struct value_t *print(struct value_t *v) {
	struct value_t *ret;
    int i;
	switch(v->type_tag) {
	case 1:
		printf("(int) %ld", v->int_val);
		break;
	case 2:
		printf("(bool) %s", !v->bool_val ? "false" : "true");
		break;
	case 3:
		printf("(string) %s", v->string_val);
		break;
	case 4:
		printf("(array) [");
        for (i = 0; i < 10; i++) {
            // only integer arrays for now
		    printf("%ld", (v->array_val+i)->int_val);
        }
		printf("]");
		break;
	default:
		printf("Don't know how to print type %d", v->type_tag);
		exit(1);
	}
	ret = malloc(sizeof(struct value_t));
	ret->int_val = 5;
    ret->type_tag = 1;
	return ret;
}


extern struct value_t *println(struct value_t *v) {
	struct value_t *ret = print(v);
    printf("\n");
    return ret;
}

