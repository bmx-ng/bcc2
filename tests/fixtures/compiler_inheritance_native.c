#include <stddef.h>
#include "compiler_inheritance_runtime.h"

BBINT bcc2_native_inheritance_layout(void) {
    struct bmx_cls1_TDerived_obj *value =
        (struct bmx_cls1_TDerived_obj *)bbObjectAtomicNew((BBClass *)&bmx_class_cls1_TDerived);
    value->bmx_field_f0_baseValue = 20;
    value->bmx_field_f0_derivedValue = 22;

    struct bmx_cls0_TBase_obj *base = (struct bmx_cls0_TBase_obj *)value;
    return bmx_class_cls1_TDerived.super == (BBClass *)&bmx_class_cls0_TBase &&
        bmx_class_cls1_TDerived.instance_size == sizeof(struct bmx_cls1_TDerived_obj) &&
        bmx_class_cls1_TDerived.fields_offset ==
            offsetof(struct bmx_cls1_TDerived_obj, bmx_field_f0_derivedValue) &&
        bmx_class_cls1_TDerived.obj_size == sizeof(BBINT) &&
        value->clas == &bmx_class_cls1_TDerived &&
        base->clas->m_cf0_Value(base) == 42 &&
        value->clas->m_cf1_Stable((struct bmx_cls0_TBase_obj *)value) == 21 &&
        value->clas->m_cf2_Extra(value) == 24;
}
