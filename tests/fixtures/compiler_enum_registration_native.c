#include <brl.mod/blitz.mod/blitz.h>

BBINT bcc2_enum_registration_ok(void) {
	return bbEnumGetInfo("EState") != 0 && bbEnumGetInfo("EAccess") != 0;
}
