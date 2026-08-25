#!/bin/sh
set -eu

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2arraysboundarytest.mod"

if test -e "$module_root"
then
	echo "temporary Arrays-boundary test module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

mkdir -p "$output_root" "$module_root/functions.mod"
cp "$fixture_dir/module_arrays_boundary_functions.bmx" "$module_root/functions.mod/functions.bmx"
"$bmk" makemods -a -bcc2 BRL.Arrays
"$bmk" makemods -a -bcc2 Bcc2ArraysBoundaryTest.Functions
cp "$fixture_dir/module_arrays_boundary_app.bmx" "$output_root/app.bmx"

debug_application="$output_root/arrays-boundary-debug"
"$bmk" makeapp -a -bcc2 -single -o "$debug_application" "$output_root/app.bmx"
test "$("$debug_application" | tail -n 1 | tr -d '\r')" = "arrays-module-boundary-ok"

release_application="$output_root/arrays-boundary-release"
"$bmk" makeapp -a -bcc2 -single -r -o "$release_application" "$output_root/app.bmx"
test "$("$release_application" | tail -n 1 | tr -d '\r')" = "arrays-module-boundary-ok"

consumer_c=$(find "$output_root/.bmx" -maxdepth 1 -name 'app.bmx.console.release.*.c' -type f)
test -f "$consumer_c"
grep -q 'bcc2arraysboundarytest_functions_ArraysBoundaryDouble' "$consumer_c"
grep -q 'bcc2arraysboundarytest_functions_ArraysBoundaryShift' "$consumer_c"
grep -q 'brl_arrays' "$consumer_c"

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 BRL.Arrays module-boundary regression passed"
