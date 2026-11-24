// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0114 | Syntax error, integer literal expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'extends' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0124 | The property 'Notes' cannot be used in this context
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A page extension system part is named TableExtension, unquoted: `systempart(TableExtension; Notes)` (al-runner issue 8634).
// Quoted, as "TableExtension", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
table 53382 "MNC KS3382"
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

page 53382 "MNC KS3382 Page"
{
    PageType = Card;
    SourceTable = "MNC KS3382";

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

pageextension 53382 "MNC KS3382 Ext" extends "MNC KS3382 Page"
{
    layout
    {
        addlast(FactBoxes)
        {
            systempart(TableExtension; Notes)
            {
            }
        }
    }
}
