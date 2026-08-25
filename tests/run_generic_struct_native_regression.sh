#!/bin/sh
set -eu

specialization_tests=$1
sdk_root=$2
output_root=$3
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)

mkdir -p "$output_root"
"$specialization_tests" --emit-wide-struct-build "$output_root"

specialization_units=$(find "$output_root/.generics" -name '*.c' -type f | sort)
set -- $specialization_units
[ "$#" -eq 1 ]
specialization_c=$1

grep -q '#include "../../wide-struct.h"' "$specialization_c"
grep -q 'BBDEBUGSCOPE_USERSTRUCT' "$specialization_c"
grep -q 'bbObjectRegisterStruct' "$specialization_c"
grep -q 'struct bmx_direct_swidepoint_' "$output_root/wide-struct.h"

cc -std=c11 -Wall -Wextra -Werror \
	-I"$sdk_root/mod" \
	-c "$specialization_c" \
	-o "$output_root/wide-struct-specialization.o"

cc -std=c11 -Wall -Wextra -Werror \
	-I"$sdk_root/mod" \
	-c "$output_root/wide-struct.c" \
	-o "$output_root/wide-struct.o"

cc -std=c11 -Wall -Wextra -Werror \
	-I"$sdk_root/mod" \
	-I"$output_root" \
	-c "$fixture_dir/generic_struct_reflection_probe.c" \
	-o "$output_root/generic-struct-reflection-probe.o"

cc "$output_root/wide-struct.o" \
	"$output_root/wide-struct-specialization.o" \
	"$output_root/generic-struct-reflection-probe.o" \
	"$sdk_root/mod/brl.mod/appstub.mod/appstub.release.macos.arm64.a" \
	"$sdk_root/mod/pub.mod/macos.mod/macos.release.macos.arm64.a" \
	"$sdk_root/mod/brl.mod/blitz.mod/blitz.release.macos.arm64.a" \
	-framework AppKit \
	-framework Foundation \
	-framework CoreServices \
	-o "$output_root/generic-struct-native-regression"

"$output_root/generic-struct-native-regression"
