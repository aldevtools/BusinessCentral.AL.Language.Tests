// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
// Scope: in-scope
// Fixtures used: none
// Facts: al-runner issue 6288 (follow-up to 6139, reporter's repro, passed on real BC): objects for WbExternalReapplyTests.al. After an external refresh, First enters OnAfterGetCurrRecord, which rebuilds the marked view and calls CurrPage.Update(false); GoToRecord of the row that dropped out of MarkedOnly returns false and row 1 stays current.

table 90571 "LT WB External Reapply Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 90572 "LT WB External Reapply Detail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Line No."; Integer) { }
    }

    keys
    {
        key(PK; Id, "Line No.") { Clustered = true; }
    }
}

codeunit 90573 "LT WB External Reapply Marks"
{
    procedure MarkFlagged(var Row: Record "LT WB External Reapply Row")
    var
        RowsInView: Record "LT WB External Reapply Row";
    begin
        Row.MarkedOnly(false);
        Row.ClearMarks();
        RowsInView.Copy(Row);
        if RowsInView.FindSet() then
            repeat
                if RowsInView.Flag then begin
                    Row.Get(RowsInView.Id);
                    Row.Mark(true);
                end;
            until RowsInView.Next() = 0;
        Row.MarkedOnly(true);
    end;
}

codeunit 90574 "LT WB External Refresh"
{
    SingleInstance = true;

    procedure InvokeRefresh()
    var
        Row: Record "LT WB External Reapply Row";
    begin
        Row.Get(2);
        Row.Flag := false;
        Row.Modify();
        RefreshCompleted := true;
    end;

    procedure ConsumeRefreshCompleted(): Boolean
    begin
        if not RefreshCompleted then
            exit(false);
        RefreshCompleted := false;
        exit(true);
    end;

    var
        RefreshCompleted: Boolean;
}

page 90575 "LT WB External Reapply Part"
{
    PageType = ListPart;
    SourceTable = "LT WB External Reapply Detail";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Id; Rec.Id) { }
                field("Line No."; Rec."Line No.") { }
            }
        }
    }
}

page 90576 "LT WB External Reapply List"
{
    PageType = Worksheet;
    SourceTable = "LT WB External Reapply Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(FlaggedTile; Tile)
                {
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Marks.MarkFlagged(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
            }
            part(Details; "LT WB External Reapply Part")
            {
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RowText := Format(Rec.Id);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrText := Format(Rec.Id);
        if ExternalRefresh.ConsumeRefreshCompleted() then begin
            Marks.MarkFlagged(Rec);
            CurrPage.Update(false);
        end;
    end;

    var
        Marks: Codeunit "LT WB External Reapply Marks";
        ExternalRefresh: Codeunit "LT WB External Refresh";
        Tile: Integer;
        RowText: Text;
        CurrText: Text;
}

