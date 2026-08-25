#include "compiler_field_initializers_runtime.h"

static BBINT initializer_trace;

BBINT bcc2_record_field_initializer(BBINT value) {
    initializer_trace = initializer_trace * 10 + value;
    return value;
}

BBINT bcc2_check_field_initializers(void) {
    return initializer_trace == 123456123;
}
