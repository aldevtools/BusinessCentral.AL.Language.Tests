// @expect AL0304 | Length of the identifier 'AbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijA' cannot exceed 120 characters
// A local variable name of 121 characters. 120 compiles.
codeunit 50001 "MNC SH C"
{
    procedure DoIt()
    var
        AbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijAbcdefghijA: Integer;
    begin
    end;
}
