#include <brl.mod/blitz.mod/blitz.h>
#include <stdlib.h>

BBSTRING bcc2_native_string = &bbEmptyString;

BBINT bcc2_native_string_length(BBSTRING value) {
	if (value->length != 6 || value->buf[0] != 'n' || value->buf[5] != 'e') {
		abort();
	}
	return value->length;
}
