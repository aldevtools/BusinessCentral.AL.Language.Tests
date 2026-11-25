// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// The member is Rec's field in a control's Visible expression, `Visible = Rec.Var > 0;`, unquoted (al-runner issue 8635).
// Quoted, as "Var", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53454 "MNC KM3454"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Var"; Integer)
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

page 53454 "MNC KM3454 Card"
{
    PageType = Card;
    SourceTable = "MNC KM3454";

    layout
    {
        area(Content)
        {
            field("Var"; Rec."Var")
            {
                Visible = Rec.Var > 0;
            }
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
    }
}
