#!/bin/sh
set -eu

if test "$#" -ne 2
then
	echo "usage: $0 <bcc> <output-root>" >&2
	exit 2
fi

compiler=$1
output_root=$2
sdk_root=${BCC2_TEST_SDK:-$(CDPATH= cd -- "$(dirname -- "$compiler")/.." && pwd)}
test ! -e "$output_root"
mkdir -p "$output_root/sdk/mod/brl.mod/blitz.mod" \
	"$output_root/sdk/mod/fixture.mod/core.mod"
cp "$sdk_root/mod/brl.mod/blitz.mod/blitz_classes.i" \
	"$output_root/sdk/mod/brl.mod/blitz.mod/blitz_classes.i"

cat > "$output_root/sdk/mod/fixture.mod/core.mod/core.bmx" <<'EOF'
SuperStrict
Module Fixture.Core
Function Magic:Int()
	Return 7
End Function
EOF
cat > "$output_root/client.bmx" <<'EOF'
SuperStrict
Module Fixture.Client
Import Fixture.Core
Function Probe:Int()
	Return Magic()
End Function
EOF

"$compiler" --emit-interface --sdk "$output_root/sdk" --module fixture.core \
	--platform esp32 --arch riscv32 --single-threaded --embedded-multicore \
	--no-runtime --release \
	-o "$output_root/sdk/mod/fixture.mod/core.mod/core.release.gcmc.esp32.riscv32.i" \
	"$output_root/sdk/mod/fixture.mod/core.mod/core.bmx"

"$compiler" --emit-build --sdk "$output_root/sdk" \
	--platform esp32 --arch riscv32 --single-threaded --embedded-multicore \
	--module fixture.client --source-unit client.bmx --no-runtime --release \
	--build-c module.c --build-manifest bcc-build.manifest \
	--build-interface module.i -o "$output_root/multicore" "$output_root/client.bmx"
test -s "$output_root/multicore/module.c"
test -s "$output_root/multicore/module.i"

if "$compiler" --emit-build --sdk "$output_root/sdk" \
	--platform esp32 --arch riscv32 --single-threaded \
	--module fixture.client --source-unit client.bmx --no-runtime --release \
	--build-c module.c --build-manifest bcc-build.manifest \
	--build-interface module.i -o "$output_root/single" "$output_root/client.bmx" \
	> "$output_root/single.log" 2>&1
then
	echo "Single-core compilation unexpectedly used the multicore interface" >&2
	exit 1
fi
grep -q "BMX4003.*Fixture.Core" "$output_root/single.log"

echo "Embedded multicore interface isolation regression passed"
