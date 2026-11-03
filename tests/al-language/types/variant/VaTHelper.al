// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: none (helper objects of the Variant probes, no tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 71027 "LT VaT Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

enum 71028 "LT VaT Enum"
{
    Extensible = true;
    value(0; Zero) { }
    value(1; One) { }
    value(5; Five) { }
}

codeunit 71026 "LT VaT Helper"
{
    procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsInteger() then R += 'Integer,';
        if V.IsText() then R += 'Text,';
        if V.IsCode() then R += 'Code,';
        if V.IsDate() then R += 'Date,';
        if V.IsDecimal() then R += 'Decimal,';
        if V.IsBoolean() then R += 'Boolean,';
        if V.IsRecord() then R += 'Record,';
        if V.IsRecordRef() then R += 'RecordRef,';
        if V.IsFieldRef() then R += 'FieldRef,';
        if V.IsCodeunit() then R += 'Codeunit,';
        if V.IsOption() then R += 'Option,';
        if V.IsChar() then R += 'Char,';
        if V.IsByte() then R += 'Byte,';
        if V.IsGuid() then R += 'Guid,';
        if V.IsDuration() then R += 'Duration,';
        if V.IsBigInteger() then R += 'BigInteger,';
        if V.IsDateTime() then R += 'DateTime,';
        if V.IsTime() then R += 'Time,';
        if V.IsDictionary() then R += 'Dictionary,';
        if V.IsList() then R += 'List,';
        if V.IsInStream() then R += 'InStream,';
        if V.IsOutStream() then R += 'OutStream,';
        if V.IsNotification() then R += 'Notification,';
        exit(R);
    end;

    procedure TakeByValue(V: Variant): Text
    begin
        V := 'changed';
        exit(Format(V));
    end;

    procedure TakeByVar(var V: Variant)
    begin
        V := 'changed';
    end;

    procedure ToInt(V: Variant): Integer
    begin
        exit(V);
    end;

    procedure ToText(V: Variant): Text
    begin
        exit(V);
    end;
}
