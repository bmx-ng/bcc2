#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/using-debugger-runtime"

mkdir -p "$output_root"
"$bmk_path" makeapp -bcc2 -a -d -t console -o "$application" "$fixture_dir/compiler_using_debugger_runtime.bmx"

output=$("$application" 2>&1 | tr -d '\r')
test "$output" = "7:11:13:1:17:6"

echo "bcc2 Using debugger runtime regression passed"
