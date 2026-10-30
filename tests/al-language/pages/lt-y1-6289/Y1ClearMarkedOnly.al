// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90930 - 90937 (writer Y1)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6289. A Worksheet with a ListPart (SubPageLink on Id). A tile's OnDrillDown marks the rows with Flag = true
//   (Id 1 Name N4 and Id 3 Name N2 of four rows), turns MarkedOnly on and calls CurrPage.Update(false). The action ClearFilters then calls
//   MarkedOnly(false), ClearMarks() and CurrPage.Update(false). GoToRecord of an unmarked row before and after the action, and First.
//   Three pages: sorted by the secondary key Name (OnOpenPage SetCurrentKey) with OnAfterGetRecord and OnAfterGetCurrRecord (the
//   reporter's failing shape), the same in primary key order, and Name order without the two row triggers.
// Result (SaaS BC 29 and corpus CI, Windows and Linux alike), for all three pages: after the DrillDown the TestPage still shows the row it
//   opened on (Name order: 4, the first by Name; Id order: 1); GoToRecord of an unmarked row returns false and the page shows row 1 (in both
//   key orders). After ClearFilters the page shows row 1; GoToRecord of the formerly unmarked row returns true and moves to it;
//   First moves to the first row of the page's key (4 in Name order, 1 in Id order). The row triggers and the key make no difference.
// Source: al-runner issue 6289 (the reporter's repro passed on a real BC 29 container).
// BC versions: 27, 28, 29

table 90930 "LT Y1 Clear Row"
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

table 90931 "LT Y1 Clear Detail"
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

page 90933 "LT Y1 Clear Detail Part"
{
    PageType = ListPart;
    SourceTable = "LT Y1 Clear Detail";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                Editable = false;
                field(Id; Rec.Id) { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }
}

page 90934 "LT Y1 Clear Name Part"
{
    PageType = Worksheet;
    SourceTable = "LT Y1 Clear Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filter)
            {
                field(Flagged; Tile)
                {
                    ApplicationArea = All;
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
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Details; "LT Y1 Clear Detail Part")
            {
                ApplicationArea = All;
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
                ApplicationArea = All;

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
        Marks: Codeunit "LT Y1 Clear Marks";
        Tile: Integer;
        RowText: Text;
        CurrentText: Text;
}

page 90935 "LT Y1 Clear Id Part"
{
    PageType = Worksheet;
    SourceTable = "LT Y1 Clear Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filter)
            {
                field(Flagged; Tile)
                {
                    ApplicationArea = All;
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
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Details; "LT Y1 Clear Detail Part")
            {
                ApplicationArea = All;
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
                ApplicationArea = All;

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
        Marks: Codeunit "LT Y1 Clear Marks";
        Tile: Integer;
        RowText: Text;
        CurrentText: Text;
}

page 90936 "LT Y1 Clear No Triggers"
{
    PageType = Worksheet;
    SourceTable = "LT Y1 Clear Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Filter)
            {
                field(Flagged; Tile)
                {
                    ApplicationArea = All;
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
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
            part(Details; "LT Y1 Clear Detail Part")
            {
                ApplicationArea = All;
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
                ApplicationArea = All;

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
        Marks: Codeunit "LT Y1 Clear Marks";
        Tile: Integer;
}

codeunit 90932 "LT Y1 Clear Marks"
{
    procedure MarkFlagged(var Row: Record "LT Y1 Clear Row")
    var
        RowsInView: Record "LT Y1 Clear Row";
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

    procedure Clear(var Row: Record "LT Y1 Clear Row")
    begin
        Row.MarkedOnly(false);
        Row.ClearMarks();
    end;
}

codeunit 90937 "LT Y1 Clear Marked Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure SeedRows()
    var
        Row: Record "LT Y1 Clear Row";
        Detail: Record "LT Y1 Clear Detail";
    begin
        Row.DeleteAll();
        Detail.DeleteAll();
        AddRow(1, 'N4', true);
        AddRow(2, 'N3', false);
        AddRow(3, 'N2', true);
        AddRow(4, 'N1', false);
    end;

    local procedure AddRow(Id: Integer; Name: Code[20]; Flag: Boolean)
    var
        Row: Record "LT Y1 Clear Row";
        Detail: Record "LT Y1 Clear Detail";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Flag := Flag;
        Row.Insert();
        Detail.Init();
        Detail.Id := Id;
        Detail."Line No." := 10000;
        Detail.Insert();
    end;

    // The reporter's failing shape: Name order, ListPart, OnAfterGetRecord and OnAfterGetCurrRecord; unmarked row 2 (N3).
    [Test]
    procedure Y1_Clear_NameKeyWithPartAndTriggers()
    var
        Row: Record "LT Y1 Clear Row";
        ClearPage: TestPage "LT Y1 Clear Name Part";
    begin
        SeedRows();
        Row.Get(2);
        ClearPage.OpenView();
        Observer.Observe('open', ClearPage.Id.Value());
        ClearPage.Flagged.Drilldown();
        Observer.Observe('after drilldown', ClearPage.Id.Value());
        Observer.Observe('goto 2 filtered', Format(ClearPage.GoToRecord(Row), 0, 9) + '/' + ClearPage.Id.Value());
        ClearPage.ClearFilters.Invoke();
        Observer.Observe('after clear', ClearPage.Id.Value());
        Observer.Observe('goto 2 cleared', Format(ClearPage.GoToRecord(Row), 0, 9) + '/' + ClearPage.Id.Value());
        Observer.Observe('first cleared', Format(ClearPage.First(), 0, 9) + '/' + ClearPage.Id.Value());
        ClearPage.Close();
        Observer.Expect('open', '4');
        Observer.Expect('after drilldown', '4');
        Observer.Expect('goto 2 filtered', 'false/1');
        Observer.Expect('after clear', '1');
        Observer.Expect('goto 2 cleared', 'true/2');
        Observer.Expect('first cleared', 'true/4');
        Observer.Verify();
    end;

    // The same page, unmarked row 4 (N1, the first row in Name order).
    [Test]
    procedure Y1_Clear_NameKeyWithPartAndTriggers_Row4()
    var
        Row: Record "LT Y1 Clear Row";
        ClearPage: TestPage "LT Y1 Clear Name Part";
    begin
        SeedRows();
        Row.Get(4);
        ClearPage.OpenView();
        Observer.Observe('open', ClearPage.Id.Value());
        ClearPage.Flagged.Drilldown();
        Observer.Observe('after drilldown', ClearPage.Id.Value());
        Observer.Observe('goto 4 filtered', Format(ClearPage.GoToRecord(Row), 0, 9) + '/' + ClearPage.Id.Value());
        ClearPage.ClearFilters.Invoke();
        Observer.Observe('after clear', ClearPage.Id.Value());
        Observer.Observe('goto 4 cleared', Format(ClearPage.GoToRecord(Row), 0, 9) + '/' + ClearPage.Id.Value());
        Observer.Observe('first cleared', Format(ClearPage.First(), 0, 9) + '/' + ClearPage.Id.Value());
        ClearPage.Close();
        Observer.Expect('open', '4');
        Observer.Expect('after drilldown', '4');
        Observer.Expect('goto 4 filtered', 'false/1');
        Observer.Expect('after clear', '1');
        Observer.Expect('goto 4 cleared', 'true/4');
        Observer.Expect('first cleared', 'true/4');
        Observer.Verify();
    end;

    // Primary key order, same triggers; unmarked row 4.
    [Test]
    procedure Y1_Clear_PrimaryKeyWithPartAndTriggers()
    var
        Row: Record "LT Y1 Clear Row";
        ClearPage: TestPage "LT Y1 Clear Id Part";
    begin
        SeedRows();
        Row.Get(4);
        ClearPage.OpenView();
        Observer.Observe('open', ClearPage.Id.Value());
        ClearPage.Flagged.Drilldown();
        Observer.Observe('after drilldown', ClearPage.Id.Value());
        Observer.Observe('goto 4 filtered', Format(ClearPage.GoToRecord(Row), 0, 9) + '/' + ClearPage.Id.Value());
        ClearPage.ClearFilters.Invoke();
        Observer.Observe('after clear', ClearPage.Id.Value());
        Observer.Observe('goto 4 cleared', Format(ClearPage.GoToRecord(Row), 0, 9) + '/' + ClearPage.Id.Value());
        Observer.Observe('first cleared', Format(ClearPage.First(), 0, 9) + '/' + ClearPage.Id.Value());
        ClearPage.Close();
        Observer.Expect('open', '1');
        Observer.Expect('after drilldown', '1');
        Observer.Expect('goto 4 filtered', 'false/1');
        Observer.Expect('after clear', '1');
        Observer.Expect('goto 4 cleared', 'true/4');
        Observer.Expect('first cleared', 'true/1');
        Observer.Verify();
    end;

    // Name order without OnAfterGetRecord and OnAfterGetCurrRecord; unmarked row 2.
    [Test]
    procedure Y1_Clear_NameKeyWithPartNoTriggers()
    var
        Row: Record "LT Y1 Clear Row";
        ClearPage: TestPage "LT Y1 Clear No Triggers";
    begin
        SeedRows();
        Row.Get(2);
        ClearPage.OpenView();
        Observer.Observe('open', ClearPage.Id.Value());
        ClearPage.Flagged.Drilldown();
        Observer.Observe('after drilldown', ClearPage.Id.Value());
        Observer.Observe('goto 2 filtered', Format(ClearPage.GoToRecord(Row), 0, 9) + '/' + ClearPage.Id.Value());
        ClearPage.ClearFilters.Invoke();
        Observer.Observe('after clear', ClearPage.Id.Value());
        Observer.Observe('goto 2 cleared', Format(ClearPage.GoToRecord(Row), 0, 9) + '/' + ClearPage.Id.Value());
        Observer.Observe('first cleared', Format(ClearPage.First(), 0, 9) + '/' + ClearPage.Id.Value());
        ClearPage.Close();
        Observer.Expect('open', '4');
        Observer.Expect('after drilldown', '4');
        Observer.Expect('goto 2 filtered', 'false/1');
        Observer.Expect('after clear', '1');
        Observer.Expect('goto 2 cleared', 'true/2');
        Observer.Expect('first cleared', 'true/4');
        Observer.Verify();
    end;
}
