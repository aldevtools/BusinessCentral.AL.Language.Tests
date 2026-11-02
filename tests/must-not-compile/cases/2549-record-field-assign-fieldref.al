// @expect AL0122 | Cannot implicitly convert type 'FieldRef' to 'Text[20]'. Use an explicit conversion or change the type.
// A FieldRef assigned to a record field. FieldRef.Value := <FieldRef> compiles: recordref/lt-y47-validate-fieldref/Y47ValidateFieldRef.al
// (writer Y47, al-runner issue 6591).
table 50000 "MNC Y47 Vf Row"
{
    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Description; Text[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 50000 "MNC Y47 Vf Copy"
{
    procedure Copy(SourceField: FieldRef)
    var
        Target: Record "MNC Y47 Vf Row";
    begin
        Target.Description := SourceField;
    end;
}
