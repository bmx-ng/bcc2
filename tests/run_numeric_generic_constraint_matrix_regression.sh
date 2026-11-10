#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk=$1
output_root=$2
test_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mkdir -p "$output_root"

"$bmk" makeapp -a -r -h -o "$output_root/constraint-matrix" "$test_dir/test_numeric_generic_constraint_matrix.bmx"
"$output_root/constraint-matrix"
"$test_dir/run_numeric_generic_constraint_runtime_regression.sh" "$bmk" "$output_root/runtime"
"$test_dir/run_numeric_generic_constraint_module_regression.sh" "$bmk" "$output_root/module"

echo "numeric generic constraint matrix regression passed"
