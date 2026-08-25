#include "compiler_object_slots_runtime.h"

BBINT bcc2_check_object_slots(void) {
    struct bmx_cls1_TDerived_obj *value =
        (struct bmx_cls1_TDerived_obj *)bbObjectAtomicNew((BBClass *)&bmx_class_cls1_TDerived);
    value->bmx_field_f0_value = 41;

    BBOBJECT object = (BBOBJECT)value;
    return value->clas == &bmx_class_cls1_TDerived &&
        bmx_class_cls1_TDerived.ToString == (BBSTRING (*)(BBOBJECT))bmx_fn5_ToString &&
        bmx_class_cls1_TDerived.Compare == (BBINT (*)(BBOBJECT, BBOBJECT))bmx_fn6_Compare &&
        bmx_class_cls1_TDerived.SendMessage == (BBOBJECT (*)(BBOBJECT, BBOBJECT, BBOBJECT))bmx_fn2_SendMessage &&
        bmx_class_cls1_TDerived.HashCode == (BBUINT (*)(BBOBJECT))bmx_fn3_HashCode &&
        bmx_class_cls1_TDerived.Equals == (BBINT (*)(BBOBJECT, BBOBJECT))bmx_fn4_Equals &&
        value->clas->Compare(object, object) == 42 &&
        value->clas->SendMessage(object, object, (BBOBJECT)&bbNullObject) == object &&
        value->clas->HashCode(object) == 41U &&
        value->clas->Equals(object, object);
}
