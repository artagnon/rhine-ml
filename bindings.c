#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <string.h>
#include <stdarg.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>

struct value_t {
	int type_tag;
	long int_val;
	bool bool_val;
	char *string_val;
	struct value_t **array_val;
	long array_len;
	double dbl_val;
	struct value_t *(*function_val)(struct value_t *);
	char char_val;
	bool gc_marked;
	struct value_t *gc_next;
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
	case 8:
		printf("(char) %c", v->char_val);
		break;
	default:
		printf("Don't know how to print type %d", v->type_tag);
	}
}

int v_to_atype(struct value_t *v) {
	if (!v)
		return 6;
	switch(v->type_tag) {
	case 1:
		return 0;
	case 2:
		return 1;
	case 3:
		return 2;
	case 4:
		return 3;
	case 6:
		return 4;
	case 8:
		return 5;
	default:
		printf("Don't know how to print type %d", v->type_tag);
		exit(1);
	}
}

value mlbox_value(int atype, struct value_t *v) {
	value int_block = caml_alloc(1, 0);
	value bool_block = caml_alloc(1, 1);
	value string_block = caml_alloc(1, 2);
	value array_block = caml_alloc(1, 3);
	value dbl_block = caml_alloc(1, 4);
	value char_block = caml_alloc(1, 5);
	value dbl_value = caml_alloc(1, Double_tag);
	value array_value = 0;
	int i;
	if (atype == 3)
		array_value = caml_alloc(v->array_len, 0);
	switch(atype) {
	case 0:
		Store_field(int_block, 0, Val_long(v->int_val));
		return int_block;
	case 1:
		Store_field(bool_block, 0, Val_int(!!v->bool_val));
		return bool_block;
	case 2:
		Store_field(string_block, 0, caml_copy_string(v->string_val));
		return string_block;
	case 3:
		for (i = 0; i < v->array_len; i++) {
			struct value_t *el = (v->array_val)[i];
			value v = mlbox_value(v_to_atype(el), el);
			Store_field(array_value, i, v);
		}
		Store_field(array_block, 0, array_value);
		return array_block;
	case 4:
		Store_double_field(dbl_value, 0, v->dbl_val);
		Store_field(dbl_block, 0, dbl_value);
		return dbl_block;
	case 5:
		Store_field(char_block, 0, Val_int(v->char_val));
		return char_block;
	case 6:
		return Val_int(0);
	default:
		printf("Don't know how to box type: %d", atype);
		exit(1);
	}
}

value unbox_value(value ptr_value) {
	CAMLparam1(ptr_value);
	struct value_t *v = (struct value_t *) ptr_value;
	CAMLreturn(mlbox_value(v_to_atype(v), v));
}

void *gc_malloc(size_t nbytes) {
	static struct value_t *gcroot = NULL;

	if (nbytes != sizeof(struct value_t))
		return malloc(nbytes);
	struct value_t *v = malloc(nbytes);
	v->gc_marked = 0;
	v->gc_next = gcroot;
	gcroot = v->gc_next;
	return v;
}

void gc_mark(struct value_t *v) {
	v->gc_marked = 1;
	if (v->type_tag == 4)
		for (int i = 0; i < v->array_len; i++)
			v->array_val[i]->gc_marked = 1;
}

extern struct value_t *print(int nargs, struct value_t **env, ...) {
	struct value_t *ret;
	va_list ap;
	va_start(ap, env);
	struct value_t *v = va_arg(ap, struct value_t *);
	print_atom(v);
	va_end(ap);
	ret = malloc(sizeof(struct value_t));
	ret->int_val = 0;
	ret->type_tag = 1;
	return ret;
}

extern struct value_t *println(int nargs, struct value_t **env, ...) {
	struct value_t *ret;
	va_list ap;
	va_start(ap, env);
	struct value_t *v = va_arg(ap, struct value_t *);
	print_atom(v);
	printf("\n");
	va_end(ap);
	ret = malloc(sizeof(struct value_t));
	ret->int_val = 0;
	ret->type_tag = 1;
	return ret;
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

extern struct value_t *cequ(int nargs, struct value_t **env, ...) {
	struct value_t *ret;
	va_list ap;
	va_start(ap, env);
	struct value_t *v = va_arg(ap, struct value_t *);
	struct value_t *v2 = va_arg(ap, struct value_t *);
	va_end(ap);

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

extern struct value_t *cstrjoin(int nargs, struct value_t **env, ...) {
	struct value_t *ret;
	va_list ap;
	va_start(ap, env);
	struct value_t *v = va_arg(ap, struct value_t *);
	va_end(ap);
	int i = 0;
	ret = malloc(sizeof(struct value_t));
	ret->string_val = malloc(sizeof(char) * (v->array_len+1));
	ret->type_tag = 3;
	ret->array_len = v->array_len;
	while (i < v->array_len) {
		ret->string_val[i] = (v->array_val)[i]->char_val;
		i++;
	}
	*(ret->string_val+i) = '\0';

	return ret;
}
