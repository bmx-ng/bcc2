#include "compiler_lifecycle_runtime.h"

static BBINT delete_trace;

void bcc2_record_delete(BBINT value) {
    delete_trace = delete_trace * 10 + value;
}

BBINT bcc2_check_lifecycle(void) {
    struct bmx_cls1_TDerived_obj *value =
        (struct bmx_cls1_TDerived_obj *)bbObjectAtomicNewNC((BBClass *)&bmx_class_cls1_TDerived);
    bmx_fn2_New(value, 20, 22);

    BBINT valid = value->clas == &bmx_class_cls1_TDerived &&
        value->bmx_field_f0_baseValue == 20 &&
        value->bmx_field_f0_derivedValue == 22 &&
        bmx_class_cls0_TBase.dtor == (void (*)(BBOBJECT))bmx_fn1_Delete &&
        bmx_class_cls1_TDerived.dtor == (void (*)(BBOBJECT))bmx_fn3_Delete;

    bmx_class_cls1_TDerived.dtor((BBOBJECT)value);
    return valid && delete_trace == 21;
}
