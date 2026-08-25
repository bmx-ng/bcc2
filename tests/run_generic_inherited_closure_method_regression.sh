#!/bin/sh
set -eu

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2genericinheritedmethod.mod"

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
	echo "temporary generic inherited-Method test module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

mkdir -p "$output_root/source" "$output_root/module" "$module_root/types.mod"

source_debug="$output_root/source/generic-inherited-method-debug"
"$bmk" makeapp -a -bcc2 -single -o "$source_debug" "$fixture_dir/compiler_generic_inherited_closure_method_runtime.bmx"
test "$(run_application "$source_debug")" = "generic-inherited-closure-method-ok"

source_release="$output_root/source/generic-inherited-method-release"
"$bmk" makeapp -a -bcc2 -single -r -o "$source_release" "$fixture_dir/compiler_generic_inherited_closure_method_runtime.bmx"
test "$(run_application "$source_release")" = "generic-inherited-closure-method-ok"

cp "$fixture_dir/module_generic_inherited_closure_method_types.bmx" "$module_root/types.mod/types.bmx"
"$bmk" makemods -a -bcc2 Bcc2GenericInheritedMethod.Types
"$bmk" makemods -a -bcc2 -r Bcc2GenericInheritedMethod.Types

cp "$fixture_dir/module_generic_inherited_closure_method_app.bmx" "$output_root/module/app.bmx"
module_debug="$output_root/module/generic-inherited-method-debug"
"$bmk" makeapp -a -bcc2 -single -o "$module_debug" "$output_root/module/app.bmx"
test "$(run_application "$module_debug")" = "generic-inherited-closure-method-module-ok"

module_release="$output_root/module/generic-inherited-method-release"
"$bmk" makeapp -a -bcc2 -single -r -o "$module_release" "$output_root/module/app.bmx"
test "$(run_application "$module_release")" = "generic-inherited-closure-method-module-ok"

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 generic inherited Method prototype regression passed"
