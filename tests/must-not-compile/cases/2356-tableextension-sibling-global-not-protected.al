// @expect AL0161 | 'Counter' is inaccessible due to its protection level
// A table extension uses a global variable that another extension of the same table in the same app declares with plain `var` (writer Y20,
// al-runner issue 6485). Declared with `protected var`, it compiles and both extensions share it:
// tests/al-language/tableextension/lt-y20-sibling-globals/Y20TableExtSiblingGlobals.al.
table 52356 "MNC Y20 Sib 2356"
{
    fields { field(1; K; Code[10]) { } }
    keys { key(PK; K) { Clustered = true; } }
}
tableextension 52356 "MNC Y20 Sib A 2356" extends "MNC Y20 Sib 2356"
{
    procedure SetFromA()
    begin
        Counter := 1;
    end;
}
tableextension 52357 "MNC Y20 Sib B 2356" extends "MNC Y20 Sib 2356"
{
    var
        Counter: Integer;
}
