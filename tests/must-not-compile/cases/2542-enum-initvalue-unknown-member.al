// @expect AL0522 | Property value Unknown is not in the values for enum 'MNC Y47 Enum'.
// An Enum field whose InitValue names no member of the enum (bare form). The same name single-quoted ('Unknown') compiles:
// record/lt-y47-initvalue-quoted/Y47EnumInitQuoted.al (writer Y47).
enum 50000 "MNC Y47 Enum"
{
    value(0; " ") { }
    value(1; "G/L Account") { }
}

table 50000 "MNC Y47 Enum Init"
{
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Line Type"; Enum "MNC Y47 Enum") { InitValue = Unknown; }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
