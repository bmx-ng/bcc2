#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
source_path="$fixture_dir/compiler_generic_struct_operator_runtime.bmx"

mkdir -p "$output_root"
for threading in default explicit-threaded
do
	for mode in debug release
	do
		application="$output_root/generic-struct-operator-$threading-$mode"
		if [ "$threading" = default ]; then
			if [ "$mode" = release ]; then
				"$bmk_path" makeapp -a -bcc2 -single -r -o "$application" "$source_path"
			else
				"$bmk_path" makeapp -a -bcc2 -single -o "$application" "$source_path"
			fi
		else
			if [ "$mode" = release ]; then
				"$bmk_path" makeapp -a -bcc2 -single -h -r -o "$application" "$source_path"
			else
				"$bmk_path" makeapp -a -bcc2 -single -h -o "$application" "$source_path"
			fi
		fi
		executable=$application
		test ! -f "$application.exe" || executable="$application.exe"
		result=$("$executable" | tr -d '\r\n')
		test "$result" = "generic Struct operator runtime passed"
	done
done

echo "generic Struct operator runtime regression passed"
