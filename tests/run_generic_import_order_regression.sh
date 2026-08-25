#!/bin/sh
set -eu

if test "$#" -ne 2
then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2importordertest.mod"
application="$output_root/generic-import-order"

test ! -e "$output_root"
if test -e "$module_root"
then
	echo "temporary generic import-order module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

run_application()
{
	executable=$application
	if test -f "$application.exe"
	then
		executable="$application.exe"
	fi
	"$executable" | tail -n 1 | tr -d '\r'
}

snapshot_generic_artifacts()
{
	result=$1
	find "$output_root/.bmx/.generics" -name '*.c' -type f -print | LC_ALL=C sort | while IFS= read -r artifact
	do
		relative=${artifact#"$output_root"/}
		set -- $(cksum "$artifact")
		printf '%s %s %s\n' "$relative" "$1" "$2"
	done > "$result"
}

snapshot_generic_manifest_entries()
{
	result=$1
	manifest=$(find "$output_root/.bmx" -maxdepth 1 -name 'app.bmx*.bmxbuild' -type f)
	test -f "$manifest"
	grep -E '^(file generic-specialization-c|link) ' "$manifest" > "$result"
}

build_order()
{
	fixture=$1
	snapshot=$2
	cp "$fixture_dir/$fixture" "$output_root/app.bmx"
	rm -rf "$output_root/.bmx"
	rm -f "$application" "$application.exe"
	"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$output_root/app.bmx"
	test "$(run_application)" = "generic-import-order-ok"
	snapshot_generic_artifacts "$output_root/$snapshot-artifacts.txt"
	snapshot_generic_manifest_entries "$output_root/$snapshot-manifest.txt"
}

mkdir -p "$module_root/core.mod" "$module_root/left.mod" "$module_root/right.mod" "$output_root"
cp "$fixture_dir/module_generic_import_order_core.bmx" "$module_root/core.mod/core.bmx"
cp "$fixture_dir/module_generic_import_order_left.bmx" "$module_root/left.mod/left.bmx"
cp "$fixture_dir/module_generic_import_order_right.bmx" "$module_root/right.mod/right.bmx"

"$bmk" makemods -a -bcc2 -r Bcc2ImportOrderTest.Core
"$bmk" makemods -a -bcc2 -r Bcc2ImportOrderTest.Left
"$bmk" makemods -a -bcc2 -r Bcc2ImportOrderTest.Right

build_order generic_import_order_app_left_first.bmx left-first
build_order generic_import_order_app_right_first.bmx right-first

cmp "$output_root/left-first-artifacts.txt" "$output_root/right-first-artifacts.txt"
cmp "$output_root/left-first-manifest.txt" "$output_root/right-first-manifest.txt"
test "$(wc -l < "$output_root/left-first-artifacts.txt" | tr -d ' ')" -ge 6

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 generic import-order/diamond-graph regression passed"
