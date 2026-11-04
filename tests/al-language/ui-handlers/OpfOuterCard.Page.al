// Fixture for "Opf Ok Part Flush Tests" (60663). OnQueryClosePage reads the PART, not Rec, and
// records what it saw in "Opf Result" (60638). Only the confirming close actions take that
// branch, so a cancelled round trip leaves no row -- which is what lets the suite tell "the
// part was empty" from "the trigger did not run".
page 60659 "Opf Outer Card"
{
    PageType = Card;
    SourceTable = "Opf Result";
    SourceTableTemporary = true;
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
        Result: Record "Opf Result";
        SeenCount: Integer;
        FirstValue: Text[30];
    begin
        if (CloseAction <> CloseAction::OK) and (CloseAction <> CloseAction::LookupOK) then
            exit(true);

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
        Result.Modify();
        exit(true);
    end;
}
