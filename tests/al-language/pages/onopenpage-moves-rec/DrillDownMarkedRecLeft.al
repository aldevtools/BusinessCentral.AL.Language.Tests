// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-markedonly-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 95433, codeunit 95434 (log), pages 95435 - 95437, test codeunit 95438 (writer r6945)
// local object: the pages' own OnDrillDown, row triggers, SourceTableView and part are under test; the log must be a SingleInstance codeunit of its own
// Probe: al-runner issue 6946; written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: a List page (Editable = false, OnAfterGetRecord and OnAfterGetCurrRecord logged, a ListPart linked on Id) whose header fields'
//   OnDrillDown mark the late rows in a loop over Rec itself (ClearMarks, FindSet, Mark, Next) and call CurrPage.Update(false). The loop
//   leaves Rec on the last row of the view (row 4, not marked). Drilldowns: LeaveLast (MarkedOnly on, Rec stays on row 4), LeaveLastMarked
//   (MarkedOnly on, Rec moved to row 3, the last marked row), LeaveFirstMarked (MarkedOnly on, Rec moved to row 2, the first marked row),
//   MarkOnly (marks, MarkedOnly stays off, Rec on row 4), ShowAll (MarkedOnly off). Page 95436 has SourceTableView = sorting(Name), page
//   95437 is the same page in the primary key. After the drilldown: GoToRecord of marked and unmarked rows, and First / Next walks.
//   Rows: Id 1 A, 2 B late, 3 C late, 4 D (the order is the same in both keys).
//   Log: d<Id> / u<Id> = the drilldown before / after its CurrPage.Update, R<Id> = OnAfterGetRecord, C<Id> = OnAfterGetCurrRecord.
//   A step observes <answer>[<Id shown>]:<log>.
// BC versions: 27, 28, 29

table 95433 "PAG DdMark Op"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Code[20]) { }
        field(3; Late; Boolean) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }
}

page 95435 "PAG DdMark Part"
{
    PageType = ListPart;
    SourceTable = "PAG DdMark Op";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

page 95436 "PAG DdMark List Name"
{
    PageType = List;
    SourceTable = "PAG DdMark Op";
    SourceTableView = sorting(Name);
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(LeaveLast; LateTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Log.Add('d' + Format(Rec.Id));
                        MarkLate();
                        CurrPage.Update(false);
                        Log.Add('u' + Format(Rec.Id));
                    end;
                }
                field(LeaveLastMarked; LateTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Log.Add('d' + Format(Rec.Id));
                        MarkLate();
                        Rec.SetRange(Late, true);
                        Rec.FindLast();
                        Rec.SetRange(Late);
                        CurrPage.Update(false);
                        Log.Add('u' + Format(Rec.Id));
                    end;
                }
                field(LeaveFirstMarked; LateTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Log.Add('d' + Format(Rec.Id));
                        MarkLate();
                        Rec.SetRange(Late, true);
                        Rec.FindFirst();
                        Rec.SetRange(Late);
                        CurrPage.Update(false);
                        Log.Add('u' + Format(Rec.Id));
                    end;
                }
                field(MarkOnly; LateTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Log.Add('d' + Format(Rec.Id));
                        MarkLateNoFilter();
                        CurrPage.Update(false);
                        Log.Add('u' + Format(Rec.Id));
                    end;
                }
                field(ShowAll; LateTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Log.Add('d' + Format(Rec.Id));
                        Rec.MarkedOnly(false);
                        CurrPage.Update(false);
                        Log.Add('u' + Format(Rec.Id));
                    end;
                }
            }
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Shown; Shown) { ApplicationArea = All; }
            }
            part(Details; "PAG DdMark Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnOpenPage()
    begin
        LateTxt := 'Late';
    end;

    trigger OnAfterGetRecord()
    begin
        Shown := Rec.Id;
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec.Id));
    end;

    // The reporter's marking loop: it walks Rec itself and leaves it on the last row of the view.
    local procedure MarkLate()
    begin
        MarkLateNoFilter();
        Rec.MarkedOnly(true);
    end;

    local procedure MarkLateNoFilter()
    begin
        Rec.ClearMarks();
        if Rec.FindSet() then
            repeat
                if Rec.Late then
                    Rec.Mark(true);
            until Rec.Next() = 0;
    end;

    var
        Log: Codeunit "PAG DdMark Log";
        LateTxt: Text;
        Shown: Integer;
}

page 95437 "PAG DdMark List Pk"
{
    PageType = List;
    SourceTable = "PAG DdMark Op";
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Tiles)
            {
                field(LeaveLast; LateTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Log.Add('d' + Format(Rec.Id));
                        MarkLate();
                        CurrPage.Update(false);
                        Log.Add('u' + Format(Rec.Id));
                    end;
                }
                field(LeaveLastMarked; LateTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Log.Add('d' + Format(Rec.Id));
                        MarkLate();
                        Rec.SetRange(Late, true);
                        Rec.FindLast();
                        Rec.SetRange(Late);
                        CurrPage.Update(false);
                        Log.Add('u' + Format(Rec.Id));
                    end;
                }
                field(LeaveFirstMarked; LateTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Log.Add('d' + Format(Rec.Id));
                        MarkLate();
                        Rec.SetRange(Late, true);
                        Rec.FindFirst();
                        Rec.SetRange(Late);
                        CurrPage.Update(false);
                        Log.Add('u' + Format(Rec.Id));
                    end;
                }
                field(MarkOnly; LateTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Log.Add('d' + Format(Rec.Id));
                        MarkLateNoFilter();
                        CurrPage.Update(false);
                        Log.Add('u' + Format(Rec.Id));
                    end;
                }
                field(ShowAll; LateTxt)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Log.Add('d' + Format(Rec.Id));
                        Rec.MarkedOnly(false);
                        CurrPage.Update(false);
                        Log.Add('u' + Format(Rec.Id));
                    end;
                }
            }
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Shown; Shown) { ApplicationArea = All; }
            }
            part(Details; "PAG DdMark Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }

    trigger OnOpenPage()
    begin
        LateTxt := 'Late';
    end;

    trigger OnAfterGetRecord()
    begin
        Shown := Rec.Id;
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec.Id));
    end;

    // The reporter's marking loop: it walks Rec itself and leaves it on the last row of the view.
    local procedure MarkLate()
    begin
        MarkLateNoFilter();
        Rec.MarkedOnly(true);
    end;

    local procedure MarkLateNoFilter()
    begin
        Rec.ClearMarks();
        if Rec.FindSet() then
            repeat
                if Rec.Late then
                    Rec.Mark(true);
            until Rec.Next() = 0;
    end;

    var
        Log: Codeunit "PAG DdMark Log";
        LateTxt: Text;
        Shown: Integer;
}

codeunit 95434 "PAG DdMark Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

codeunit 95438 "PAG DdMark Rec Left Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PAG DdMark Log";

    local procedure Seed()
    var
        Op: Record "PAG DdMark Op";
        i: Integer;
    begin
        Op.DeleteAll();
        for i := 1 to 4 do begin
            Op.Init();
            Op.Id := i;
            Op.Name := CopyStr('ABCD', i, 1);
            Op.Late := i in [2, 3];
            Op.Insert();
        end;
        Log.Take();
    end;

    local procedure Shows(var P: TestPage "PAG DdMark List Name"): Text
    begin
        exit('[' + P.Id.Value() + ']:' + Log.Take());
    end;

    local procedure Shows(var P: TestPage "PAG DdMark List Pk"): Text
    begin
        exit('[' + P.Id.Value() + ']:' + Log.Take());
    end;

    local procedure GoTo(var P: TestPage "PAG DdMark List Name"; Id: Integer)
    var
        Op: Record "PAG DdMark Op";
    begin
        Op.Get(Id);
        Observer.Observe('goto ' + Format(Id), Format(P.GoToRecord(Op)) + Shows(P));
    end;

    local procedure GoTo(var P: TestPage "PAG DdMark List Pk"; Id: Integer)
    var
        Op: Record "PAG DdMark Op";
    begin
        Op.Get(Id);
        Observer.Observe('goto ' + Format(Id), Format(P.GoToRecord(Op)) + Shows(P));
    end;

    local procedure Walk(var P: TestPage "PAG DdMark List Name")
    begin
        Observer.Observe('first', Format(P.First()) + Shows(P));
        Observer.Observe('next', Format(P.Next()) + Shows(P));
        Observer.Observe('next 2', Format(P.Next()) + Shows(P));
    end;

    local procedure Walk(var P: TestPage "PAG DdMark List Pk")
    begin
        Observer.Observe('first', Format(P.First()) + Shows(P));
        Observer.Observe('next', Format(P.Next()) + Shows(P));
        Observer.Observe('next 2', Format(P.Next()) + Shows(P));
    end;

    // the key ByName: the reporter's shape, Rec left on row 4 (unmarked); GoToRecord of 3, then of 4.
    [Test]
    procedure Name_LeaveUnmarked_GoToMarkedThenUnmarked()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLast.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 3);
        Observer.Observe('part', P.Details.Id.Value());
        GoTo(P, 4);
        P.Close();
        Observer.Finish();
    end;

    // the key ByName: Rec left on row 4 (unmarked); GoToRecord of 2, the first marked row.
    [Test]
    procedure Name_LeaveUnmarked_GoToFirstMarked()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLast.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 2);
        GoTo(P, 3);
        P.Close();
        Observer.Finish();
    end;

    // the key ByName: Rec left on row 4 (unmarked); GoToRecord of 4 first, then of 1.
    [Test]
    procedure Name_LeaveUnmarked_GoToUnmarked()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLast.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 4);
        GoTo(P, 1);
        P.Close();
        Observer.Finish();
    end;

    // the key ByName: Rec left on row 4 (unmarked); First, Next, Next.
    [Test]
    procedure Name_LeaveUnmarked_Walk()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLast.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    // the key ByName: Rec left on row 3 (the last marked row); GoToRecord of 2, then of 4.
    [Test]
    procedure Name_LeaveLastMarked_GoToOther()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLastMarked.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 2);
        GoTo(P, 4);
        P.Close();
        Observer.Finish();
    end;

    // the key ByName: Rec left on row 3 (the last marked row); First, Next, Next.
    [Test]
    procedure Name_LeaveLastMarked_Walk()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLastMarked.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    // the key ByName: Rec left on row 2 (the first marked row, row 3 marked after it); GoToRecord of 2, 3, then 4.
    [Test]
    procedure Name_LeaveFirstMarked_GoTo()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveFirstMarked.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 2);
        GoTo(P, 3);
        GoTo(P, 4);
        P.Close();
        Observer.Finish();
    end;

    // the key ByName: Rec left on row 2 (the first marked row); First, Next, Next.
    [Test]
    procedure Name_LeaveFirstMarked_Walk()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveFirstMarked.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    // the key ByName: the drilldown marks rows 2 and 3 but leaves MarkedOnly off, Rec on row 4; GoToRecord of 3, then of 1.
    [Test]
    procedure Name_MarkedOnlyOff_GoTo()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.MarkOnly.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 3);
        GoTo(P, 1);
        P.Close();
        Observer.Finish();
    end;

    // the key ByName: marks without MarkedOnly, Rec on row 4; First, Next, Next.
    [Test]
    procedure Name_MarkedOnlyOff_Walk()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.MarkOnly.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    // the key ByName: Rec left on row 4 with MarkedOnly on, then a second drilldown turns MarkedOnly off; GoToRecord of 4, then of 1.
    [Test]
    procedure Name_MarkedOnlyOnThenOff_GoTo()
    var
        P: TestPage "PAG DdMark List Name";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLast.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        P.ShowAll.Drilldown();
        Observer.Observe('show all', Shows(P));
        GoTo(P, 4);
        GoTo(P, 1);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: the reporter's shape, Rec left on row 4 (unmarked); GoToRecord of 3, then of 4.
    [Test]
    procedure Pk_LeaveUnmarked_GoToMarkedThenUnmarked()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLast.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 3);
        Observer.Observe('part', P.Details.Id.Value());
        GoTo(P, 4);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: Rec left on row 4 (unmarked); GoToRecord of 2, the first marked row.
    [Test]
    procedure Pk_LeaveUnmarked_GoToFirstMarked()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLast.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 2);
        GoTo(P, 3);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: Rec left on row 4 (unmarked); GoToRecord of 4 first, then of 1.
    [Test]
    procedure Pk_LeaveUnmarked_GoToUnmarked()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLast.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 4);
        GoTo(P, 1);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: Rec left on row 4 (unmarked); First, Next, Next.
    [Test]
    procedure Pk_LeaveUnmarked_Walk()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLast.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: Rec left on row 3 (the last marked row); GoToRecord of 2, then of 4.
    [Test]
    procedure Pk_LeaveLastMarked_GoToOther()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLastMarked.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 2);
        GoTo(P, 4);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: Rec left on row 3 (the last marked row); First, Next, Next.
    [Test]
    procedure Pk_LeaveLastMarked_Walk()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLastMarked.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: Rec left on row 2 (the first marked row, row 3 marked after it); GoToRecord of 2, 3, then 4.
    [Test]
    procedure Pk_LeaveFirstMarked_GoTo()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveFirstMarked.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 2);
        GoTo(P, 3);
        GoTo(P, 4);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: Rec left on row 2 (the first marked row); First, Next, Next.
    [Test]
    procedure Pk_LeaveFirstMarked_Walk()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveFirstMarked.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: the drilldown marks rows 2 and 3 but leaves MarkedOnly off, Rec on row 4; GoToRecord of 3, then of 1.
    [Test]
    procedure Pk_MarkedOnlyOff_GoTo()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.MarkOnly.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        GoTo(P, 3);
        GoTo(P, 1);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: marks without MarkedOnly, Rec on row 4; First, Next, Next.
    [Test]
    procedure Pk_MarkedOnlyOff_Walk()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.MarkOnly.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        Walk(P);
        P.Close();
        Observer.Finish();
    end;

    // the primary key: Rec left on row 4 with MarkedOnly on, then a second drilldown turns MarkedOnly off; GoToRecord of 4, then of 1.
    [Test]
    procedure Pk_MarkedOnlyOnThenOff_GoTo()
    var
        P: TestPage "PAG DdMark List Pk";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('open', Shows(P));
        P.LeaveLast.Drilldown();
        Observer.Observe('drilldown', Shows(P));
        P.ShowAll.Drilldown();
        Observer.Observe('show all', Shows(P));
        GoTo(P, 4);
        GoTo(P, 1);
        P.Close();
        Observer.Finish();
    end;
}
