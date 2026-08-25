#include "blitz.h"

BBOBJECT bcc2_managed_null_object(void) {
    return 0;
}

BBARRAY bcc2_managed_wrong_array(void) {
    return (BBARRAY)&bbNullObject;
}

BBSTRING bcc2_managed_wrong_string(void) {
    return (BBSTRING)&bbNullObject;
}
