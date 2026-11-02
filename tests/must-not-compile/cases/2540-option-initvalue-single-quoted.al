// @expect AL0294 | The type of property value 'G/L Account' does not match the field’s type.
// An Option field whose InitValue is a single-quoted string. The double-quoted ("G/L Account") and the bare form compile. An Enum field
// accepts the single-quoted form (al-runner issue 6585): record/lt-y47-initvalue-quoted/Y47EnumInitQuoted.al (writer Y47).
table 50000 "MNC Y47 Opt Init"
{
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Line Type"; Option)
        {
            OptionMembers = " ","G/L Account",Item;
            InitValue = 'G/L Account';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
