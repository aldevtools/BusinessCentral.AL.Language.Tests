// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// Procedure, unquoted after `.`, in a page part's Visible (al-runner issue 8650).
// Quoted, as "Procedure", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53542 "MNC KP3542"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Procedure"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"Procedure";
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

page 53542 "MNC KP3542 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3542";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                }
            }
            part(Lines; "MNC KP3542 Part")
            {
                Visible = Rec.Procedure > 0;
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

page 58542 "MNC KP3542 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3542";

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
