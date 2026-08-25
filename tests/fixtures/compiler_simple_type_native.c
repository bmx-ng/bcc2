#include <stddef.h>
#include "compiler_simple_type_runtime.h"

BBINT bcc2_native_simple_type_layout(void) {
    int count = 0;
    int found = 0;
    BBClass **classes = bbObjectRegisteredTypes(&count);
    for (int index = 0; index < count; ++index) {
        if (classes[index] == (BBClass *)&bmx_class_cls0_TSimple) {
            found = 1;
            break;
        }
    }
    struct bmx_cls0_TSimple_obj *value = bmx_class_cls0_TSimple.f_cf0_Create(7, 8, 9);
    return found && value &&
        bmx_class_cls0_TSimple.super == &bbObjectClass &&
        bmx_class_cls0_TSimple.instance_size == sizeof(struct bmx_cls0_TSimple_obj) &&
        bmx_class_cls0_TSimple.fields_offset == offsetof(struct bmx_cls0_TSimple_obj, bmx_field_f0_a) &&
        bmx_class_cls0_TSimple.obj_size ==
            offsetof(struct bmx_cls0_TSimple_obj, bmx_field_f2_c) -
            offsetof(struct bmx_cls0_TSimple_obj, bmx_field_f0_a) + sizeof(BBINT) &&
        value->clas == &bmx_class_cls0_TSimple &&
        value->bmx_field_f0_a == 7 && value->bmx_field_f1_b == 8 && value->bmx_field_f2_c == 9 &&
        bmx_class_cls0_TSimple.m_cf1_Sum(value) == 24;
}
