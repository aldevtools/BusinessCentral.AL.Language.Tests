// @expect AL0161 | 'Marker' is inaccessible due to its protection level
// A codeunit names a protected variable of a table through a record variable (al-runner issue 6984). In an extension of the same
// table the member form compiles: tests/al-language/table-objects/extensions/ProtectedVarCrossApp.al.
table 52953 "MNC ProtVar Table 2953"
{
    fields { field(1; K; Code[10]) { } }
    keys { key(PK; K) { Clustered = true; } }

    protected var
        Marker: Text;
}
codeunit 52953 "MNC ProtVar Reader 2953"
{
    procedure Read(var R: Record "MNC ProtVar Table 2953"): Text
    begin
        exit(R.Marker);
    end;
}
