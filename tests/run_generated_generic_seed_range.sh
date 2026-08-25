#!/bin/sh
set -eu

if [ "$#" -ne 4 ]; then
	echo "usage: $0 <bmk> <output-root> <first-seed> <last-seed>" >&2
	exit 1
fi

bmk=$1
output_root=$2
first_seed=$3
last_seed=$4
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

case "$first_seed" in
	''|*[!0-9]*)
		echo "first seed must be a non-negative integer: $first_seed" >&2
		exit 1
		;;
esac
case "$last_seed" in
	''|*[!0-9]*)
		echo "last seed must be a non-negative integer: $last_seed" >&2
		exit 1
		;;
esac
if [ "$first_seed" -gt "$last_seed" ]; then
	echo "first seed must not be greater than last seed" >&2
	exit 1
fi
if [ -z "$output_root" ] || [ "$output_root" = "/" ]; then
	echo "refusing unsafe output root: '$output_root'" >&2
	exit 1
fi

mkdir -p "$output_root"
seed=$first_seed
while [ "$seed" -le "$last_seed" ]; do
	seed_root="$output_root/seed-$seed"
	echo "=== generated generic seed $seed ($first_seed..$last_seed) ==="
	if ! "$script_dir/run_generated_generic_combinations.sh" "$bmk" "$seed_root" "$seed"; then
		echo "generated generic seed $seed failed; retained under $seed_root" >&2
		exit 1
	fi
	test -d "$seed_root"
	rm -rf -- "$seed_root"
	seed=$((seed + 1))
done

echo "bcc2 generated generic seed range passed: $first_seed..$last_seed"
