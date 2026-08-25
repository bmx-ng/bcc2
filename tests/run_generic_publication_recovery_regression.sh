#!/bin/sh
set -eu

if test "$#" -ne 2
then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
source_path="$output_root/app.bmx"
application="$output_root/generic-publication-recovery"

test ! -e "$output_root"
mkdir -p "$output_root"
cp "$fixture_dir/compiler_generic_composition_matrix_runtime.bmx" "$source_path"

run_application()
{
	executable=$application
	if test -f "$application.exe"
	then
		executable="$application.exe"
	fi
	"$executable" | tail -n 1 | tr -d '\r'
}

# Force several independent compiler engines and native drivers to publish the
# same generated sources, specialization objects, sidecars and executable.
# Every writer must use a private temporary path and an atomic final publish.
for ordinal in 1 2 3 4
do
	(
		if "$bmk" makeapp -a -bcc2 -single -r -o "$application" "$source_path" > "$output_root/concurrent-$ordinal.txt" 2>&1
		then
			printf '0\n' > "$output_root/concurrent-$ordinal.status"
		else
			printf '1\n' > "$output_root/concurrent-$ordinal.status"
		fi
	) &
done
wait

for ordinal in 1 2 3 4
do
	if test "$(cat "$output_root/concurrent-$ordinal.status")" -ne 0
	then
		cat "$output_root/concurrent-$ordinal.txt" >&2
		echo "concurrent generic publisher $ordinal failed" >&2
		exit 1
	fi
done
test "$(run_application)" = "generic-composition-matrix-runtime-ok"

manifest=$(find "$output_root/.bmx" -maxdepth 1 -name 'app*.bmxbuild' -type f)
test -f "$manifest"
specialization_object=$(find "$output_root/.bmx/.generics/objects" -name '*.o' -type f | head -n 1)
test -f "$specialization_object"
specialization_key="$specialization_object.bcc2key"
test -f "$specialization_key"

# A process terminated between object and sidecar publication leaves either
# member missing. Both shapes must trigger exactly one specialization repair.
rm "$specialization_object"
missing_object_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$source_path")
test "$(printf '%s' "$missing_object_output" | grep -c 'Compiling generic specialization')" -eq 1
test -f "$specialization_object"
test -f "$specialization_key"

printf 'partial-key' > "$specialization_key"
partial_key_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$source_path")
test "$(printf '%s' "$partial_key_output" | grep -c 'Compiling generic specialization')" -eq 1
test -f "$specialization_object"
test "$(wc -l < "$specialization_key" | tr -d ' ')" -eq 2

# Generated source and manifest publication is atomic for new writers, but bmk
# also repairs an older partial artifact instead of accepting or reusing it.
object_name=$(basename -- "$specialization_object")
specialization_c=$(find "$output_root/.bmx/.generics" -name "${object_name%.o}.c" -type f)
test -f "$specialization_c"
specialization_checksum=$(cksum "$specialization_c")
printf 'partial-c' > "$specialization_c"
"$bmk" makeapp -bcc2 -single -r -o "$application" "$source_path"
test "$(cksum "$specialization_c")" = "$specialization_checksum"

manifest_checksum=$(cksum "$manifest")
printf 'BMXBUILD 1\nfile' > "$manifest"
"$bmk" makeapp -bcc2 -single -r -o "$application" "$source_path"
test "$(cksum "$manifest")" = "$manifest_checksum"
test "$(run_application)" = "generic-composition-matrix-runtime-ok"

test -z "$(find "$output_root" -type f \( -name '*.bmk-tmp-*' -o -name '*.bcc2-tmp-*' \) -print)"

echo "bcc2 generic concurrent publication and recovery regression passed"
