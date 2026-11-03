// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Fixtures used: ALT Page Find Record Row (60671), ALT Page Find Rec Trace (60672)
//
// A list page that serves its rows from a page-global TEMPORARY record instead of from the
// table, through OnFindRecord/OnNextRecord -- the documented way a page presents a rowset the
// platform cannot produce by filtering Rec.
//
// Two properties of the fixture carry the suite's weight:
//
//   * FillTempEveryOther inserts every SECOND row of the table into the buffer, and the table
//     gives it nothing to select on -- every row's Description is identical. So the rowset the
//     triggers serve cannot be reached by any filter over the table, and an implementation
//     that walks the table instead of asking the page cannot produce it by accident.
//   * The triggers hand Which/Steps straight to the buffer, which is the shape every real page
//     of this kind uses. TempBuf.Copy(Rec) is what carries the host's filters, current key and
//     sort direction onto the buffer, so the rowset stays subject to whatever the user filtered
//     -- see the record-level test of Copy for the properties that makes true.

page 60673 "ALT Page Find Record List"
{
    PageType = List;
    SourceTable = "ALT Page Find Record Row";
    SourceTableView = sorting("No.") order(descending);
    Editable = false;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(FillTempEveryOther)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Src: Record "ALT Page Find Record Row";
                    Take: Boolean;
                begin
                    ResetBuffer();
                    Src.SetCurrentKey("No.");
                    Src.Ascending(true);
                    Take := true;
                    if Src.FindSet() then
                        repeat
                            if Take then begin
                                TempBuf := Src;
                                TempBuf.Insert();
                            end;
                            Take := not Take;
                        until Src.Next() = 0;
                    Activate();
                end;
            }

            action(FillTempAll)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Src: Record "ALT Page Find Record Row";
                begin
                    ResetBuffer();
                    if Src.FindSet() then
                        repeat
                            TempBuf := Src;
                            TempBuf.Insert();
                        until Src.Next() = 0;
                    Activate();
                end;
            }
        }
    }

    var
        TempBuf: Record "ALT Page Find Record Row" temporary;
        Trace: Codeunit "ALT Page Find Rec Trace";
        RunOnTemp: Boolean;

    local procedure ResetBuffer()
    begin
        TempBuf.Reset();
        TempBuf.DeleteAll();
    end;

    local procedure Activate()
    begin
        RunOnTemp := true;
        Rec.FilterGroup(0);
        Rec.SetRange("No.");
        CurrPage.Update(false);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
    begin
        Trace.NoteFind();
        if not RunOnTemp then
            exit(Rec.Find(Which));
        TempBuf.Copy(Rec);
        Found := TempBuf.Find(Which);
        if Found then
            Rec := TempBuf;
        exit(Found);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        Moved: Integer;
    begin
        Trace.NoteNext(Steps);
        if not RunOnTemp then
            exit(Rec.Next(Steps));
        TempBuf.Copy(Rec);
        Moved := TempBuf.Next(Steps);
        if Moved <> 0 then
            Rec := TempBuf;
        exit(Moved);
    end;
}
