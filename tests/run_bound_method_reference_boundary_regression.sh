#!/bin/sh
set -eu

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2boundmethodboundary.mod"

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
	echo "temporary bound-Method boundary test module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

mkdir -p "$output_root/file" "$output_root/module" "$module_root/types.mod"

cp "$fixture_dir/bound_method_boundary_file_types.bmx" "$output_root/file/"
cp "$fixture_dir/bound_method_boundary_file_app.bmx" "$output_root/file/app.bmx"
file_debug="$output_root/file/bound-method-file-debug"
"$bmk" makeapp -a -bcc2 -single -o "$file_debug" "$output_root/file/app.bmx"
test "$(run_application "$file_debug")" = "bound-method-file-boundary-ok"
file_release="$output_root/file/bound-method-file-release"
"$bmk" makeapp -a -bcc2 -single -r -o "$file_release" "$output_root/file/app.bmx"
test "$(run_application "$file_release")" = "bound-method-file-boundary-ok"

cp "$fixture_dir/module_bound_method_boundary_types.bmx" "$module_root/types.mod/types.bmx"
"$bmk" makemods -a -bcc2 Bcc2BoundMethodBoundary.Types
"$bmk" makemods -a -bcc2 -r Bcc2BoundMethodBoundary.Types
module_interface=$(find "$module_root/types.mod" -maxdepth 1 -name 'types.release.*.i' -type f)
test -f "$module_interface"
grep -q 'BindModuleReceiver' "$module_interface"
grep -q 'BindModuleBox<T>' "$module_interface"

cp "$fixture_dir/module_bound_method_boundary_app.bmx" "$output_root/module/app.bmx"
module_debug="$output_root/module/bound-method-module-debug"
"$bmk" makeapp -a -bcc2 -single -o "$module_debug" "$output_root/module/app.bmx"
test "$(run_application "$module_debug")" = "bound-method-module-boundary-ok"
module_release="$output_root/module/bound-method-module-release"
"$bmk" makeapp -a -bcc2 -single -r -o "$module_release" "$output_root/module/app.bmx"
test "$(run_application "$module_release")" = "bound-method-module-boundary-ok"

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 bound Method reference file/module boundary regression passed"
