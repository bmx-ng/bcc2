#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/polymorphic-recursive-generic"

mkdir -p "$output_root"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_polymorphic_recursive_generic_runtime.bmx"

executable=$application
if test -x "$application.exe"
then
	executable="$application.exe"
fi

result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "polymorphic-recursive-generic-ok"

echo "bcc2 polymorphic-recursive generic runtime regression passed"
