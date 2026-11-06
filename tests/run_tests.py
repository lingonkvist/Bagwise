#!/usr/bin/env python3
"""Run Bagwise Lua tests via lupa (Lua 5.1 from Python)."""

import sys
import os
from pathlib import Path

try:
    from lupa.lua51 import LuaRuntime
except ImportError:
    from lupa import LuaRuntime

def main():
    project_root = Path(__file__).resolve().parent.parent
    os.chdir(project_root)

    lua = LuaRuntime(unpack_returned_tuples=True)

    # Load mini test harness
    harness = (project_root / "tests" / "mini_test.lua").read_text()
    lua.execute(harness)

    # Run each spec file
    spec_files = sorted(project_root.glob("tests/*_spec.lua"))
    for spec in spec_files:
        print(f"\n=== {spec.name} ===")
        code = spec.read_text()
        try:
            lua.execute(code)
        except Exception as e:
            print(f"  ERROR loading {spec.name}: {e}")

    # Report
    failed = lua.eval("mini_test_report()")
    sys.exit(1 if failed and failed > 0 else 0)


if __name__ == "__main__":
    main()
