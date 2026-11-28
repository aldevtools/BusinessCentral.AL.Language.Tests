// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Integer' and 'Joker'
// An Integer += FieldRef.Value(): the value is typed Joker, and AL has no '+=' between Integer and Joker (al-runner issue 9283).
// A plain assignment from the same value, I := FR.Value(), compiles.
table 53834 "MNC Counter 3834"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
codeunit 53834 "MNC Compound 3834"
{
    procedure Probe()
    var
        RecRef: RecordRef;
        FR: FieldRef;
        I: Integer;
    begin
        RecRef.Open(Database::"MNC Counter 3834");
        FR := RecRef.Field(2);
        I := 5;
        I += FR.Value();
    end;
}
