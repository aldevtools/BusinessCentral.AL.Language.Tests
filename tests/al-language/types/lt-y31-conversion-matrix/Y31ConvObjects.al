// Scope: in-scope
// Fixtures of the implicit conversion matrix (scripts/conversion-matrix/gen_run.py): the enums, the interface, the table whose fields are
// conversion targets, and the helpers that show a value (ordinal of a Char or an Option, type and value of a Variant).
interface "LT Y31 I"
{
    procedure Name(): Text;
}

enum 92400 "LT Y31 E"
{
    Extensible = true;
    value(0; A) { }
    value(1; B) { }
    value(2; C) { }
}

enum 92401 "LT Y31 EI" implements "LT Y31 I"
{
    value(0; A) { Implementation = "LT Y31 I" = "LT Y31 Impl"; }
}

codeunit 92401 "LT Y31 Impl" implements "LT Y31 I"
{
    procedure Name(): Text
    begin
        exit('impl');
    end;
}

table 92400 "LT Y31 Conv Fields"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Integer; Integer) { }
        field(2; BigInteger; BigInteger) { }
        field(3; Decimal; Decimal) { }
        field(4; Option; Option) { OptionMembers = A,B,C; }
        field(5; Enum; Enum "LT Y31 E") { }
        field(6; Text10; Text[10]) { }
        field(7; Code10; Code[10]) { }
        field(8; Guid; Guid) { }
        field(9; Duration; Duration) { }
    }

    keys
    {
        key(PK; Integer) { }
    }
}

codeunit 92400 "LT Y31 Conv Util"
{
    // Char to Integer by value: types/lt-scalars/ScT70061.al pins it.
    procedure CharOrd(C: Char): Integer
    begin
        exit(C);
    end;

    // Option to Integer by value: types/PROptionInteger.al pins it.
    procedure OptOrd(O: Integer): Integer
    begin
        exit(O);
    end;

    // The Is... answers of a Variant (every one that is true, in this order) and its value in XML format.
    procedure VShow(V: Variant): Text
    var
        Kinds: Text;
    begin
        if V.IsBoolean() then Kinds += ',Boolean';
        if V.IsOption() then Kinds += ',Option';
        if V.IsInteger() then Kinds += ',Integer';
        if V.IsByte() then Kinds += ',Byte';
        if V.IsBigInteger() then Kinds += ',BigInteger';
        if V.IsDecimal() then Kinds += ',Decimal';
        if V.IsChar() then Kinds += ',Char';
        if V.IsText() then Kinds += ',Text';
        if V.IsCode() then Kinds += ',Code';
        if V.IsDate() then Kinds += ',Date';
        if V.IsTime() then Kinds += ',Time';
        if V.IsDateTime() then Kinds += ',DateTime';
        if V.IsDuration() then Kinds += ',Duration';
        if V.IsGuid() then Kinds += ',Guid';
        exit(CopyStr(Kinds, 2) + '|' + Format(V, 0, 9));
    end;
}
