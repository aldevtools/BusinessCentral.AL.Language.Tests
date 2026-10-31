// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-first-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 91735 - 91739 (writer Y15)
// Probe: written against SaaS BC 29 and the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: al-runner issue 6470 (related 6381, 6469). A non-editable List page over bins (Code, Room) keyed on Code. OnOpenPage sets
//   SetFilter(Room, '>0'). Action ShowAll runs SetRange(Room) and CurrPage.Update(false), so the view gets wider. Page 91736 has an
//   OnAfterGetRecord (the reporter's page, logged); page 91737 is the same without row triggers. The reporter's data: 25 bins A01..A25,
//   only A20 and A24 have Room 6, so the action adds rows before the row the page stands on (A20). Neighbours: rows added only after
//   the current row (A01 and A03 filtered), the page moved to A24 before the action, and a small table of 5 rows.
// Result (SaaS BC 29): after the action the page still stands on the row it stood on (A20, A24, A01, A03), but First returns true on
//   A01, the first row of the new view, and runs no OnAfterGetRecord; Next and Previous move from the current row in the new view
//   (A20 -> A21, A20 -> A19). The action itself runs OnAfterGetRecord 28 times (A20 first, A01 last). The same without row triggers.
// Source: al-runner issue 6470 (the reporter's repro passed on a real BC 29 container).
// BC versions: 27, 28, 29

table 91735 "LT Y15 WV Bin"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Room; Integer) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

page 91736 "LT Y15 WV Bins"
{
    PageType = List;
    SourceTable = "LT Y15 WV Bin";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(RoomShown; RoomShown) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ShowAll)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.SetRange(Room);
                    CurrPage.Update(false);
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.SetFilter(Room, '>0');
    end;

    trigger OnAfterGetRecord()
    begin
        RoomShown := Format(Rec.Room);
        Log.Add(Rec."Code");
    end;

    var
        Log: Codeunit "LT Y15 WV Log";
        RoomShown: Text[10];
}

page 91737 "LT Y15 WV Bins Plain"
{
    PageType = List;
    SourceTable = "LT Y15 WV Bin";
    Editable = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field(Room; Rec.Room) { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ShowAll)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.SetRange(Room);
                    CurrPage.Update(false);
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.SetFilter(Room, '>0');
    end;
}

codeunit 91738 "LT Y15 WV Log"
{
    SingleInstance = true;

    procedure Add(Entry: Text)
    begin
        Count += 1;
        if First = '' then
            First := Entry;
        Last := Entry;
    end;

    // Number of OnAfterGetRecord calls and the first and last row they ran for, then cleared.
    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Format(Count) + ':' + First + '-' + Last;
        Count := 0;
        First := '';
        Last := '';
        exit(Result);
    end;

    var
        Count: Integer;
        First: Text;
        Last: Text;
}

codeunit 91739 "LT Y15 WV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y15 WV Log";

    local procedure InsertBins(Total: Integer; RoomA: Integer; RoomB: Integer)
    var
        Bin: Record "LT Y15 WV Bin";
        i: Integer;
    begin
        Bin.DeleteAll();
        for i := 1 to Total do begin
            Bin."Code" := 'A' + Format(i, 2, '<Integer,2><Filler Character,0>');
            Bin.Room := 0;
            if i in [RoomA, RoomB] then
                Bin.Room := 6;
            Bin.Insert();
        end;
        Log.Take();
    end;

    local procedure CountToEnd(var Bins: TestPage "LT Y15 WV Bins"): Text
    var
        Count: Integer;
    begin
        repeat
            Count += 1;
        until not Bins.Next();
        exit(Format(Count) + '/' + Bins."Code".Value());
    end;

    local procedure CountToEndPlain(var Bins: TestPage "LT Y15 WV Bins Plain"): Text
    var
        Count: Integer;
    begin
        repeat
            Count += 1;
        until not Bins.Next();
        exit(Format(Count) + '/' + Bins."Code".Value());
    end;

    // The reporter's test: rows are added before the current row A20; First, the count with Next, and the triggers.
    [Test]
    procedure Y15_WV_ReporterShape()
    var
        Bins: TestPage "LT Y15 WV Bins";
    begin
        InsertBins(25, 20, 24);
        Bins.OpenView();
        Observer.Observe('open', Bins."Code".Value() + '/' + Bins.RoomShown.Value() + ' ' + Log.Take());
        Bins.ShowAll.Invoke();
        Observer.Observe('after action', Bins."Code".Value() + '/' + Bins.RoomShown.Value() + ' ' + Log.Take());
        Observer.Observe('first', Format(Bins.First(), 0, 9) + '/' + Bins."Code".Value() + '/' + Bins.RoomShown.Value() + ' ' + Log.Take());
        Observer.Observe('count', CountToEnd(Bins));
        Observer.Observe('last', Format(Bins.Last(), 0, 9) + '/' + Bins."Code".Value());
        Bins.Close();
        Observer.Expect('open', 'A20/6 3:A20-A20');
        Observer.Expect('after action', 'A20/6 28:A20-A01');
        Observer.Expect('first', 'true/A01/0 0:-');
        Observer.Expect('count', '25/A25');
        Observer.Expect('last', 'true/A25');
        Observer.Verify();
    end;

    // The same page without row triggers.
    [Test]
    procedure Y15_WV_NoRowTriggers()
    var
        Bins: TestPage "LT Y15 WV Bins Plain";
    begin
        InsertBins(25, 20, 24);
        Bins.OpenView();
        Observer.Observe('open', Bins."Code".Value());
        Bins.ShowAll.Invoke();
        Observer.Observe('after action', Bins."Code".Value());
        Observer.Observe('first', Format(Bins.First(), 0, 9) + '/' + Bins."Code".Value());
        Observer.Observe('count', CountToEndPlain(Bins));
        Bins.Close();
        Observer.Expect('open', 'A20');
        Observer.Expect('after action', 'A20');
        Observer.Expect('first', 'true/A01');
        Observer.Expect('count', '25/A25');
        Observer.Verify();
    end;

    // Next and Previous straight after the action, without First.
    [Test]
    procedure Y15_WV_NextPreviousAfterAction()
    var
        Bins: TestPage "LT Y15 WV Bins";
    begin
        InsertBins(25, 20, 24);
        Bins.OpenView();
        Bins.ShowAll.Invoke();
        Observer.Observe('next', Format(Bins.Next(), 0, 9) + '/' + Bins."Code".Value());
        Observer.Observe('previous', Format(Bins.Previous(), 0, 9) + '/' + Bins."Code".Value());
        Observer.Observe('previous 2', Format(Bins.Previous(), 0, 9) + '/' + Bins."Code".Value());
        Bins.Close();

        Bins.OpenView();
        Bins.ShowAll.Invoke();
        Observer.Observe('previous first', Format(Bins.Previous(), 0, 9) + '/' + Bins."Code".Value());
        Bins.Close();

        Bins.OpenView();
        Observer.Observe('next before action', Format(Bins.Next(), 0, 9) + '/' + Bins."Code".Value());
        Bins.ShowAll.Invoke();
        Observer.Observe('after action from A24', Bins."Code".Value());
        Observer.Observe('next from A24', Format(Bins.Next(), 0, 9) + '/' + Bins."Code".Value());
        Observer.Observe('first from A24', Format(Bins.First(), 0, 9) + '/' + Bins."Code".Value());
        Bins.Close();
        Observer.Expect('next', 'true/A21');
        Observer.Expect('previous', 'true/A20');
        Observer.Expect('previous 2', 'true/A19');
        Observer.Expect('previous first', 'true/A19');
        Observer.Expect('next before action', 'true/A24');
        Observer.Expect('after action from A24', 'A24');
        Observer.Expect('next from A24', 'true/A25');
        Observer.Expect('first from A24', 'true/A01');
        Observer.Verify();
    end;

    // Rows are added only after the current row: A01 and A03 have Room 6, the page stands on A01.
    [Test]
    procedure Y15_WV_RowsAddedAfter()
    var
        Bins: TestPage "LT Y15 WV Bins";
    begin
        InsertBins(25, 1, 3);
        Bins.OpenView();
        Observer.Observe('open', Bins."Code".Value());
        Observer.Observe('open next', Format(Bins.Next(), 0, 9) + '/' + Bins."Code".Value());
        Observer.Observe('open first', Format(Bins.First(), 0, 9) + '/' + Bins."Code".Value());
        Bins.ShowAll.Invoke();
        Observer.Observe('after action', Bins."Code".Value());
        Observer.Observe('next', Format(Bins.Next(), 0, 9) + '/' + Bins."Code".Value());
        Observer.Observe('first', Format(Bins.First(), 0, 9) + '/' + Bins."Code".Value());
        Observer.Observe('count', CountToEnd(Bins));
        Bins.Close();

        // The page stands on A03 when the action runs.
        Bins.OpenView();
        Bins.Next();
        Bins.ShowAll.Invoke();
        Observer.Observe('after action from A03', Bins."Code".Value());
        Observer.Observe('previous from A03', Format(Bins.Previous(), 0, 9) + '/' + Bins."Code".Value());
        Observer.Observe('first from A03', Format(Bins.First(), 0, 9) + '/' + Bins."Code".Value());
        Bins.Close();
        Observer.Expect('open', 'A01');
        Observer.Expect('open next', 'true/A03');
        Observer.Expect('open first', 'true/A01');
        Observer.Expect('after action', 'A01');
        Observer.Expect('next', 'true/A02');
        Observer.Expect('first', 'true/A01');
        Observer.Expect('count', '25/A25');
        Observer.Expect('after action from A03', 'A03');
        Observer.Expect('previous from A03', 'true/A02');
        Observer.Expect('first from A03', 'true/A01');
        Observer.Verify();
    end;

    // A small table: 5 rows, only A03 and A05 have Room 6.
    [Test]
    procedure Y15_WV_SmallTable()
    var
        Bins: TestPage "LT Y15 WV Bins";
    begin
        InsertBins(5, 3, 5);
        Bins.OpenView();
        Observer.Observe('open', Bins."Code".Value());
        Bins.ShowAll.Invoke();
        Observer.Observe('after action', Bins."Code".Value());
        Observer.Observe('first', Format(Bins.First(), 0, 9) + '/' + Bins."Code".Value());
        Observer.Observe('count', CountToEnd(Bins));
        Bins.Close();
        Observer.Expect('open', 'A03');
        Observer.Expect('after action', 'A03');
        Observer.Expect('first', 'true/A01');
        Observer.Expect('count', '5/A05');
        Observer.Verify();
    end;
}
