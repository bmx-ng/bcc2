#!/bin/sh
set -eu

if test "$#" -ne 3
then
	echo "usage: $0 <bcc> <sdk-root> <output-root>" >&2
	exit 2
fi

bcc=$1
sdk_root=$2
output_root=$3
fixture_root=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)

mkdir -p "$output_root"
for case_name in embedded_generic_managed_c embedded_generic_struct_literal_c
do
	case_root="$output_root/$case_name"
	"$bcc" --emit-build --sdk "$sdk_root" --platform esp32 --arch riscv32 \
		--single-threaded --no-runtime --release --build-c application.c \
		--build-manifest bcc-build.manifest -o "$case_root" \
		"$fixture_root/$case_name.bmx"
	test -s "$case_root/application.c"
	${CC:-cc} -std=c99 -Wall -Wextra -Werror -Wno-unused-const-variable \
		-fsyntax-only -I "$sdk_root/mod/embedded.mod/runtime.mod/native/include" \
		"$case_root/application.c" "$case_root"/.generics/units/*.c
done

echo "Embedded generic C syntax regression passed"
