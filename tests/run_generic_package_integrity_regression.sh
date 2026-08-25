#!/bin/sh
set -eu

if test "$#" -ne 2
then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
compiler="$bmk_dir/bcc"
if test -f "$bmk_dir/bcc.exe"
then
	compiler="$bmk_dir/bcc.exe"
fi
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2packageintegritytest.mod"
module_dir="$module_root/owner.mod"
application="$output_root/generic-package-integrity"
direct_root="$output_root/direct"

test ! -e "$output_root"
if test -e "$module_root"
then
	echo "temporary generic package-integrity module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

run_application()
{
	executable=$application
	if test -f "$application.exe"
	then
		executable="$application.exe"
	fi
	"$executable" | tail -n 1 | tr -d '\r'
}

compile_direct_expect_failure()
{
	expected=$1
	label=$2
	rm -rf "$direct_root"
	mkdir -p "$direct_root"
	if "$compiler" --emit-build --release --single-threaded --app-type console \
		--framework brl.standardio --sdk "$sdk_root" -o "$direct_root" \
		--build-c application.c --build-manifest application.bmxbuild \
		"$output_root/app.bmx" > "$output_root/$label.txt" 2>&1
	then
		echo "$label unexpectedly compiled" >&2
		exit 1
	fi
	grep -Eq "$expected" "$output_root/$label.txt"
	if grep -qi 'internal compiler error' "$output_root/$label.txt"
	then
		echo "$label produced an internal compiler error" >&2
		exit 1
	fi
	test ! -f "$direct_root/application.bmxbuild"
}

mkdir -p "$module_dir" "$output_root"
cp "$fixture_dir/module_generic_package_integrity_owner.bmx" "$module_dir/owner.bmx"
cp "$fixture_dir/generic_package_integrity_app.bmx" "$output_root/app.bmx"

"$bmk" makemods -a -bcc2 -r Bcc2PackageIntegrityTest.Owner
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$output_root/app.bmx"
test "$(run_application)" = "generic-package-integrity-ok"

template=$(find "$module_dir/.generics/templates" -name '*.bmxgt' -type f | LC_ALL=C sort | head -n 1)
test -f "$template"
cp "$template" "$output_root/original.bmxgt"

rm "$template"
compile_direct_expect_failure 'BMX4011' missing-template
cp "$output_root/original.bmxgt" "$template"

printf '\ntampered-package-payload\n' >> "$template"
compile_direct_expect_failure 'BMXGT105' corrupt-template
cp "$output_root/original.bmxgt" "$template"

{
	printf 'BMXGT 999\n'
	sed '1d' "$output_root/original.bmxgt"
} > "$template"
compile_direct_expect_failure 'BMXGT103' future-template-version
cp "$output_root/original.bmxgt" "$template"

printf 'truncated\n' > "$template"
compile_direct_expect_failure 'BMXGT103' truncated-template

# A forced provider rebuild must atomically restore its canonical package.
"$bmk" makemods -a -bcc2 -r Bcc2PackageIntegrityTest.Owner
cmp "$output_root/original.bmxgt" "$template"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$output_root/app.bmx"
test "$(run_application)" = "generic-package-integrity-ok"

manifest=$(find "$module_dir" -maxdepth 1 -name 'owner.release.*.bmxbuild' -type f)
generic_c=$(find "$module_dir/.generics" -name '*.c' -type f | LC_ALL=C sort | head -n 1)
test -f "$manifest"
test -f "$generic_c"
cp "$manifest" "$output_root/original.bmxbuild"
cp "$generic_c" "$output_root/original-generic.c"

printf '\ntampered-native-output\n' >> "$generic_c"
repair_output=$("$bmk" makemods -bcc2 -r Bcc2PackageIntegrityTest.Owner)
printf '%s' "$repair_output" | grep -q 'Processing:owner.bmx'
cmp "$output_root/original-generic.c" "$generic_c"
cmp "$output_root/original.bmxbuild" "$manifest"

rm "$generic_c"
repair_output=$("$bmk" makemods -bcc2 -r Bcc2PackageIntegrityTest.Owner)
printf '%s' "$repair_output" | grep -q 'Processing:owner.bmx'
cmp "$output_root/original-generic.c" "$generic_c"
cmp "$output_root/original.bmxbuild" "$manifest"

printf 'BMXBUILD 1\ntruncated\n' > "$manifest"
repair_output=$("$bmk" makemods -bcc2 -r Bcc2PackageIntegrityTest.Owner)
printf '%s' "$repair_output" | grep -q 'Processing:owner.bmx'
cmp "$output_root/original.bmxbuild" "$manifest"
test "$(run_application)" = "generic-package-integrity-ok"

printf 'BMXBUILD 999\n' > "$manifest"
repair_output=$("$bmk" makemods -bcc2 -r Bcc2PackageIntegrityTest.Owner)
printf '%s' "$repair_output" | grep -q 'Processing:owner.bmx'
cmp "$output_root/original.bmxbuild" "$manifest"
test "$(run_application)" = "generic-package-integrity-ok"

convergence_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$output_root/app.bmx")
if printf '%s' "$convergence_output" | grep -Eq 'Processing:|Compiling generic specialization|Compiling:'
then
	printf '%s\n' "$convergence_output" >&2
	echo "package repair recompiled its unchanged consumer" >&2
	exit 1
fi
printf '%s' "$convergence_output" | grep -q 'Linking:generic-package-integrity'
test "$(run_application)" = "generic-package-integrity-ok"

quiet_output=$("$bmk" makeapp -bcc2 -single -r -o "$application" "$output_root/app.bmx")
if printf '%s' "$quiet_output" | grep -Eq 'Processing:|Compiling generic specialization|Compiling:|Linking:'
then
	printf '%s\n' "$quiet_output" >&2
	echo "repaired package was not quiet on the following build" >&2
	exit 1
fi

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 generic package-integrity regression passed"
