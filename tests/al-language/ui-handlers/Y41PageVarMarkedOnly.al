// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-settableview-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 92800 (Y41Log.al); table 92361, page 92362, test codeunit 92363
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: a Page variable handed a record whose MarkedOnly is on, through SetTableView (filter + marks, the Microsoft shape with
//   FilterGroup(-1) and FilterGroup(2), no marks at all, a temporary record) and through SetRecord: what the page's OnOpenPage sees
//   (GetFilters, MarkedOnly, Count), the row the page stands on when the handler gets it and the rows the handler can walk, and what
//   the Page variable's SetSelectionFilter hands back after the handler moved to a row and answered LookupOK.
//   Rows R1..R6, Group 1 for R1-R4 and 2 for R5-R6, Qty = 10 x the row number.
//   misc/lt-protected-var-abs-query-views/P146ViewMarkedTemp.al pins Page.RunModal(Id, Rec) with MarkedOnly.
// Measured (27.5, 28.5, 29.0 alike): SetTableView hands the marks over: OnOpenPage sees 'Marked: Yes, Group: 1', MarkedOnly Yes, and
//   the page shows only the marked rows (none when nothing is marked; the same for a temporary record). After LookupOK on R4, the
//   Page variable's SetSelectionFilter hands back the marked set (MarkedOnly Yes, both rows), not the row R4. The FilterGroup(-1) /
//   FilterGroup(2) shape shows the marked rows, GetFilters 'Marked: Yes'. SetRecord does not hand marks over: all 6 rows, on R4.
// BC versions: all (CI)

table 92361 "LT Y41 PVM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Group; Integer) { }
        field(3; Qty; Decimal) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

page 92362 "LT Y41 PVM List"
{
    PageType = List;
    SourceTable = "LT Y41 PVM Row";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(GroupCtl; Rec.Group) { ApplicationArea = All; }
                field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('open filters=' + Rec.GetFilters() + ' mo=' + Format(Rec.MarkedOnly()) + ' count=' + Format(Rec.Count()) + ' at=' + Rec."No.");
    end;
}

codeunit 92363 "LT Y41 Page Var MarkedOnly"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT Y41 PVM Row";
        Log: Record "LT Y41 Log";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 6 do begin
            Row.Init();
            Row."No." := 'R' + Format(i);
            if i <= 4 then
                Row.Group := 1
            else
                Row.Group := 2;
            Row.Qty := 10 * i;
            Row.Insert();
        end;
        Log.ClearLog();
    end;

    local procedure Walk(var P: TestPage "LT Y41 PVM List")
    var
        Log: Record "LT Y41 Log";
        Shown: Text;
    begin
        Shown := 'at=' + P.NoCtl.Value() + ' shown=';
        if P.First() then
            repeat
                Shown += P.NoCtl.Value() + ',';
            until not P.Next();
        Log.AddLine(Shown);
    end;

    local procedure MarkRows(var R: Record "LT Y41 PVM Row"; Keys: Text)
    var
        Part: Text;
    begin
        foreach Part in Keys.Split(',') do begin
            R.Get(Part);
            R.Mark(true);
        end;
    end;

    local procedure Describe(Prefix: Text; var R: Record "LT Y41 PVM Row")
    var
        Rows: Text;
    begin
        Obs.Observe(Prefix + 'filters', R.GetFilters());
        Obs.Observe(Prefix + 'markedonly', Format(R.MarkedOnly()));
        Obs.Observe(Prefix + 'count', Format(R.Count()));
        if R.FindSet() then
            repeat
                Rows += R."No." + ',';
            until R.Next() = 0;
        Obs.Observe(Prefix + 'rows', Rows);
    end;

    local procedure LogNow(): Text
    var
        Log: Record "LT Y41 Log";
    begin
        exit(Log.Dump());
    end;

    [ModalPageHandler]
    procedure WalkCancelHandler(var P: TestPage "LT Y41 PVM List")
    begin
        Walk(P);
        P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure WalkGoToR4OkHandler(var P: TestPage "LT Y41 PVM List")
    var
        Log: Record "LT Y41 Log";
    begin
        Walk(P);
        Log.AddLine('goto=' + Format(P.GoToKey('R4')));
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('WalkCancelHandler')]
    procedure PVM_SetTableView_MarkedOnly_Shown()
    var
        R: Record "LT Y41 PVM Row";
        L: Page "LT Y41 PVM List";
    begin
        Seed();
        R.SetRange(Group, 1);
        MarkRows(R, 'R2,R4');
        R.MarkedOnly(true);
        L.SetTableView(R);
        L.LookupMode(true);
        Obs.Observe('action', Format(L.RunModal()));
        Obs.Observe('log', LogNow());
        Obs.Expect('action', 'LookupCancel');
        Obs.Expect('log', 'open filters=Marked: Yes, Group: 1 mo=Yes count=2 at=;at=R2 shown=R2,R4,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkGoToR4OkHandler')]
    procedure PVM_SetTableView_MarkedOnly_SelectionAfter()
    var
        R: Record "LT Y41 PVM Row";
        R2: Record "LT Y41 PVM Row";
        L: Page "LT Y41 PVM List";
    begin
        Seed();
        R.SetRange(Group, 1);
        MarkRows(R, 'R2,R4');
        R.MarkedOnly(true);
        L.SetTableView(R);
        L.LookupMode(true);
        Obs.Observe('action', Format(L.RunModal()));
        Obs.Observe('log', LogNow());
        L.SetSelectionFilter(R2);
        Describe('sel ', R2);
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('log', 'open filters=Marked: Yes, Group: 1 mo=Yes count=2 at=;at=R2 shown=R2,R4,;goto=Yes');
        Obs.Expect('sel filters', 'Marked: Yes, Group: 1');
        Obs.Expect('sel markedonly', 'Yes');
        Obs.Expect('sel count', '2');
        Obs.Expect('sel rows', 'R2,R4,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkGoToR4OkHandler')]
    procedure PVM_SetTableView_MarkedOnly_FilterGroups()
    var
        R: Record "LT Y41 PVM Row";
        R2: Record "LT Y41 PVM Row";
        L: Page "LT Y41 PVM List";
    begin
        Seed();
        R.FilterGroup(-1);
        R.SetFilter(Qty, '>=%1', 30);
        R.SetFilter(Group, '%1', 2);
        R.FilterGroup(2);
        R.SetRange(Group, 1);
        if R.FindSet() then
            repeat
                R.Mark(true);
            until R.Next() = 0;
        R.MarkedOnly(true);
        R.FilterGroup(0);
        L.SetTableView(R);
        L.LookupMode(true);
        Obs.Observe('action', Format(L.RunModal()));
        Obs.Observe('log', LogNow());
        L.SetSelectionFilter(R2);
        Describe('sel ', R2);
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('log', 'open filters=Marked: Yes mo=Yes count=2 at=;at=R3 shown=R3,R4,;goto=Yes');
        Obs.Expect('sel filters', 'Marked: Yes');
        Obs.Expect('sel markedonly', 'Yes');
        Obs.Expect('sel count', '2');
        Obs.Expect('sel rows', 'R3,R4,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkCancelHandler')]
    procedure PVM_SetTableView_MarkedOnly_NoMarks()
    var
        R: Record "LT Y41 PVM Row";
        L: Page "LT Y41 PVM List";
    begin
        Seed();
        R.SetRange(Group, 1);
        R.MarkedOnly(true);
        L.SetTableView(R);
        L.LookupMode(true);
        Obs.Observe('action', Format(L.RunModal()));
        Obs.Observe('log', LogNow());
        Obs.Expect('action', 'LookupCancel');
        Obs.Expect('log', 'open filters=Marked: Yes, Group: 1 mo=Yes count=0 at=;at= shown=');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkCancelHandler')]
    procedure PVM_SetRecord_MarkedOnly()
    var
        R: Record "LT Y41 PVM Row";
        L: Page "LT Y41 PVM List";
    begin
        Seed();
        MarkRows(R, 'R2,R4');
        R.MarkedOnly(true);
        R.Get('R4');
        L.SetRecord(R);
        L.LookupMode(true);
        Obs.Observe('action', Format(L.RunModal()));
        Obs.Observe('log', LogNow());
        Obs.Expect('action', 'LookupCancel');
        Obs.Expect('log', 'open filters= mo=No count=6 at=R4;at=R4 shown=R1,R2,R3,R4,R5,R6,');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('WalkCancelHandler')]
    procedure PVM_SetTableView_MarkedOnly_TempRec()
    var
        Src: Record "LT Y41 PVM Row";
        T: Record "LT Y41 PVM Row" temporary;
        L: Page "LT Y41 PVM List";
    begin
        Seed();
        if Src.FindSet() then
            repeat
                T := Src;
                T.Insert();
            until Src.Next() = 0;
        T.SetRange(Group, 1);
        MarkRows(T, 'R2,R4');
        T.MarkedOnly(true);
        L.SetTableView(T);
        L.LookupMode(true);
        Obs.Observe('action', Format(L.RunModal()));
        Obs.Observe('log', LogNow());
        Obs.Expect('action', 'LookupCancel');
        Obs.Expect('log', 'open filters=Marked: Yes, Group: 1 mo=Yes count=2 at=;at=R2 shown=R2,R4,');
        Obs.Verify();
    end;
}
