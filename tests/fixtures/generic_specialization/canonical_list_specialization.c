#include "canonical_list.h"

struct bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_obj {
    BBClass *clas;
    BBSTRING value;
};

static struct bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_obj storage[2];
static int next_storage;

struct bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_obj *
bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_Create(BBSTRING value) {
    struct bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_obj *result =
        &storage[next_storage++];
    result->clas = 0;
    result->value = value;
    return result;
}

BBSTRING
bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_First(
    struct bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_obj *self) {
    return self->value;
}
