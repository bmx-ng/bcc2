#!/bin/sh
set -eu

if [ "$#" -ne 3 ]; then
	echo "usage: $0 <reference-bmk> <candidate-bmk> <output-root>" >&2
	exit 1
fi

reference_bmk=$1
candidate_bmk=$2
output_root=$3
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
fixture="$fixture_dir/compiler_managed_conversion_bcc_differential.bmx"
reference="$output_root/bcc-reference"
candidate="$output_root/bcc2-candidate"

mkdir -p "$output_root"
"$reference_bmk" makeapp -a -r -o "$reference" "$fixture"
"$candidate_bmk" makeapp -bcc2 -a -r -o "$candidate" "$fixture"

reference_output=$("$reference" | tr -d '\r')
candidate_output=$("$candidate" | tr -d '\r')
test "$reference_output" = "0:2:0:2:42:0"
test "$candidate_output" = "$reference_output"
echo "bcc/bcc2 managed-conversion differential regression passed"
