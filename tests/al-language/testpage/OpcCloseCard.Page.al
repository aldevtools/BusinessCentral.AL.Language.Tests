// Fixture for "Opc Close Part Flush Tests" (60438). The TestPage.Close() twin of
// "Opf Outer Card" (60659): the same temporary-sourced ListPart, read the same way, but its
// OnQueryClosePage records UNCONDITIONALLY -- an explicitly driven Close() does not
// necessarily carry CloseAction::OK, and an arm that never wrote its witness row could not
// tell "the part was empty" from "the trigger did not run".
page 60423 "Opc Close Card"
{
    PageType = Card;
    SourceTable = "Opc Head";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "Opf Lines Part") { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Temp: Record "Opf Line" temporary;
        Result: Record "Opc Result";
        SeenCount: Integer;
        FirstValue: Text[30];
    begin
        CurrPage.Lines.Page.GetRows(Temp);
        SeenCount := Temp.Count();
        if Temp.FindFirst() then
            FirstValue := Temp."Value";

        if not Result.Get('CLOSE') then begin
            Result.Init();
            Result."No." := 'CLOSE';
            Result.Insert();
        end;
        Result."Line Count" := SeenCount;
        Result."Value Seen" := FirstValue;
        Result."Close Action" := CopyStr(Format(CloseAction), 1, MaxStrLen(Result."Close Action"));
        Result.Modify();
        exit(true);
    end;
}
