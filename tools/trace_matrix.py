"""Generate a requirements traceability matrix from pytest markers.

Usage:  python tools/trace_matrix.py

Walks the test files, collects @pytest.mark.req(...) markers, and
prints requirement -> tests coverage, flagging any requirement in
docs/requirements.md with zero tests. This mirrors the "maintain full
traceability between requirements, test cases, and verification
results" responsibility in the job description — mention that you
built one.
"""

from __future__ import annotations

import ast
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def requirements_from_docs() -> list[str]:
    text = (ROOT / "docs" / "requirements.md").read_text()
    return re.findall(r"\*\*(REQ-[A-Z]+-\d+)\*\*", text)


def req_marks(decorator: ast.expr) -> list[str]:
    """Extract IDs from a @pytest.mark.req("...", "...") decorator node."""
    if not isinstance(decorator, ast.Call):
        return []
    func = decorator.func
    if not (isinstance(func, ast.Attribute) and func.attr == "req"):
        return []
    return [a.value for a in decorator.args if isinstance(a, ast.Constant)]


def collect() -> dict[str, list[str]]:
    matrix: dict[str, list[str]] = defaultdict(list)
    for path in sorted((ROOT / "tests").glob("test_*.py")):
        tree = ast.parse(path.read_text())
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef) and node.name.startswith("test"):
                for dec in node.decorator_list:
                    for req in req_marks(dec):
                        matrix[req].append(f"{path.name}::{node.name}")
    return matrix


def main() -> int:
    matrix = collect()
    reqs = requirements_from_docs()
    gaps = []
    print(f"{'Requirement':<14} Tests")
    print("-" * 70)
    for req in reqs:
        tests = matrix.get(req, [])
        if not tests:
            gaps.append(req)
            print(f"{req:<14} *** NO COVERAGE ***")
        for i, t in enumerate(tests):
            print(f"{req if i == 0 else '':<14} {t}")
    unknown = sorted(set(matrix) - set(reqs))
    for req in unknown:
        print(f"{req:<14} (referenced in tests but not in requirements.md!)")
    print("-" * 70)
    print(f"{len(reqs) - len(gaps)}/{len(reqs)} requirements covered.")
    return 1 if gaps or unknown else 0


if __name__ == "__main__":
    sys.exit(main())
