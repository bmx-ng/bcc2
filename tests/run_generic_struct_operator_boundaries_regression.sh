#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2genericstructoperatortest.mod"

if test -e "$module_root"; then
	echo "temporary generic Struct operator test module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

run_application()
{
	application=$1
	expected=$2
	executable=$application
	test ! -f "$application.exe" || executable="$application.exe"
	result=$("$executable" | tr -d '\r\n')
	test "$result" = "$expected"
}

build_application()
{
	source=$1
	application=$2
	threading=$3
	mode=$4
	if [ "$threading" = default ]; then
		if [ "$mode" = release ]; then
			"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$source"
		else
			"$bmk" makeapp -a -bcc2 -single -o "$application" "$source"
		fi
	else
		if [ "$mode" = release ]; then
			"$bmk" makeapp -a -bcc2 -single -h -r -o "$application" "$source"
		else
			"$bmk" makeapp -a -bcc2 -single -h -o "$application" "$source"
		fi
	fi
}

build_module()
{
	threading=$1
	mode=$2
	if [ "$threading" = default ]; then
		if [ "$mode" = release ]; then
			"$bmk" makemods -a -bcc2 -single -r Bcc2GenericStructOperatorTest.Provider
		else
			"$bmk" makemods -a -bcc2 -single Bcc2GenericStructOperatorTest.Provider
		fi
	else
		if [ "$mode" = release ]; then
			"$bmk" makemods -a -bcc2 -single -h -r Bcc2GenericStructOperatorTest.Provider
		else
			"$bmk" makemods -a -bcc2 -single -h Bcc2GenericStructOperatorTest.Provider
		fi
	fi
}

mkdir -p "$output_root/import" "$output_root/include" "$output_root/module" "$module_root/provider.mod"
cp "$fixture_dir/compiler_generic_struct_operator_boundary_provider.bmx" "$output_root/import/"
cp "$fixture_dir/compiler_generic_struct_operator_import_app.bmx" "$output_root/import/app.bmx"
cp "$fixture_dir/compiler_generic_struct_operator_boundary_provider.bmx" "$output_root/include/"
cp "$fixture_dir/compiler_generic_struct_operator_include_app.bmx" "$output_root/include/app.bmx"
cp "$fixture_dir/module_generic_struct_operator_provider.bmx" "$module_root/provider.mod/provider.bmx"
cp "$fixture_dir/module_generic_struct_operator_app.bmx" "$output_root/module/app.bmx"

for threading in default explicit-threaded
do
	for mode in debug release
	do
		import_application="$output_root/import/generic-struct-operator-import-$threading-$mode"
		build_application "$output_root/import/app.bmx" "$import_application" "$threading" "$mode"
		run_application "$import_application" "generic Struct operator quoted Import passed"

		include_application="$output_root/include/generic-struct-operator-include-$threading-$mode"
		build_application "$output_root/include/app.bmx" "$include_application" "$threading" "$mode"
		run_application "$include_application" "generic Struct operator Include passed"

		build_module "$threading" "$mode"
		module_application="$output_root/module/generic-struct-operator-module-$threading-$mode"
		build_application "$output_root/module/app.bmx" "$module_application" "$threading" "$mode"
		run_application "$module_application" "generic Struct operator module passed"
	done
done

template_count=$(find "$module_root/provider.mod/.generics/templates" -name '*.bmxgt' -type f | wc -l | tr -d ' ')
test "$template_count" -ge 1

cleanup_module
trap - 0 HUP INT TERM

echo "generic Struct operator source-boundary regression passed"
