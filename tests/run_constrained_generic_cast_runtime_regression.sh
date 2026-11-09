#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
source_path="$fixture_dir/compiler_constrained_generic_cast_runtime.bmx"

mkdir -p "$output_root"
for mode in debug release
do
	application="$output_root/constrained-cast-$mode"
	if [ "$mode" = release ]; then
		"$bmk_path" makeapp -bcc2 -single -r -o "$application" "$source_path"
	else
		"$bmk_path" makeapp -bcc2 -single -o "$application" "$source_path"
	fi
	executable=$application
	test ! -f "$application.exe" || executable="$application.exe"
	result=$("$executable" | tr -d '\r\n')
	test "$result" = "constrained generic casts passed"
done

echo "constrained generic cast runtime regression passed"
