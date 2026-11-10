#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
source_file="$fixture_dir/compiler_generic_string_operations_runtime.bmx"
expected='root|tail|2|114|alue|1'

mkdir -p "$output_root"

for configuration in debug release
do
	application="$output_root/generic-string-operations-$configuration"
	if [ "$configuration" = release ]; then
		"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$source_file"
	else
		"$bmk" makeapp -a -bcc2 -single -o "$application" "$source_file"
	fi
	actual=$("$application" | tr -d '\r\n')
	if [ "$actual" != "$expected" ]; then
		echo "$configuration generic String operations produced '$actual', expected '$expected'" >&2
		exit 1
	fi
done

echo "bcc2 generic String operations runtime regression passed"
