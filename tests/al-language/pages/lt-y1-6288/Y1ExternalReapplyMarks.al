// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 90920 - 90926 (writer Y1)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6288 (follow-up to 6139). A Worksheet with a ListPart (SubPageLink on Id), OnAfterGetRecord and OnAfterGetCurrRecord.
//   A tile's OnDrillDown marks the rows with Flag = true (rows 1 and 2 of 1..3), turns MarkedOnly on and calls CurrPage.Update(false).
//   Then code outside the page clears Flag of row 2 and sets a SingleInstance "refresh done" flag; the next OnAfterGetCurrRecord
//   consumes it, marks the flagged rows again (only row 1) and calls CurrPage.Update(false). The test then calls First and GoToRecord.
//   Contrast tests: the same steps without the external refresh, and GoToRecord without First after the refresh.
// Result (SaaS BC 29 and corpus CI, Windows and Linux alike): the TestPage still shows row 1 after the DrillDown; GoToRecord of row 2 returns
//   true (row 2 is marked). After the external refresh, First returns true on row 1 and its OnAfterGetCurrRecord reapplies the marks: then
//   GoToRecord of row 2 returns false and row 1 stays current, Next returns false, GoToRecord of row 1 returns true, and the refresh flag is
//   consumed. Without the refresh, GoToRecord of row 2 after First returns true (row 3, never marked: false). GoToRecord of row 2 right after
//   the refresh (no First) already returns false with row 1 current, and the refresh flag is consumed.
// Source: al-runner issue 6288 (the reporter's repro passed on a real BC 29 container).
// BC versions: 27, 28, 29

table 90920 "LT Y1 Reapply Row"
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

table 90921 "LT Y1 Reapply Detail"
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

page 90924 "LT Y1 Reapply Part"
{
    PageType = ListPart;
    SourceTable = "LT Y1 Reapply Detail";
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
                field(Id; Rec.Id) { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
            }
        }
    }
}

page 90925 "LT Y1 Reapply List"
{
    PageType = Worksheet;
    SourceTable = "LT Y1 Reapply Row";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(FlaggedTile; Tile)
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
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
            part(Details; "LT Y1 Reapply Part")
            {
                ApplicationArea = All;
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
        Marks: Codeunit "LT Y1 Reapply Marks";
        ExternalRefresh: Codeunit "LT Y1 External Refresh";
        Tile: Integer;
        RowText: Text;
        CurrText: Text;
}

codeunit 90922 "LT Y1 Reapply Marks"
{
    procedure MarkFlagged(var Row: Record "LT Y1 Reapply Row")
    var
        RowsInView: Record "LT Y1 Reapply Row";
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

codeunit 90923 "LT Y1 External Refresh"
{
    SingleInstance = true;

    procedure InvokeRefresh()
    var
        Row: Record "LT Y1 Reapply Row";
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

    procedure Reset()
    begin
        RefreshCompleted := false;
    end;

    var
        RefreshCompleted: Boolean;
}

codeunit 90926 "LT Y1 Reapply Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        ExternalRefresh: Codeunit "LT Y1 External Refresh";

    local procedure SeedRows()
    var
        Row: Record "LT Y1 Reapply Row";
        Detail: Record "LT Y1 Reapply Detail";
    begin
        ExternalRefresh.Reset();
        Row.DeleteAll();
        Detail.DeleteAll();
        AddRow(1, true);
        AddRow(2, true);
        AddRow(3, false);
    end;

    local procedure AddRow(Id: Integer; Flag: Boolean)
    var
        Row: Record "LT Y1 Reapply Row";
        Detail: Record "LT Y1 Reapply Detail";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Flag := Flag;
        Row.Insert();
        Detail.Init();
        Detail.Id := Id;
        Detail."Line No." := 10000;
        Detail.Insert();
    end;

    // The reporter's test: DrillDown, external refresh, First, GoToRecord of row 2.
    [Test]
    procedure Y1_Reapply_FirstAfterExternalRefresh()
    var
        Row: Record "LT Y1 Reapply Row";
        ReapplyPage: TestPage "LT Y1 Reapply List";
    begin
        SeedRows();
        ReapplyPage.OpenView();
        ReapplyPage.FlaggedTile.Drilldown();
        Observer.Observe('after drilldown', ReapplyPage.Id.Value());
        Row.Get(2);
        Observer.Observe('goto 2 before', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + ReapplyPage.Id.Value());
        ExternalRefresh.InvokeRefresh();
        Observer.Observe('first', Format(ReapplyPage.First(), 0, 9) + '/' + ReapplyPage.Id.Value());
        Observer.Observe('goto 2 after', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + ReapplyPage.Id.Value());
        Observer.Observe('next after', Format(ReapplyPage.Next(), 0, 9) + '/' + ReapplyPage.Id.Value());
        Row.Get(1);
        Observer.Observe('goto 1 after', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + ReapplyPage.Id.Value());
        Observer.Observe('refresh still pending', Format(ExternalRefresh.ConsumeRefreshCompleted(), 0, 9));
        ReapplyPage.Close();
        Observer.Expect('after drilldown', '1');
        Observer.Expect('goto 2 before', 'true/2');
        Observer.Expect('first', 'true/1');
        Observer.Expect('goto 2 after', 'false/1');
        Observer.Expect('next after', 'false/1');
        Observer.Expect('goto 1 after', 'true/1');
        Observer.Expect('refresh still pending', 'false');
        Observer.Verify();
    end;

    // Contrast: no external refresh; First and GoToRecord of row 2 within the marked view.
    [Test]
    procedure Y1_Reapply_FirstWithoutRefresh()
    var
        Row: Record "LT Y1 Reapply Row";
        ReapplyPage: TestPage "LT Y1 Reapply List";
    begin
        SeedRows();
        ReapplyPage.OpenView();
        ReapplyPage.FlaggedTile.Drilldown();
        Row.Get(2);
        Observer.Observe('goto 2 before', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + ReapplyPage.Id.Value());
        Observer.Observe('first', Format(ReapplyPage.First(), 0, 9) + '/' + ReapplyPage.Id.Value());
        Observer.Observe('goto 2 after', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + ReapplyPage.Id.Value());
        Row.Get(3);
        Observer.Observe('goto 3 after', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + ReapplyPage.Id.Value());
        ReapplyPage.Close();
        Observer.Expect('goto 2 before', 'true/2');
        Observer.Expect('first', 'true/1');
        Observer.Expect('goto 2 after', 'true/2');
        Observer.Expect('goto 3 after', 'false/2');
        Observer.Verify();
    end;

    // Contrast: after the external refresh GoToRecord of row 2 comes first, without First (the marks still hold row 2 at that point).
    [Test]
    procedure Y1_Reapply_GoToRecordAfterRefreshWithoutFirst()
    var
        Row: Record "LT Y1 Reapply Row";
        ReapplyPage: TestPage "LT Y1 Reapply List";
    begin
        SeedRows();
        ReapplyPage.OpenView();
        ReapplyPage.FlaggedTile.Drilldown();
        Observer.Observe('after drilldown', ReapplyPage.Id.Value());
        ExternalRefresh.InvokeRefresh();
        Row.Get(2);
        Observer.Observe('goto 2', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + ReapplyPage.Id.Value());
        Observer.Observe('refresh still pending', Format(ExternalRefresh.ConsumeRefreshCompleted(), 0, 9));
        Observer.Observe('goto 2 again', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + ReapplyPage.Id.Value());
        ReapplyPage.Close();
        Observer.Expect('after drilldown', '1');
        Observer.Expect('goto 2', 'false/1');
        Observer.Expect('refresh still pending', 'false');
        Observer.Expect('goto 2 again', 'false/1');
        Observer.Verify();
    end;
}
