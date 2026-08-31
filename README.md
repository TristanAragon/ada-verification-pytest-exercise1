# ada-verification (Repo 4) — Build a Suite From Nothing

An aircraft fuel monitor, originally written in Ada, ported to Python. `tests/` is **empty**. No scaffolding, no TODO stubs, no `pytest.skip` placeholders — you design the entire suite, name every test, choose every technique. That's the difference between this repo and the earlier ones, and it's much closer to what a live interview exercise or a first week on the job actually looks like.

Scenario: legacy avionics Ada is being ported to a new platform. The Ada in `ada_src/` is the correct reference. The Python in `src/fuelmon/` is the port under test, and it **contains defects introduced during translation**. You verify the port against `docs/requirements.md`.

## Setup

```bash
cd ada-verification
pip install pytest pytest-cov
pytest              # collects nothing — that's the starting line
```

## The drill

**1. Read the Ada first** (`ada_src/fuel_monitor.ads`, then `.adb`). Spec before body — the `.ads` gives you the API and the type ranges, which hand you boundary values for free. Comments in both files translate the syntax for a Python reader. Notice what the type system does: `type Litres is range 0 .. 5_000` enforces its own range at runtime, so the Ada body contains no explicit range checks. The Python port has no such mechanism — think about what that implies before you read the port.

**2. Derive your artifacts from `docs/requirements.md`,** choosing the right one per function — you now have three in your toolkit and should pick deliberately rather than defaulting:
- boundary sets where the spec states ranges or thresholds
- a branch map where you need structural coverage of a function
- an MC/DC vector table wherever a requirement states a multi-condition rule
- a state/effect check where a function mutates its inputs

**3. Build the suite.** Everything is yours: file names, test names, `pytest.param` ids, fixtures (a couple of tank-builder fixtures will earn their keep), parametrize tables, `@pytest.mark.req` markers for traceability. Aim for a suite you'd be willing to show an interviewer.

**4. Verify and report.** Run `pytest --cov=fuelmon --cov-branch --cov-report=term-missing` and interrogate every gap using the three-way triage: working check, dead check, or unreachable-through-caller. Run `python tools/trace_matrix.py` and close any requirement with no test. Write a defect note per root cause in `docs/defects.md`, five fields each, evidence before fix.

## What's different here, and why it matters

The Ada reference gives you something the earlier repos didn't: a **known-good implementation to compare against**. That's a real and powerful verification technique — differential testing against a reference oracle — and it changes how you root-cause. When a test fails, you can ask not just "what does the spec say?" but "what did the original do, and what did the translation change?" Porting defects have characteristic shapes: dropped conditions, flipped operators, lost type constraints, and conditions that were `and then` in Ada arriving as something else in Python. Read the two side by side and the diffs will find you.

## Self-check

`docs/SOLUTIONS.md` lists how many defects exist and what each one is. **Don't open it until your suite is complete and your defect notes are written** — the count alone is a spoiler that tells you when to stop looking, and knowing when to stop looking is part of what you're practicing.
