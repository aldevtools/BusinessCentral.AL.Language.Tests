// Scope: in-scope
// Fixtures used: none (see the fixture file of this folder)

page 90603 "LT WB Modal Part"
{
    PageType = ListPart;
    SourceTable = "LT WB Modal Row";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec."Entry No." := 1;
        Rec.Insert();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CloseTrace: Codeunit "LT WB Close Trace";
    begin
        CloseTrace.Add('Part', CloseAction);
        exit(CloseTrace.IsCloseAllowed());
    end;
}
