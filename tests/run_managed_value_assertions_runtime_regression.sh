#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/compiler-managed-value-assertions"

mkdir -p "$output_root"
"$bmk" makeapp -bcc2 -single -a -o "$application" "$fixture_dir/compiler_managed_value_assertions_runtime.bmx"

executable=$application
test ! -f "$application.exe" || executable="$application.exe"
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "managed-value-assertions-ok"
echo "bcc2 managed-value debug assertions runtime regression passed"
