#!/bin/sh
set -eu

if test "$#" -ne 2
then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)

test ! -e "$output_root"
mkdir -p "$output_root"
cp "$fixture_dir/generic_inherited_constructor_provider.bmx" "$output_root/generic_inherited_constructor_provider.bmx"
cp "$fixture_dir/generic_inherited_constructor_app.bmx" "$output_root/app.bmx"

application="$output_root/application"
log="$output_root/build.txt"
if ! "$bmk" makeapp -a -bcc2 -single -r -o "$application" "$output_root/app.bmx" >"$log" 2>&1
then
	echo "generic inherited-constructor regression failed to compile; log: $log" >&2
	exit 1
fi

executable=$application
test ! -f "$application.exe" || executable="$application.exe"
result=$("$executable" | tail -n 1 | tr -d '\r')
if test "$result" != "generic-inherited-constructor-ok"
then
	echo "generic inherited-constructor regression produced '$result'; retained under $output_root" >&2
	exit 1
fi

echo "bcc2 generic inherited-constructor regression passed"
