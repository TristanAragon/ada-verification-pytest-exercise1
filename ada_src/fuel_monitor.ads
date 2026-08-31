--  fuel_monitor.ads -- package SPECIFICATION (the public interface)
--
--  In Ada, a package is split across two files:
--    .ads  the spec  -- types, constants, and subprogram declarations
--    .adb  the body  -- the implementations
--  Reading the spec first is how you orient in unfamiliar Ada: it gives
--  you the API and, crucially, the TYPE RANGES -- which hand you your
--  boundary values for free.

package Fuel_Monitor is

   --  Constrained scalar types. The compiler and runtime enforce these
   --  ranges; assigning out of range raises Constraint_Error. Note how
   --  much of the validation you would hand-write in Python lives in
   --  the type declaration here.
   type Litres        is range 0 .. 5_000;
   type Percent       is range 0 .. 100;
   type Flow_Rate     is range 0 .. 500;      --  litres per minute
   type Tank_Index    is range 1 .. 4;

   subtype Reserve_Percent is Percent range 0 .. 20;

   --  Enumeration type -- like a Python enum.
   type Alert_Level is (Normal, Advisory, Caution, Warning);

   type Tank_State is record
      Capacity   : Litres  := 0;
      Quantity   : Litres  := 0;
      Sensor_Ok  : Boolean := True;
      Isolated   : Boolean := False;   --  crew has isolated this tank
   end record;

   --  A FUNCTION returns a value; a PROCEDURE does not (like -> None).
   --  Parameters are `in` (read-only) by default; `in out` means the
   --  subprogram may modify the caller's variable.

   function Fuel_Percent (T : Tank_State) return Percent;

   function Alert_For (T : Tank_State; Rate : Flow_Rate) return Alert_Level;

   function Usable_Quantity (T : Tank_State) return Litres;

   procedure Transfer
     (From    : in out Tank_State;
      To      : in out Tank_State;
      Amount  : in     Litres;
      Success :    out Boolean);

end Fuel_Monitor;
