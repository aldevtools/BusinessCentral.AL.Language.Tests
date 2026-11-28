// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// Procedure, unquoted after `.`, in a page control's Visible, `Visible = Rec.Procedure > 0;` (al-runner issue 8650).
// Quoted, as "Procedure", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53520 "MNC KP3520"
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

page 53520 "MNC KP3520 Card"
{
    PageType = Card;
    SourceTable = "MNC KP3520";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = Rec.Procedure > 0;
                }
            }
            part(Lines; "MNC KP3520 Part")
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

page 58520 "MNC KP3520 Part"
{
    PageType = ListPart;
    SourceTable = "MNC KP3520";

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
