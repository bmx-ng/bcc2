#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#include "wide-struct.h"

static BBINT reflection_failure(void) {
	abort();
	return 0;
}

BBINT validate_wide_struct_reflection(void) {
	BBDebugScope *scope = bbObjectStructInfo("TWideValue<string>");
	if (!scope || scope->kind != BBDEBUGSCOPE_USERSTRUCT) return reflection_failure();
	if (strcmp(scope->name, "TWideValue<string>") != 0) return reflection_failure();

	int field_count = 0;
	int global_count = 0;
	int method_count = 0;
	int callable_method_count = 0;
	size_t previous_offset = 0;
	for (BBDebugDecl *decl = scope->decls; ; ++decl) {
		if (decl->kind == BBDEBUGDECL_END) {
			if (field_count != 9 || global_count != 1 || method_count != 3 ||
					callable_method_count != 1 || decl->struct_size <= previous_offset) return reflection_failure();
			return 1;
		}
		if (decl->kind == BBDEBUGDECL_GLOBAL) {
			if (!decl->name || strcmp(decl->name, "staticCount") != 0 ||
					!decl->type_tag || !decl->var_address ||
					*(BBINT *)decl->var_address != 4 || decl->reflection_wrapper) return reflection_failure();
			++global_count;
			continue;
		}
		if (decl->kind == BBDEBUGDECL_FIELD) {
			if (!decl->name || !decl->type_tag) return reflection_failure();
			if (field_count && decl->field_offset < previous_offset) return reflection_failure();
			previous_offset = decl->field_offset;
			++field_count;
			continue;
		}
		if (decl->kind == BBDEBUGDECL_TYPEMETHOD) {
			if (!decl->func_ptr || !decl->name || !decl->type_tag) return reflection_failure();
			if (strcmp(decl->name, "Apply") == 0) {
				if (decl->reflection_wrapper) return reflection_failure();
				++callable_method_count;
			} else if (!decl->reflection_wrapper) {
				return reflection_failure();
			}
			++method_count;
			continue;
		}
		return reflection_failure();
	}
}
