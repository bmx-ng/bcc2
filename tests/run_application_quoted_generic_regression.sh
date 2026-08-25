#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/application-quoted-generic"

mkdir -p "$output_root"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_application_quoted_generic_main.bmx"

executable=$application
if test -x "$application.exe"
then
	executable="$application.exe"
fi

result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "application-quoted-generic-ok"

generic_unit=$(find "$fixture_dir/.bmx/.generics" -name '*.c' -type f -exec grep -l '#include <\.bmx/compiler_application_quoted_generic_types\.bmx\.' {} \; | head -n 1)
test -n "$generic_unit"
if grep -q '#include <application\.mod/' "$generic_unit"
then
	echo "quoted-source generic unit used a synthetic module header" >&2
	exit 1
fi

echo "bcc2 application quoted-source generic regression passed"
