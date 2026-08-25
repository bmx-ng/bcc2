#!/bin/sh
set -eu

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2compositiontest.mod"

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
	echo "temporary composition-test module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

mkdir -p "$output_root/imported" "$output_root/module" "$module_root/owner.mod"
cp "$fixture_dir/compiler_generic_composition_imported.bmx" "$output_root/imported/"
cp "$fixture_dir/compiler_generic_composition_import_app.bmx" "$output_root/imported/"
import_application="$output_root/imported/generic-composition-import"
"$bmk" makeapp -a -bcc2 -single -r -o "$import_application" "$output_root/imported/compiler_generic_composition_import_app.bmx"
test "$(run_application "$import_application")" = "generic-composition-import-ok"

cp "$fixture_dir/module_generic_composition_owner.bmx" "$module_root/owner.mod/owner.bmx"
"$bmk" makemods -a -bcc2 -r Bcc2CompositionTest.Owner
module_interface=$(find "$module_root/owner.mod" -maxdepth 1 -name 'owner.release.*.i' -type f)
test -f "$module_interface"
grep -q 'TModulePipeline<T>' "$module_interface"
grep -q 'ModuleDeferred<T>:Closure<T()>' "$module_interface"
template_count=$(find "$module_root/owner.mod/.generics/templates" -name '*.bmxgt' -type f | wc -l | tr -d ' ')
test "$template_count" -ge 4

# The provider source remains present for bmk's module/archive discovery, but
# the consumer compiler snapshot resolves the module through this compact
# interface and its canonical template companions.
cp "$fixture_dir/module_generic_composition_app.bmx" "$output_root/module/app.bmx"
module_application="$output_root/module/generic-composition-module"
"$bmk" makeapp -a -bcc2 -single -r -o "$module_application" "$output_root/module/app.bmx"
test "$(run_application "$module_application")" = "generic-composition-module-ok"

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 generic composition source-boundary matrix passed"
