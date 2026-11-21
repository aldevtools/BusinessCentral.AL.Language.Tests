// @expect AL0105 | Syntax error, identifier expected; 'else' is a keyword
// The member Else, unquoted, in a table extension field's OptionMembers (al-runner issue 8657).
// Quoted, as "Else", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
table 53598 "MNC KO3598"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Opt; Option)
        {
            OptionMembers = Zero,One;
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

tableextension 53598 "MNC KO3598 Ext" extends "MNC KO3598"
{
    fields
    {
        field(50000; ExtOpt; Option)
        {
            OptionMembers = Zero,Else;
        }
    }
}
