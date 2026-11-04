// @expect AL0193 | Argument 2: cannot convert from 'FieldRef' to the type of Argument 1 'Text[20]'
// Record.Validate(Field, <FieldRef>): the value argument is typed by the field, and a FieldRef does not convert to it. FieldRef.Validate(<FieldRef>)
// compiles and validates the source field's value: recordref/lt-y47-validate-fieldref/Y47ValidateFieldRef.al (writer Y47, al-runner issue 6591).
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
        Target.Validate(Description, SourceField);
    end;
}
