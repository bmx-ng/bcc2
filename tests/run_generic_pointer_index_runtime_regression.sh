#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
mkdir -p "$output_root"
cp "$fixture_dir/compiler_generic_pointer_index_runtime.bmx" "$output_root/app.bmx"

for configuration in debug release
do
	application="$output_root/generic-pointer-index-$configuration"
	if [ "$configuration" = release ]; then
		"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$output_root/app.bmx"
	else
		"$bmk" makeapp -a -bcc2 -single -o "$application" "$output_root/app.bmx"
	fi
	test "$("$application" | tail -n 1 | tr -d '\r')" = "generic-pointer-index-ok"
	unit_dir="$output_root/.bmx/.generics/units"
	test -d "$unit_dir"
	if test "$configuration" = debug; then
		grep -RFql 'bmx_generic_debug_pointer_element((void *)' "$unit_dir"
	else
		grep -RFql '((BBINT *)(' "$unit_dir"
	fi
done

cp "$fixture_dir/compiler_generic_pointer_index_debug_failure.bmx" "$output_root/null-pointer.bmx"
"$bmk" makeapp -a -bcc2 -single -o "$output_root/null-pointer" "$output_root/null-pointer.bmx"
"$output_root/null-pointer" > "$output_root/null-pointer.out" 2>&1 || true
grep -Fq 'Attempt to access null pointer' "$output_root/null-pointer.out"

echo "bcc2 generic raw pointer indexing regression passed"
