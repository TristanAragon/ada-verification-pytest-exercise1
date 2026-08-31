# Software Requirements — Fuel_Monitor

Authoritative specification. Both the Ada reference (`ada_src/`) and the Python port (`src/fuelmon/`) implement these. Where the port and this document disagree, **this document wins**.

Units: litres for quantities and capacities, percent (0–100) for fuel level, litres/minute for flow rate.

## Fuel percentage

- **REQ-FUEL-001** — `fuel_percent` shall return the tank quantity as a percentage of its capacity, truncated toward zero. A tank with zero capacity shall read 0 percent.

## Usable fuel

- **REQ-FUEL-002** — An isolated tank shall contribute zero usable fuel.
- **REQ-FUEL-003** — A tank whose sensor has failed shall contribute zero usable fuel, because its quantity cannot be trusted.

## Alerting

- **REQ-FUEL-004** — `alert_for` shall return an alert level determined by fuel percent and burn rate, evaluated most-severe-first:
  - **WARNING** when fuel percent is at or below 5, or when the sensor has failed.
  - **CAUTION** when fuel percent is at or below 15.
  - **ADVISORY** when fuel percent is at or below 30 **and** the flow rate exceeds 200 litres/minute.
  - **NORMAL** otherwise.

## Transfers

- **REQ-FUEL-005** — A transfer shall succeed only when all of the following hold: the source tank has at least `amount` of **usable** fuel; the destination has room for `amount` without exceeding its capacity; and neither tank is isolated. On success both quantities shall be updated. On failure neither tank shall be modified.
- **REQ-FUEL-006** — A transfer of zero litres shall always succeed and shall change nothing.

## Ranges

- **REQ-FUEL-007** — Capacity and quantity shall lie within 0–5000 litres, fuel percent within 0–100, and flow rate within 0–500 litres/minute. Values outside these ranges shall be rejected with `RangeError`.

> Porting note: in the Ada original these ranges were enforced by the type system (`type Litres is range 0 .. 5_000`), so no explicit check appears in the Ada body. The Python port has no equivalent mechanism.
