#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/eachin-debugger-line"

mkdir -p "$output_root"
"$bmk_path" makeapp -bcc2 -a -d -h -t console -o "$application" "$fixture_dir/compiler_eachin_debugger_line_runtime.bmx"

output=$(printf 't\nr\n' | "$application" 2>&1 | tr -d '\r')

printf '%s\n' "$output" | grep -q '^~>Unhandled Exception:Attempt to index array element beyond array length$'
printf '%s\n' "$output" | grep -q '^~>StackTrace{$'
printf '%s\n' "$output" | grep -q '/compiler_eachin_debugger_line_runtime.bmx<17,.*>$'
if printf '%s\n' "$output" | grep -q '/compiler_eachin_debugger_line_runtime.bmx<15,'; then
	echo "debugger reported the EachIn header instead of its failing body statement" >&2
	exit 1
fi

echo "bcc2 EachIn debugger line regression passed"
