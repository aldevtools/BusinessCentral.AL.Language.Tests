// @expect AL0133 | Argument 1: cannot convert from 'Boolean' to 'Integer'
// @expect AL0133 | Argument 2: cannot convert from 'Boolean' to 'Text'
// A table procedure Insert(Integer; Text; Boolean) hides the built-in Insert for a call with three arguments: Insert(true, true, true)
// is checked against the own procedure and refused, not taken as a built-in call. (gap cycle 3 C3-06b; writer Y36)
codeunit 50000 "MNC C2500"
{
    procedure Run1()
    var
        R: Record "MNC Y36 Row";
    begin
        R.Insert(true, true, true);
    end;
}

table 50001 "MNC Y36 Row"
{
    fields { field(1; Id; Integer) { } }

    procedure Insert(A: Integer; B: Text; C: Boolean)
    begin
    end;
}
