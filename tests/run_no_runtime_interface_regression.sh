#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
compiler="${BCC2_TEST_COMPILER:-$repo_root/../BlitzMax-pico/bin/bcc}"
sdk="${BCC2_TEST_SDK:-$repo_root/../BlitzMax-pico}"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

cat > "$work_dir/pico_fixture.bmx" <<'BMX'
SuperStrict
Module Pico.Test.Fixture

Extern "C"
	Function FixtureValue:UInt() = "bmx_pico_fixture_value"
End Extern
BMX

"$compiler" \
	--emit-interface \
	--no-runtime \
	--sdk "$sdk" \
	--module pico.test.fixture \
	--platform pico \
	--arch arm \
	--release \
	--single-threaded \
	-o "$work_dir/pico_fixture.release.pico.arm.i" \
	"$work_dir/pico_fixture.bmx"

test -s "$work_dir/pico_fixture.release.pico.arm.i"
grep -q 'bmx_pico_fixture_value' "$work_dir/pico_fixture.release.pico.arm.i"
