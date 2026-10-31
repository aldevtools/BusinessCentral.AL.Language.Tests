// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 91720 - 91726 (writer Y15)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6467, follow-up to 6288 (primary-key view: pages/lt-y1-6288/Y1ExternalReapplyMarks.al). The same Worksheet
//   with a ListPart (SubPageLink on Id), but OnOpenPage sets Rec.SetCurrentKey(SortOrder) and SortOrder = 4 - Id, so the key order
//   is row 3, 2, 1. A tile's OnDrillDown marks the rows with Flag = true (rows 1 and 2), turns MarkedOnly on and calls
//   CurrPage.Update(false). Code outside the page clears Flag of row 2 and sets a SingleInstance "refresh done" flag; the next
//   OnAfterGetCurrRecord consumes it, marks the flagged rows again (only row 1), calls CurrPage.Update(false) and notes that it ran.
//   The page logs OnAfterGetCurrRecord (agcr<Id>).
//   Version difference: without the refresh, First in the marked view gives row 2 then Next row 1 on BC 27.5 and 29 (SaaS and CI),
//   but row 1 then Next false on BC 28.5 (CI, Linux; not checked on Windows 28.5 yet).
// Result (SaaS BC 29): the page opens on row 3 (first in key order) and stays on row 3 after the DrillDown. GoToRecord of row 2 then
//   returns false and leaves the page on row 1 (the reporter's before=false/1). After the refresh First returns true on row 1, its
//   OnAfterGetCurrRecord reapplies the marks; then GoToRecord of row 2 is false, Next and Previous are false, Last stays on row 1.
// Source: al-runner issue 6467 (the reporter's repro passed on a real BC 29 container).
// BC versions: 27, 28, 29

table 91720 "LT Y15 SK Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Flag; Boolean) { }
        field(3; SortOrder; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(BySortOrder; SortOrder) { }
    }
}

table 91721 "LT Y15 SK Detail"
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

codeunit 91722 "LT Y15 SK Marks"
{
    procedure MarkFlagged(var Row: Record "LT Y15 SK Row")
    var
        RowsInView: Record "LT Y15 SK Row";
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

codeunit 91723 "LT Y15 SK External Refresh"
{
    SingleInstance = true;

    procedure InvokeRefresh()
    var
        Row: Record "LT Y15 SK Row";
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

    procedure NoteReapplied()
    begin
        RefreshReapplied := true;
    end;

    procedure WasReapplied(): Boolean
    begin
        exit(RefreshReapplied);
    end;

    procedure AddLog(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure TakeLog(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure Reset()
    begin
        RefreshCompleted := false;
        RefreshReapplied := false;
        Entries := '';
    end;

    var
        RefreshCompleted: Boolean;
        RefreshReapplied: Boolean;
        Entries: Text;
}

page 91724 "LT Y15 SK Part"
{
    PageType = ListPart;
    SourceTable = "LT Y15 SK Detail";
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

page 91725 "LT Y15 SK List"
{
    PageType = Worksheet;
    SourceTable = "LT Y15 SK Row";
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
            part(Details; "LT Y15 SK Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey(SortOrder);
    end;

    trigger OnAfterGetRecord()
    begin
        RowText := Format(Rec.Id);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrText := Format(Rec.Id);
        ExternalRefresh.AddLog('agcr' + CurrText);
        if ExternalRefresh.ConsumeRefreshCompleted() then begin
            Marks.MarkFlagged(Rec);
            CurrPage.Update(false);
            ExternalRefresh.NoteReapplied();
        end;
    end;

    var
        Marks: Codeunit "LT Y15 SK Marks";
        ExternalRefresh: Codeunit "LT Y15 SK External Refresh";
        Tile: Integer;
        RowText: Text;
        CurrText: Text;
}

codeunit 91726 "LT Y15 SK Reapply Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        ExternalRefresh: Codeunit "LT Y15 SK External Refresh";

    local procedure SeedRows()
    var
        Row: Record "LT Y15 SK Row";
        Detail: Record "LT Y15 SK Detail";
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
        Row: Record "LT Y15 SK Row";
        Detail: Record "LT Y15 SK Detail";
    begin
        Row.Init();
        Row.Id := Id;
        Row.SortOrder := 4 - Id;
        Row.Flag := Flag;
        Row.Insert();
        Detail.Init();
        Detail.Id := Id;
        Detail."Line No." := 10000;
        Detail.Insert();
    end;

    local procedure Here(var ReapplyPage: TestPage "LT Y15 SK List"): Text
    begin
        exit(ReapplyPage.Id.Value() + '/' + ReapplyPage.Details.Id.Value());
    end;

    // The reporter's test: DrillDown, GoToRecord of row 2, external refresh, First, GoToRecord of row 2; plus the moves after it.
    [Test]
    procedure Y15_SK_FirstAfterExternalRefresh()
    var
        Row: Record "LT Y15 SK Row";
        ReapplyPage: TestPage "LT Y15 SK List";
    begin
        SeedRows();
        ReapplyPage.OpenView();
        Observer.Observe('open', Here(ReapplyPage) + ' ' + ExternalRefresh.TakeLog());
        ReapplyPage.FlaggedTile.Drilldown();
        Observer.Observe('after drilldown', Here(ReapplyPage) + ' ' + ExternalRefresh.TakeLog());
        Row.Get(2);
        Observer.Observe('goto 2 before', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + Here(ReapplyPage) + ' ' + ExternalRefresh.TakeLog());
        ExternalRefresh.InvokeRefresh();
        Observer.Observe('first', Format(ReapplyPage.First(), 0, 9) + '/' + Here(ReapplyPage) + ' ' + ExternalRefresh.TakeLog());
        Observer.Observe('reapplied', Format(ExternalRefresh.WasReapplied(), 0, 9));
        Observer.Observe('goto 2 after', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('next after', Format(ReapplyPage.Next(), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('previous after', Format(ReapplyPage.Previous(), 0, 9) + '/' + Here(ReapplyPage));
        Row.Get(1);
        Observer.Observe('goto 1 after', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + Here(ReapplyPage));
        Row.Get(3);
        Observer.Observe('goto 3 after', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('last after', Format(ReapplyPage.Last(), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('refresh still pending', Format(ExternalRefresh.ConsumeRefreshCompleted(), 0, 9));
        ReapplyPage.Close();
        Observer.Expect('open', '3/3 agcr3');
        Observer.Expect('after drilldown', '3/3 ');
        Observer.Expect('goto 2 before', 'false/1/1 agcr1;agcr2;agcr1');
        Observer.Expect('first', 'true/1/1 agcr2;agcr1');
        Observer.Expect('reapplied', 'true');
        Observer.Expect('goto 2 after', 'false/1/1');
        Observer.Expect('next after', 'false/1/1');
        Observer.Expect('previous after', 'false/1/1');
        Observer.Expect('goto 1 after', 'true/1/1');
        Observer.Expect('goto 3 after', 'false/1/1');
        Observer.Expect('last after', 'true/1/1');
        Observer.Expect('refresh still pending', 'false');
        Observer.Verify();
    end;

    // Contrast: no external refresh; the moves inside the marked view (rows 2 and 1, in key order 2 then 1).
    [Test]
    procedure Y15_SK_MovesWithoutRefresh()
    var
        Row: Record "LT Y15 SK Row";
        ReapplyPage: TestPage "LT Y15 SK List";
    begin
        SeedRows();
        ReapplyPage.OpenView();
        Observer.Observe('open first', Format(ReapplyPage.First(), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('open next', Format(ReapplyPage.Next(), 0, 9) + '/' + Here(ReapplyPage));
        ReapplyPage.FlaggedTile.Drilldown();
        Observer.Observe('after drilldown', Here(ReapplyPage));
        Observer.Observe('first', Format(ReapplyPage.First(), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('next', Format(ReapplyPage.Next(), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('next 2', Format(ReapplyPage.Next(), 0, 9) + '/' + Here(ReapplyPage));
        Row.Get(2);
        Observer.Observe('goto 2', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + Here(ReapplyPage));
        Row.Get(3);
        Observer.Observe('goto 3', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('last', Format(ReapplyPage.Last(), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('reapplied', Format(ExternalRefresh.WasReapplied(), 0, 9));
        ReapplyPage.Close();
        Observer.Expect('open first', 'true/3/3');
        Observer.Expect('open next', 'true/2/2');
        Observer.Expect('after drilldown', '2/2');
#if BC28PLUS and not BC29PLUS
        // BC 28.5 (corpus CI, Linux): First in the marked secondary-key view goes to row 1 and Next finds no further row.
        Observer.Expect('first', 'true/1/1');
        Observer.Expect('next', 'false/1/1');
#else
        Observer.Expect('first', 'true/2/2');
        Observer.Expect('next', 'true/1/1');
#endif
        Observer.Expect('next 2', 'false/1/1');
        Observer.Expect('goto 2', 'true/2/2');
        Observer.Expect('goto 3', 'false/2/1');
        Observer.Expect('last', 'true/1/1');
        Observer.Expect('reapplied', 'false');
        Observer.Verify();
    end;

    // Contrast: after the refresh GoToRecord of row 1 comes first, without First.
    [Test]
    procedure Y15_SK_GoToRecordAfterRefreshWithoutFirst()
    var
        Row: Record "LT Y15 SK Row";
        ReapplyPage: TestPage "LT Y15 SK List";
    begin
        SeedRows();
        ReapplyPage.OpenView();
        ReapplyPage.FlaggedTile.Drilldown();
        ExternalRefresh.TakeLog();
        ExternalRefresh.InvokeRefresh();
        Row.Get(1);
        Observer.Observe('goto 1', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + Here(ReapplyPage) + ' ' + ExternalRefresh.TakeLog());
        Observer.Observe('reapplied', Format(ExternalRefresh.WasReapplied(), 0, 9));
        Row.Get(2);
        Observer.Observe('goto 2', Format(ReapplyPage.GoToRecord(Row), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('first', Format(ReapplyPage.First(), 0, 9) + '/' + Here(ReapplyPage));
        Observer.Observe('next', Format(ReapplyPage.Next(), 0, 9) + '/' + Here(ReapplyPage));
        ReapplyPage.Close();
        Observer.Expect('goto 1', 'true/1/1 agcr1');
        Observer.Expect('reapplied', 'true');
        Observer.Expect('goto 2', 'false/1/1');
        Observer.Expect('first', 'true/1/1');
        Observer.Expect('next', 'false/1/1');
        Observer.Verify();
    end;
}
