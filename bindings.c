#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <string.h>

struct value_t {
	int type_tag;
	long int_val;
	bool bool_val;
	char *string_val;
	struct value_t **array_val;
	long array_len;
	double dbl_val;
};

void print_atom(struct value_t *v) {
	int i;
	if (!v) {
		printf("(nil)");
		return;
	}
	switch(v->type_tag) {
	case 1:
		printf("(int) %ld", v->int_val);
		break;
	case 2:
		printf("(bool) %s", !v->bool_val ? "false" : "true");
		break;
	case 3:
		printf("(string len %ld) %s", v->array_len, v->string_val);
		break;
	case 4:
		printf("(array len %ld) [", v->array_len);
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
	}
}

extern struct value_t *print(struct value_t *v) {
	struct value_t *ret;
	print_atom(v);
	ret = malloc(sizeof(struct value_t));
	ret->int_val = 0;
	ret->type_tag = 1;
	return ret;
}

extern struct value_t *println(struct value_t *v) {
	struct value_t *ret = print(v);
	printf("\n");
	return ret;
}

double get_value(struct value_t *v, int *ret_type) {
	if (v->type_tag == 6) {
		*ret_type = 6;
		return v->dbl_val;
	} else {
		return (double) v->int_val;
	}
}

struct value_t *save_value(double val, int ret_type) {
	struct value_t *ret;
	ret = malloc(sizeof(struct value_t));

	if (ret_type == 6) {
		ret->dbl_val = val;
		ret->type_tag = 6;
	} else if (ret_type == 2) {
		ret->bool_val = (bool) val;
		ret->type_tag = 2;
	} else {
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
	// only makes sense for integers and bools currently
	switch(v->type_tag) {
	case 1:
		if (v->int_val == v2->int_val) {
			ret = save_value(1.0, 2);
		} else {
			ret = save_value(0.0, 2);
		}
		break;
	case 2:
		if (!v->bool_val == !v2->bool_val) {
			ret = save_value(1.0, 2);
		} else {
			ret = save_value(0.0, 2);
		}
		break;
    case 4:
        if (v->array_len == v2->array_len) {
            ret = save_value(1.0, 2);
        } else {
            ret = save_value(0.0, 2);
        }
        break;
    case 3:
        if (v->array_len == v2->array_len && memcmp(v->array_val, v2->array_val, sizeof(char)*v->array_len) == 0) {
            ret = save_value(1.0, 2);
        } else {
            ret = save_value(0.0, 2);
        }
        break;
    }
	return ret;
}

extern struct value_t *cand(struct value_t *v, struct value_t *v2) {
	int ret_type = 0;
	struct value_t *ret;
	if (!(!v->bool_val) && !(!v2->bool_val)) {
		ret = save_value(1.0, 2);
	} else {
		ret = save_value(0.0, 2);
	}
	return ret;
}

extern struct value_t *cor(struct value_t *v, struct value_t *v2) {
	int ret_type = 0;
	struct value_t *ret;
	if (!(!v->bool_val) || !(!v2->bool_val)) {
		ret = save_value(1.0, 2);
	} else {
		ret = save_value(0.0, 2);
	}
	return ret;

}

extern struct value_t *cnot(struct value_t *v) {
	int ret_type = 0;
	struct value_t *ret;
	if (!(!v->bool_val)) {
		ret = save_value(0.0, 2);
	} else {
		ret = save_value(1.0, 2);
	}
	return ret;
}

extern struct value_t *cmod(struct value_t *v, struct value_t *v2) {
	int ret_type = 1;
	int val = v->int_val % v2->int_val;
	struct value_t *ret = save_value(val, ret_type);
	return ret;

}

extern struct value_t *cexponent(struct value_t *v, struct value_t *v2) {
	int ret_type = 0;
	double val = pow(get_value(v, &ret_type),get_value(v2, &ret_type));
	struct value_t *ret = save_value(val, ret_type);
	return ret;
}


extern struct value_t *cstrjoin(struct value_t *v) {
    struct value_t *ret;
    int i = 0;
    ret = malloc(sizeof(struct value_t));
    ret->string_val = malloc(sizeof(char) * (v->array_len+1));
    ret->type_tag = 3;
    ret->array_len = v->array_len;
    while (i < v->array_len) {
        ret->string_val[i] = *((v->array_val)[i]->string_val);
        i++;
    }
    *(ret->string_val+i) = '\0';


    return ret;
}

