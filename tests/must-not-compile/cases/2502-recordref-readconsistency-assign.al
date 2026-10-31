// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// RecordRef.ReadConsistency is a getter with no parameter: the assignment form is refused. (gap cycle 3 C3-09; writer Y36)
codeunit 50000 "MNC C2502"
{
    procedure Run1()
    var
        RR: RecordRef;
        FR: FieldRef;
    begin
        RR.Open(Database::"MNC Y36 RR Row");
        FR := RR.Field(1);
        RR.ReadConsistency := true;
    end;
}

table 50001 "MNC Y36 RR Row"
{
    fields { field(1; Id; Integer) { } }
}
