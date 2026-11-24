// @expect AL0105 | Syntax error, identifier expected; 'pageextension' is a keyword
// The member PageExtension, unquoted, in a table field's OptionMembers, `OptionMembers = Zero,PageExtension;` (al-runner issue 8657).
// Quoted, as "PageExtension", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
table 53594 "MNC KO3594"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Opt; Option)
        {
            OptionMembers = Zero,PageExtension;
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
