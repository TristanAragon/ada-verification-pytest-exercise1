# SOLUTIONS — ada-verification

**Stop.** Open this only after your suite is written, run, and your defect notes are drafted. The defect count is itself a spoiler.

---

Five defects were introduced in the Python port. Each is a characteristic *porting* defect — compare the Ada in `ada_src/fuel_monitor.adb` against `src/fuelmon/monitor.py` line by line and every one becomes visible.

## 1. `usable_quantity` drops the sensor check (REQ-FUEL-003)

Ada: `if T.Isolated or else not T.Sensor_Ok then return 0;`
Python: `if tank.isolated: return 0`

A whole condition vanished in translation. A tank with a failed sensor reports its untrusted quantity as usable. Evidence: `usable_quantity(Tank(capacity=1000, quantity=800, sensor_ok=False))` returns 800, spec requires 0. Fix: restore the disjunct. Class: **dropped condition** — the most common porting defect, and one that requirements-based testing finds instantly while a code-only reading of the port never would (nothing in the Python looks wrong; the wrongness is what's absent).

## 2. `alert_for` WARNING boundary off-by-one (REQ-FUEL-004)

Ada: `P <= 5`. Python: `pct < 5`. A tank at exactly 5 percent returns CAUTION where the spec requires WARNING. Exactly one input value misclassified; the boundary set {4, 5, 6} exposes it. Class: **boundary off-by-one**, the same species you met in coupon expiry and free shipping.

## 3. `alert_for` ADVISORY condition uses `or` instead of `and` (REQ-FUEL-004)

Ada: `elsif P <= 30 and then Rate > 200 then`. Python: `if pct <= 30 or rate > 200:`. The spec requires *both* low fuel and high burn. As implemented, a full tank at high burn rate (50 percent, 300 L/min) returns ADVISORY, and so does any tank at or below 30 percent regardless of rate. Note this is a *different* mechanism from the account.py precedence bug — there the operator precedence silently regrouped a correct-looking expression; here the operator itself is simply wrong. Both are conjunction-becomes-disjunction defects; distinguishing the two mechanisms in a defect note is worth doing. MC/DC on the two-condition decision catches it: vector (P≤30 false, Rate>200 true) is the killer.

## 4. `transfer` inherits defect 1 (REQ-FUEL-005)

No independent bug in `transfer` — but because it calls `usable_quantity`, a failed-sensor source tank can transfer fuel it may not have. Evidence: `transfer(Tank(1000, 900, sensor_ok=False), Tank(1000, 0), 500)` returns True and mutates both tanks. **This is not a separate defect note** — one root cause, one note; list this as an additional consequence under defect 1. Recognizing shared root causes across symptoms is exactly the judgment you practiced deciding that three failing MC/DC vectors were one note.

## 5. Range enforcement lost entirely (REQ-FUEL-007)

The Ada types (`Litres is range 0 .. 5_000`, `Percent is range 0 .. 100`) enforced ranges at runtime with no explicit checks in the body. Python has no equivalent, and the porter wrote no replacement — `RangeError` is defined in the module and never raised anywhere. `fuel_percent(Tank(capacity=100, quantity=99999))` returns 99999, a "percent" far outside 0–100. Class: **lost type constraint** — a defect class that exists *only* in porting, and one you can only find by reading the source language's type declarations or the requirement that documents them. If you found this one, you did the Ada reading properly. Fix: explicit validation at each entry point, raising `RangeError`.

---

## Scoring your suite

Beyond the defect count, ask: does every requirement have at least one test (`tools/trace_matrix.py`)? Did you test the *negative space* of REQ-FUEL-005 — that a failed transfer leaves **both** tanks unmodified? Did REQ-FUEL-006's zero-litre case get a test, including the subtle version where a zero transfer is attempted between two isolated tanks (which requirement wins)? Did you notice that `fuel_percent`'s zero-capacity guard is the only defensive check that survived the port intact?

That last question is the interesting one to sit with: a port that keeps one guard and loses another tells you the translation wasn't systematic, which is itself a finding worth raising about the *process*, not just the code.
