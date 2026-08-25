#!/bin/sh
set -eu

reference_bmk=$1
candidate_bmk=$2
output_root=$3
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
fixture="$fixture_dir/compiler_generic_bcc_differential.bmx"
reference="$output_root/bcc-reference"
candidate="$output_root/bcc2-candidate"

mkdir -p "$output_root"
"$reference_bmk" makeapp -a -r -o "$reference" "$fixture"
"$candidate_bmk" makeapp -bcc2 -a -r -o "$candidate" "$fixture"

reference_output=$("$reference" | tr -d '\r')
candidate_output=$("$candidate" | tr -d '\r')
test "$reference_output" = "canonical:10"
test "$candidate_output" = "$reference_output"
echo "bcc/bcc2 canonical generic differential regression passed"
