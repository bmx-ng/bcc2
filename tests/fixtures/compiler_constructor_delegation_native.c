#include "compiler_constructor_delegation_runtime.h"

static BBINT delegation_trace;

BBINT bcc2_record_constructor_delegation(BBINT value) {
    delegation_trace = delegation_trace * 10 + value;
    return value;
}

BBINT bcc2_check_constructor_delegation(void) {
    return delegation_trace == 45123;
}
