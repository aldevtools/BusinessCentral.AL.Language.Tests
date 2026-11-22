// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A page action group is named Begin, unquoted: `group(Begin)` (al-runner issue 8634).
// Quoted, as "Begin", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53366 "MNC KS3366"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Amount; Integer)
        {
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

page 53366 "MNC KS3366 Page"
{
    PageType = Card;
    SourceTable = "MNC KS3366";

    actions
    {
        area(Processing)
        {
            group(Begin)
            {
                action(Act)
                {
                    trigger OnAction()
                    begin
                    end;
                }
            }
        }
    }
}
