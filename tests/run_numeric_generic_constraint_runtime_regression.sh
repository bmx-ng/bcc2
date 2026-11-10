#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
mkdir -p "$output_root"

run_case()
{
	name=$1
	source=$2
	expected=$3
	application="$output_root/$name"
	"$bmk" makeapp -a -r -o "$application" "$fixture_dir/$source"
	result=$("$application" | tail -n 1 | tr -d '\r')
	test "$result" = "$expected"
}

run_case numeric-runtime numeric_generic_constraint_runtime.bmx numeric-generic-constraint-runtime-ok
run_case numeric-include numeric_generic_include_app.bmx numeric-generic-include-ok
run_case numeric-quoted numeric_generic_quoted_app.bmx numeric-generic-quoted-ok
echo "numeric generic constraint runtime regression passed"
