// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A page extension action separator is named True, unquoted: `separator(True)` (al-runner issue 8634).
// Quoted, as "True", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53386 "MNC KS3386"
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

page 53386 "MNC KS3386 Page"
{
    PageType = Card;
    SourceTable = "MNC KS3386";

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
            }
        }
        area(FactBoxes)
        {
        }
    }
    actions
    {
        area(Processing)
        {
            action(Act)
            {
                trigger OnAction()
                begin
                end;
            }
        }
        area(Promoted)
        {
        }
    }
}

pageextension 53386 "MNC KS3386 Ext" extends "MNC KS3386 Page"
{
    actions
    {
        addlast(Processing)
        {
            separator(True)
            {
            }
        }
    }
}
