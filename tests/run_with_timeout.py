#!/usr/bin/env python3
"""Run one generated test executable with a bounded wall-clock duration."""

from __future__ import annotations

import os
import signal
import subprocess
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <seconds> <executable>", file=sys.stderr)
        return 2
    try:
        timeout = float(sys.argv[1])
    except ValueError:
        print(f"invalid timeout: {sys.argv[1]}", file=sys.stderr)
        return 2
    if timeout <= 0:
        print(f"timeout must be positive: {sys.argv[1]}", file=sys.stderr)
        return 2
    try:
        process = subprocess.Popen(
            [sys.argv[2]],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        try:
            output, _ = process.communicate(timeout=1)
        except subprocess.TimeoutExpired as error:
            # A corrupted runtime can become uninterruptible inside the OS.
            # Do not let waiting to reap that process defeat the corpus timeout.
            output = error.output or b""
        if output:
            sys.stdout.buffer.write(output)
        print(f"generated application timed out after {timeout:g} seconds", file=sys.stderr)
        return 124
    sys.stdout.buffer.write(output)
    return process.returncode


if __name__ == "__main__":
    raise SystemExit(main())
