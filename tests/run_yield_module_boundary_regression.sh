#!/bin/sh
set -eu

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2yieldboundary.mod"

run_application()
{
	application=$1
	executable=$application
	if test -f "$application.exe"
	then
		executable="$application.exe"
	fi
	"$executable" | tail -n 1 | tr -d '\r'
}

if test -e "$module_root"
then
	echo "temporary Yield boundary test module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

mkdir -p "$output_root" "$module_root/values.mod"
cp "$fixture_dir/module_yield_boundary_values.bmx" "$module_root/values.mod/values.bmx"

"$bmk" makemods -a -bcc2 Bcc2YieldBoundary.Values
"$bmk" makemods -a -bcc2 -r Bcc2YieldBoundary.Values

module_interface=$(find "$module_root/values.mod" -maxdepth 1 -name 'values.release.*.i' -type f)
test -f "$module_interface"
grep -q 'Words' "$module_interface"
grep -q 'Once<T>' "$module_interface"
grep -q 'StaticValues<T>' "$module_interface"
grep -q 'NestedDelegated<T>' "$module_interface"

debug_application="$output_root/yield-module-debug"
"$bmk" makeapp -a -bcc2 -o "$debug_application" "$fixture_dir/module_yield_boundary_app.bmx"
test "$(run_application "$debug_application")" = "yield-module-boundary-ok"

release_application="$output_root/yield-module-release"
"$bmk" makeapp -a -bcc2 -r -o "$release_application" "$fixture_dir/module_yield_boundary_app.bmx"
test "$(run_application "$release_application")" = "yield-module-boundary-ok"

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 Yield module-boundary regression passed"
