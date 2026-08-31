--  fuel_monitor.adb -- package BODY (the implementations)
--
--  READ THIS CAREFULLY. This Ada is the REFERENCE implementation: it is
--  correct with respect to docs/requirements.md. The Python port in
--  src/fuelmon/ is what you actually test, and the port contains
--  defects introduced during translation.
--
--  This mirrors a real verification situation: legacy Ada avionics code
--  is ported to a new platform, and your job is to verify the port
--  behaves per requirements. The Ada is your white-box reference.
--
--  Ada reading notes for a Python person:
--    --        comment
--    :=        assignment          =    equality
--    /=        not equal           and then / or else = short-circuit
--    elsif     elif                end if; / end loop;  close blocks
--    Foo'First / Foo'Last  are ATTRIBUTES: the min/max of a type

package body Fuel_Monitor is

   -----------------------
   -- Fuel_Percent      --
   -----------------------
   --  REQ-FUEL-001: percentage of capacity currently in the tank,
   --  truncated toward zero. A tank of zero capacity reads 0 percent.

   function Fuel_Percent (T : Tank_State) return Percent is
   begin
      if T.Capacity = 0 then
         return 0;
      end if;

      --  Integer division truncates toward zero in Ada, as // does in
      --  Python for non-negative operands.
      return Percent ((Integer (T.Quantity) * 100) / Integer (T.Capacity));
   end Fuel_Percent;

   -----------------------
   -- Usable_Quantity   --
   -----------------------
   --  REQ-FUEL-002: an isolated tank contributes no usable fuel.
   --  REQ-FUEL-003: a tank with a failed sensor contributes no usable
   --  fuel (the quantity cannot be trusted).

   function Usable_Quantity (T : Tank_State) return Litres is
   begin
      if T.Isolated or else not T.Sensor_Ok then
         return 0;
      end if;
      return T.Quantity;
   end Usable_Quantity;

   -----------------------
   -- Alert_For         --
   -----------------------
   --  REQ-FUEL-004: alert level is determined by fuel percent and the
   --  current burn rate:
   --     Warning  when percent is at or below 5, OR when the sensor
   --              has failed (unknown fuel is a Warning condition)
   --     Caution  when percent is at or below 15
   --     Advisory when percent is at or below 30, AND rate exceeds 200
   --     Normal   otherwise
   --  Bands are evaluated most-severe first.

   function Alert_For (T : Tank_State; Rate : Flow_Rate) return Alert_Level is
      P : constant Percent := Fuel_Percent (T);
   begin
      if not T.Sensor_Ok or else P <= 5 then
         return Warning;
      elsif P <= 15 then
         return Caution;
      elsif P <= 30 and then Rate > 200 then
         return Advisory;
      else
         return Normal;
      end if;
   end Alert_For;

   -----------------------
   -- Transfer          --
   -----------------------
   --  REQ-FUEL-005: a transfer succeeds only when ALL of: the source
   --  has at least Amount of usable fuel, the destination has room for
   --  Amount without exceeding its capacity, and NEITHER tank is
   --  isolated. On success both quantities are updated; on failure
   --  neither tank is modified.
   --  REQ-FUEL-006: a transfer of zero litres always succeeds and
   --  changes nothing.

   procedure Transfer
     (From    : in out Tank_State;
      To      : in out Tank_State;
      Amount  : in     Litres;
      Success :    out Boolean)
   is
      Room : constant Litres := To.Capacity - To.Quantity;
   begin
      if Amount = 0 then
         Success := True;
         return;
      end if;

      if From.Isolated or else To.Isolated then
         Success := False;
         return;
      end if;

      if Usable_Quantity (From) < Amount or else Room < Amount then
         Success := False;
         return;
      end if;

      From.Quantity := From.Quantity - Amount;
      To.Quantity   := To.Quantity + Amount;
      Success       := True;
   end Transfer;

end Fuel_Monitor;
