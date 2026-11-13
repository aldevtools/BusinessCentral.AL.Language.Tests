// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '[' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ']' expected
// An option member named In is a keyword: R.Direction::In needs quotes (R.Direction::"In" compiles).
// The quoted form R.Direction::"In" compiles (AL 16, 17, 18 and 30). AL 16 stops the texts after the first sentence; AL 17 and later append an explanation.
table 53158 "MNC OI3158 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Direction; Option) { OptionMembers = "In","Out"; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53159 "MNC OI3158 C"
{
    procedure SetIn(var R: Record "MNC OI3158 T")
    begin
        R.Direction := R.Direction::In;
    end;
}
