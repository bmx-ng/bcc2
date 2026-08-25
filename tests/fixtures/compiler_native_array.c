#include <brl.mod/blitz.mod/blitz.h>
#include <stdlib.h>
#include <string.h>

BBARRAY bcc2_native_array = &bbEmptyArray;

BBINT bcc2_native_array_sum(BBARRAY values) {
	if (values == &bbEmptyArray || values->dims != 1 || values->scales[0] != 2 || strcmp(values->type, "i") != 0) {
		abort();
	}
	BBINT *data = (BBINT *)BBARRAYDATA(values, 1);
	if (data[0] != 20 || data[1] != 22) {
		abort();
	}
	return data[0] + data[1];
}
