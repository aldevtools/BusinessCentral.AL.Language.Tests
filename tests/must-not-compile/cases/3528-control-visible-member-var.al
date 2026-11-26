// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// Var, unquoted after `.`, in a page control's Visible, `Visible = Rec.Var > 0;` (al-runner issue 8650).
// Quoted, as "Var", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53528 "MNC KP3528"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Var"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"Var";
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

page 53528 "MNC KP3528 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3528";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = Rec.Var > 0;
                }
            }
            part(Lines; "MNC KP3528 Part")
            {
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

page 58528 "MNC KP3528 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3528";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.")
                {
                }
            }
        }
    }
}
