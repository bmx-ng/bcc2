#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
bmk_dir=$(CDPATH= cd -- "$(dirname -- "$bmk")" && pwd)
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
module_root="$sdk_root/mod/bcc2genericcoverage.mod"

if test -e "$module_root"; then
	echo "temporary generic coverage module already exists: $module_root" >&2
	exit 1
fi
trap 'rm -rf "$module_root"' 0 HUP INT TERM
mkdir -p "$output_root/include" "$output_root/import" "$output_root/module" "$module_root/owner.mod"
cp "$fixture_dir/generic_pointer_method_boundary_provider.bmx" "$output_root/include/"
cp "$fixture_dir/generic_pointer_method_boundary_provider.bmx" "$output_root/import/"
cp "$fixture_dir/generic_pointer_method_boundary_consumer.bmx" "$output_root/include/"
cp "$fixture_dir/generic_pointer_method_boundary_consumer.bmx" "$output_root/import/"
cp "$fixture_dir/generic_pointer_method_boundary_consumer.bmx" "$output_root/module/"
cp "$fixture_dir/generic_pointer_method_boundary_include_app.bmx" "$output_root/include/app.bmx"
cp "$fixture_dir/generic_pointer_method_boundary_import_app.bmx" "$output_root/import/app.bmx"
cp "$fixture_dir/generic_pointer_method_boundary_module_app.bmx" "$output_root/module/app.bmx"
cp "$fixture_dir/generic_pointer_method_boundary_module_owner.bmx" "$module_root/owner.mod/owner.bmx"

"$bmk" makemods -a -bcc2 -r Bcc2GenericCoverage.Owner
test -n "$(find "$module_root/owner.mod/.generics/templates" -name '*.bmxgt' -type f -print -quit)"

for configuration in debug release; do
	for boundary in include import module; do
		application="$output_root/$boundary/$boundary-$configuration"
		if test "$configuration" = release; then
			"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$output_root/$boundary/app.bmx"
		else
			"$bmk" makeapp -a -bcc2 -single -o "$application" "$output_root/$boundary/app.bmx"
		fi
		test "$("$application" | tail -n 1 | tr -d '\r')" = generic-pointer-method-boundary-ok
	done
done

echo "bcc2 generic pointer, Method, and Interface source-boundary regression passed"
