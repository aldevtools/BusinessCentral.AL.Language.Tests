// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// The name after `::` is an option field's member, `Row.Opt := Row.Opt::Exit;`, unquoted (al-runner issue 8649).
// Quoted, as "Exit", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53493 "MNC KS3493"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Opt; Option)
        {
            OptionMembers = Zero,"Exit";
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

codeunit 58493 "MNC KS3493 Use"
{
    procedure P()
    var
        Row: Record "MNC KS3493";

    begin
        Row.Opt := Row.Opt::Exit;
    end;
}
