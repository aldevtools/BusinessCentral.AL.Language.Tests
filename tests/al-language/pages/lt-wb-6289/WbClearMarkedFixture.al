// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
// Scope: in-scope
// Fixtures used: none
// Facts: al-runner issue 6289 (reporter's repro, passed on real BC): objects for WbClearMarkedTests.al. After a marked DrillDown, an action clears MarkedOnly; GoToRecord then includes the row again.

table 90579 "LT WB Clear Filter Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Code[20]) { }
        field(3; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }
}

table 90580 "LT WB Clear Filter Detail"
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

codeunit 90581 "LT WB Clear Filter Marks"
{
    procedure MarkFlagged(var Row: Record "LT WB Clear Filter Row")
    var
        RowsInView: Record "LT WB Clear Filter Row";
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

    procedure Clear(var Row: Record "LT WB Clear Filter Row")
    begin
        Row.MarkedOnly(false);
        Row.ClearMarks();
    end;
}

page 90582 "LT WB Clear Filter Detail Part"
{
    PageType = ListPart;
    SourceTable = "LT WB Clear Filter Detail";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field(Id; Rec.Id) { }
                field("Line No."; Rec."Line No.") { }
            }
        }
    }
}

page 90583 "LT WB Clear Filter Name Part"
{
    PageType = Worksheet;
    SourceTable = "LT WB Clear Filter Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filter)
            {
                field(Flagged; Tile)
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
                Editable = false;
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
            part(Details; "LT WB Clear Filter Detail Part")
            {
                SubPageLink = Id = field(Id);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ClearFilters)
            {
                trigger OnAction()
                begin
                    Marks.Clear(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Name);
    end;

    trigger OnAfterGetRecord()
    begin
        RowText := Format(Rec.Id);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrentText := Format(Rec.Id);
    end;

    var
        Marks: Codeunit "LT WB Clear Filter Marks";
        Tile: Integer;
        RowText: Text;
        CurrentText: Text;
}

page 90584 "LT WB Clear Filter Id Part"
{
    PageType = Worksheet;
    SourceTable = "LT WB Clear Filter Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filter)
            {
                field(Flagged; Tile)
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
                Editable = false;
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
            part(Details; "LT WB Clear Filter Detail Part")
            {
                SubPageLink = Id = field(Id);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ClearFilters)
            {
                trigger OnAction()
                begin
                    Marks.Clear(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RowText := Format(Rec.Id);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrentText := Format(Rec.Id);
    end;

    var
        Marks: Codeunit "LT WB Clear Filter Marks";
        Tile: Integer;
        RowText: Text;
        CurrentText: Text;
}

page 90585 "LT WB Clear Filter No Triggers"
{
    PageType = Worksheet;
    SourceTable = "LT WB Clear Filter Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filter)
            {
                field(Flagged; Tile)
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
                Editable = false;
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
            }
            part(Details; "LT WB Clear Filter Detail Part")
            {
                SubPageLink = Id = field(Id);
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ClearFilters)
            {
                trigger OnAction()
                begin
                    Marks.Clear(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(Name);
    end;

    var
        Marks: Codeunit "LT WB Clear Filter Marks";
        Tile: Integer;
}
