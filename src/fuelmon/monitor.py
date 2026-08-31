"""Python port of the Ada Fuel_Monitor package.

This module is the SYSTEM UNDER TEST. It was ported from the Ada in
ada_src/ by another engineer. Your job is to verify the port against
docs/requirements.md.

Two reference sources are available to you:
  * docs/requirements.md  -- the authoritative spec (black-box)
  * ada_src/fuel_monitor.adb -- the correct reference implementation,
    useful for white-box comparison when you want to see how a check
    was *supposed* to work

Note what the port LOSES relative to Ada: the Ada types (Litres is
range 0 .. 5_000, Percent is range 0 .. 100) enforced their ranges
automatically at runtime. Python has no equivalent, so any range
enforcement must be written by hand -- or is silently absent. That
gap is a real class of porting defect and is worth thinking about
as you design tests.

NOTE: this port contains defects. There are no tests yet -- you are
building the suite from nothing.
"""

from __future__ import annotations

import enum
from dataclasses import dataclass

CAPACITY_MAX = 5000
PERCENT_MAX = 100
RATE_MAX = 500


class AlertLevel(enum.Enum):
    NORMAL = "NORMAL"
    ADVISORY = "ADVISORY"
    CAUTION = "CAUTION"
    WARNING = "WARNING"


class RangeError(ValueError):
    """Raised when a value falls outside its declared range."""


@dataclass
class Tank:
    capacity: int = 0
    quantity: int = 0
    sensor_ok: bool = True
    isolated: bool = False


def fuel_percent(tank: Tank) -> int:
    if tank.capacity == 0:
        return 0
    return (tank.quantity * 100) // tank.capacity


def usable_quantity(tank: Tank) -> int:
    if tank.isolated:
        return 0
    return tank.quantity


def alert_for(tank: Tank, rate: int) -> AlertLevel:
    pct = fuel_percent(tank)
    if not tank.sensor_ok or pct < 5:
        return AlertLevel.WARNING
    if pct <= 15:
        return AlertLevel.CAUTION
    if pct <= 30 or rate > 200:
        return AlertLevel.ADVISORY
    return AlertLevel.NORMAL


def transfer(source: Tank, dest: Tank, amount: int) -> bool:
    """Move `amount` litres from source to dest.

    Returns True on success. On failure neither tank is modified.
    """
    room = dest.capacity - dest.quantity

    if amount == 0:
        return True

    if source.isolated or dest.isolated:
        return False

    if usable_quantity(source) < amount or room < amount:
        return False

    source.quantity -= amount
    dest.quantity += amount
    return True
