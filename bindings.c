#include <stdio.h>
#include <stdlib.h>

struct value_t {
	int type_tag;
	long int_val;
	int bool_val:1;
	char *string_val;
	struct value_t **array_val;
	int array_len;
	double dbl_val;
};

void print_atom(struct value_t *v) {
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
		printf("(array len %d) [", v->array_len);
		for (i = 0; i < v->array_len; i++) {
			struct value_t *el = (v->array_val)[i];
			print_atom(el);
			printf(";");
		}
		printf("]");
		break;
	case 6:
		printf("(double) %f", v->dbl_val);
		break;
	default:
		printf("Don't know how to print type %d", v->type_tag);
		exit(1);
	}
}

extern struct value_t *print(struct value_t *v) {
	struct value_t *ret;
	print_atom(v);
	ret = malloc(sizeof(struct value_t));
	ret->int_val = 5;
	ret->type_tag = 1;
	return ret;
}

extern struct value_t *println(struct value_t *v) {
	struct value_t *ret;
	print_atom(v);
	printf("\n");
	ret = malloc(sizeof(struct value_t));
	ret->int_val = 5;
	ret->type_tag = 1;
	return ret;
}

double get_value(struct value_t *v, int *ret_type) {
    if (v->type_tag == 6) {
        *ret_type = 6;
        return v->dbl_val;
    }
    else {
        return (double) v->int_val;
    }
}

struct value_t *save_value(double val, int ret_type) {
    struct value_t *ret;
    ret = malloc(sizeof(struct value_t));

    if (ret_type == 6) {
        ret->dbl_val = val;
        ret->type_tag = 6;
    }
    else if (ret_type == 2) {
        ret->bool_val = (int)val;
        ret->type_tag = 2;
    }
    else {
        ret->int_val = (int) val;
        ret->type_tag = 1;
    }
    return ret;
}

extern struct value_t *cadd(struct value_t *v, struct value_t *v2) {
    int ret_type = 0;
    double val = get_value(v, &ret_type) + get_value(v2, &ret_type);
    struct value_t *ret = save_value(val, ret_type);
    return ret;
}

extern struct value_t *cdiv(struct value_t *v, struct value_t *v2) {
    int ret_type = 6; // force float
    double val = get_value(v, &ret_type) / get_value(v2, &ret_type);
    struct value_t *ret = save_value(val, ret_type);
    return ret;
}

extern struct value_t *csub(struct value_t *v, struct value_t *v2) {
    int ret_type = 0;
    double val = get_value(v, &ret_type) - get_value(v2, &ret_type);
    struct value_t *ret = save_value(val, ret_type);
    return ret;
}

extern struct value_t *cmul(struct value_t *v, struct value_t *v2) {
    int ret_type = 0;
    double val = get_value(v, &ret_type) * get_value(v2, &ret_type);
    struct value_t *ret = save_value(val, ret_type);
    return ret;
}

extern struct value_t *clt(struct value_t *v, struct value_t *v2) {
    int ret_type = 0;
    struct value_t *ret;
    if (get_value(v, &ret_type) < get_value(v2, &ret_type)) {
        ret = save_value(1.0, 2);
    } else {
        ret = save_value(0.0, 2);
    }
    return ret;
}

extern struct value_t *cgt(struct value_t *v, struct value_t *v2) {
    int ret_type = 0;
    struct value_t *ret;
    if (get_value(v, &ret_type) > get_value(v2, &ret_type)) {
        ret = save_value(1.0, 2);
    } else {
        ret = save_value(0.0, 2);
    }
    return ret;
}

extern struct value_t *clte(struct value_t *v, struct value_t *v2) {
    int ret_type = 0;
    struct value_t *ret;
    if (get_value(v, &ret_type) <= get_value(v2, &ret_type)) {
        ret = save_value(1.0, 2);
    } else {
        ret = save_value(0.0, 2);
    }
    return ret;
}

extern struct value_t *cgte(struct value_t *v, struct value_t *v2) {
    int ret_type = 0;
    struct value_t *ret;
    if (get_value(v, &ret_type) >= get_value(v2, &ret_type)) {
        ret = save_value(1.0, 2);
    } else {
        ret = save_value(0.0, 2);
    }
    return ret;
}

extern struct value_t *cequ(struct value_t *v, struct value_t *v2) {
    int ret_type = 0;
    struct value_t *ret;
    // only makes sense for integers currently
    if (v->int_val == v2->int_val) {
        ret = save_value(1.0, 2);
    } else {
        ret = save_value(0.0, 2);
    }
    return ret;
}







