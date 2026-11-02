// @expect AL0294 | The type of property value 'Item' does not match the field’s type.
// An Option field whose InitValue is a single-quoted member name without spaces; the bare form (InitValue = Item) compiles.
// The Enum counterpart compiles: record/lt-y47-initvalue-quoted/Y47EnumInitQuoted.al (writer Y47).
table 50000 "MNC Y47 Opt Init Plain"
{
    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Line Type"; Option)
        {
            OptionMembers = " ","G/L Account",Item;
            InitValue = 'Item';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
