#!/bin/sh
set -eu

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2identitytest.mod"

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
	echo "temporary identity-test module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

include_root="$output_root/include"
mkdir -p "$include_root/shared" "$include_root/left" "$include_root/right"
cp "$fixture_dir/generic_identity_include_app.bmx" "$include_root/app.bmx"
cp "$fixture_dir/generic_identity_include_owner.bmx" "$include_root/shared/owner.bmx"
cp "$fixture_dir/generic_identity_include_left.bmx" "$include_root/left/consumer.bmx"
cp "$fixture_dir/generic_identity_include_right.bmx" "$include_root/right/consumer.bmx"
include_application="$include_root/generic-include-identity"
"$bmk" makeapp -a -bcc2 -single -r -o "$include_application" "$include_root/app.bmx"
test "$(run_application "$include_application")" = "generic-include-identity-ok"
include_second_output=$("$bmk" makeapp -bcc2 -single -r -o "$include_application" "$include_root/app.bmx")
if printf '%s' "$include_second_output" | grep -Eq 'Processing:app|Compiling generic specialization|Compiling:app|Linking:generic-include-identity'
then
	echo "unchanged included generic application was rebuilt" >&2
	exit 1
fi

mkdir -p "$module_root/left.mod" "$module_root/right.mod"
cp "$fixture_dir/module_generic_identity_left.bmx" "$module_root/left.mod/left.bmx"
cp "$fixture_dir/module_generic_identity_right.bmx" "$module_root/right.mod/right.bmx"
"$bmk" makemods -a -bcc2 -r Bcc2IdentityTest.Left
"$bmk" makemods -a -bcc2 -r Bcc2IdentityTest.Right

module_app_source="$output_root/module-app.bmx"
cp "$fixture_dir/module_generic_identity_app.bmx" "$module_app_source"
module_application="$output_root/generic-module-identity"
"$bmk" makeapp -a -bcc2 -single -r -o "$module_application" "$module_app_source"
test "$(run_application "$module_application")" = "generic-module-identity-ok"

left_object=$(find "$module_root/left.mod/.generics/objects" -name '*.o' -type f)
right_object=$(find "$module_root/right.mod/.generics/objects" -name '*.o' -type f)
test -n "$left_object"
test -n "$right_object"
test "$(basename -- "$left_object")" != "$(basename -- "$right_object")"

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 generic identity/ownership regression passed"
