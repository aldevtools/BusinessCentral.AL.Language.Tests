// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'String' of 'SetFilter(Text, [Joker])'
// FieldRef.SetFilter has two parameters (String, [Joker]): the assignment form is checked as SetFilter() and refused. (gap cycle 3 C3-09; writer Y36)
codeunit 50000 "MNC C2504"
{
    procedure Run1()
    var
        RR: RecordRef;
        FR: FieldRef;
    begin
        RR.Open(Database::"MNC Y36 RR Row");
        FR := RR.Field(1);
        FR.SetFilter := '1';
    end;
}

table 50001 "MNC Y36 RR Row"
{
    fields { field(1; Id; Integer) { } }
}
