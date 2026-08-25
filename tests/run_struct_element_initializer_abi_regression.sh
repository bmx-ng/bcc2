#!/bin/sh
set -eu

compiler_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
compiler="$compiler_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$2" && pwd)
mkdir -p "$3"
output_root=$(CDPATH= cd -- "$3" && pwd)
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
overlay="$output_root/sdk"
module_dir="$overlay/mod/acme.mod/elementinit.mod"
module_build_dir="$module_dir/.bmx"

mkdir -p "$overlay/mod" "$module_build_dir"
[ -e "$overlay/mod/brl.mod" ] || ln -s "$sdk_root/mod/brl.mod" "$overlay/mod/brl.mod"
[ -e "$overlay/mod/pub.mod" ] || ln -s "$sdk_root/mod/pub.mod" "$overlay/mod/pub.mod"

cp "$fixture_dir/compiler_struct_element_initializer_module.bmx" "$module_dir/elementinit.bmx"
module_source="$module_dir/elementinit.bmx"
consumer_source="$fixture_dir/compiler_struct_element_initializer_consumer.bmx"
module_c="$module_build_dir/elementinit.bmx.release.macos.arm64.c"
module_header="$module_build_dir/elementinit.bmx.release.macos.arm64.h"
module_interface="$module_dir/elementinit.release.macos.arm64.i"
consumer_c="$output_root/consumer.c"

"$compiler" --emit-runtime-c --release --platform macos --arch arm64 \
	--module acme.elementinit --sdk "$overlay" -o "$module_c" "$module_source"
"$compiler" --emit-runtime-header --release --platform macos --arch arm64 \
	--module acme.elementinit --sdk "$overlay" -o "$module_header" "$module_source"
"$compiler" --emit-interface --release --platform macos --arch arm64 \
	--module acme.elementinit --sdk "$overlay" -o "$module_interface" "$module_source"
"$compiler" --emit-runtime-c --release --platform macos --arch arm64 \
	--sdk "$overlay" -o "$consumer_c" "$consumer_source"

grep -q 'void bbStructElementInit_acme_elementinit_SElementCell(void \*bmx_value)' "$module_c"
grep -q 'void bbStructElementInit_acme_elementinit_SElementCell(void \*bmx_value);' "$module_header"
grep -q 'bbArrayNewStruct("@SElementCell", sizeof(struct acme_elementinit_SElementCell), bbStructElementInit_acme_elementinit_SElementCell, 2, 2, 3)' "$consumer_c"

cc -std=c99 -Wall -Wextra \
	-I"$overlay/mod" \
	-c "$module_c" \
	-o "$output_root/module.o"
cc -std=c99 -Wall -Wextra \
	-I"$overlay/mod" \
	-c "$consumer_c" \
	-o "$output_root/consumer.o"

cc "$output_root/module.o" \
	"$output_root/consumer.o" \
	"$sdk_root/mod/brl.mod/appstub.mod/appstub.release.macos.arm64.a" \
	"$sdk_root/mod/pub.mod/macos.mod/macos.release.macos.arm64.a" \
	"$sdk_root/mod/brl.mod/blitz.mod/blitz.release.macos.arm64.a" \
	-framework AppKit \
	-framework Foundation \
	-framework CoreServices \
	-o "$output_root/struct-element-initializer-regression"

"$output_root/struct-element-initializer-regression"
