#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/reflection-debugger-interactive"

mkdir -p "$output_root"
"$bmk_path" makeapp -a -d -h -t console -o "$application" "$fixture_dir/compiler_reflection_debugger_runtime.bmx"

output=$(printf 't\nr\n' | "$application" 2>&1 | tr -d '\r')

printf '%s\n' "$output" | grep -q '^~>Function _Invoke$'
printf '%s\n' "$output" | grep -q '^~>Local reflectionWrapper:'
printf '%s\n' "$output" | grep -q '^~>Local buf:Byte Ptr\[\]='
printf '%s\n' "$output" | grep -q '^~>Local bufPtr:Byte Ptr Ptr='
printf '%s\n' "$output" | grep -q '^~>Local rawPointer:Byte Ptr Ptr='
printf '%s\n' "$output" | grep -q '^~>Local callback:Int(Int)='
printf '%s\n' "$output" | grep -q '^~>Local callbacks:Int(Int)\[\]='
printf '%s\n' "$output" | grep -q '^~>Local closureValue:Closure<Int(Int)>='
printf '%s\n' "$output" | grep -q '^~>Local fixed:Int\[4\]='
printf '%s\n' "$output" | grep -q '^~>Local record:SReflectionDebugValue='
printf '%s\n' "$output" | grep -q '^~>Local iface:IReflectionDebugValue='
printf '%s\n' "$output" | grep -q '^~>Local state:EReflectionDebugState='
if printf '%s\n' "$output" | grep -q 'Debugger Error:'; then
	printf '%s\n' "$output" >&2
	exit 1
fi

echo "bcc2 reflected interactive debugger regression passed"
