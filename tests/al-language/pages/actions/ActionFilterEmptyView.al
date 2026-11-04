// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects table 95427, codeunit 95428 (log), page 95429, test codeunit 95430 (writer r6945)
// local object: the page's own row triggers and actions are under test; the log must be a SingleInstance codeunit of its own
// Probe: al-runner issue 6945; written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: an action of a List page (Editable = false, OnAfterGetRecord and OnAfterGetCurrRecord logged) sets a filter on Rec and calls
//   CurrPage.Update(false) or CurrPage.Update(true): a filter that leaves no row (Included = true, no row included), a filter that
//   leaves some rows (Id 3..4) with the current row inside or outside it, and an action that clears the filters again. After each
//   action: the log, the row shown (Id and the page variable Shown that OnAfterGetRecord sets), and First / Next / Last / Previous /
//   GoToRecord / GoToKey with their answers. Rows: Id 1, 2, 3, 4, none included.
//   Log: a<Id> / u<Id> = the action before / after its CurrPage.Update, R<Id> = OnAfterGetRecord, C<Id> = OnAfterGetCurrRecord.
// Result (27.5, 28.5, 29.0): a filter that leaves no row shows a blank row (Id and Shown blank) with Update(false) and Update(true)
//   alike; no OnAfterGetCurrRecord runs. After CurrPage.Update, OnAfterGetRecord runs for rows outside the new view: on 27.5 and 29.0
//   once, for the row before the current one (the row after it when there is none); on 28.5 for every other row, from the row before
//   the current one up to the first, then the rows after it. First, Next, Last, Previous, GoToRecord and GoToKey then answer false and
//   the row stays blank. An action invoked on the blank row sees a blank Rec (a0); clearing the filters there shows the rows again
//   from the first one, read as at open. A filter that keeps rows behaves as the pinned cases (pages/list-order/AiListOrderTests.al).
// BC versions: 27, 28, 29

table 95427 "PAG ActEmpty Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Included; Boolean) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 95429 "PAG ActEmpty List"
{
    PageType = List;
    SourceTable = "PAG ActEmpty Row";
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
                field(Shown; Shown) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NoneFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('a' + Format(Rec.Id));
                    Rec.SetRange(Included, true);
                    CurrPage.Update(false);
                    Log.Add('u' + Format(Rec.Id));
                end;
            }
            action(NoneTrue)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('a' + Format(Rec.Id));
                    Rec.SetRange(Included, true);
                    CurrPage.Update(true);
                    Log.Add('u' + Format(Rec.Id));
                end;
            }
            action(SomeFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('a' + Format(Rec.Id));
                    Rec.SetRange(Id, 3, 4);
                    CurrPage.Update(false);
                    Log.Add('u' + Format(Rec.Id));
                end;
            }
            action(SomeTrue)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('a' + Format(Rec.Id));
                    Rec.SetRange(Id, 3, 4);
                    CurrPage.Update(true);
                    Log.Add('u' + Format(Rec.Id));
                end;
            }
            action(ClearFalse)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('a' + Format(Rec.Id));
                    Rec.SetRange(Included);
                    Rec.SetRange(Id);
                    CurrPage.Update(false);
                    Log.Add('u' + Format(Rec.Id));
                end;
            }
            action(ClearTrue)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Log.Add('a' + Format(Rec.Id));
                    Rec.SetRange(Included);
                    Rec.SetRange(Id);
                    CurrPage.Update(true);
                    Log.Add('u' + Format(Rec.Id));
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Shown := Rec.Id;
        Log.Add('R' + Format(Rec.Id));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C' + Format(Rec.Id));
    end;

    var
        Log: Codeunit "PAG ActEmpty Log";
        Shown: Integer;
}

codeunit 95428 "PAG ActEmpty Log"
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

codeunit 95430 "PAG ActEmpty Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "PAG ActEmpty Log";

    local procedure Seed()
    var
        Row: Record "PAG ActEmpty Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 4 do begin
            Row.Init();
            Row.Id := i;
            Row.Insert();
        end;
        Log.Take();
    end;

    local procedure Shows(var P: TestPage "PAG ActEmpty List"): Text
    begin
        exit('[' + P.Id.Value() + '|' + P.Shown.Value() + ']:' + Log.Take());
    end;

    local procedure Open(var P: TestPage "PAG ActEmpty List"; Row: Integer)
    var
        i: Integer;
    begin
        Seed();
        P.OpenView();
        P.First();
        for i := 2 to Row do
            P.Next();
        Observer.Observe('on', Shows(P));
    end;

    local procedure Moves(var P: TestPage "PAG ActEmpty List")
    begin
        Observer.Observe('next', Format(P.Next()) + Shows(P));
        Observer.Observe('first', Format(P.First()) + Shows(P));
        Observer.Observe('next 2', Format(P.Next()) + Shows(P));
        Observer.Observe('last', Format(P.Last()) + Shows(P));
        Observer.Observe('previous', Format(P.Previous()) + Shows(P));
    end;

    local procedure GoTo(var P: TestPage "PAG ActEmpty List"; Id: Integer)
    var
        Row: Record "PAG ActEmpty Row";
    begin
        Row.Get(Id);
        Observer.Observe('goto ' + Format(Id), Format(P.GoToRecord(Row)) + Shows(P));
    end;

    // The reporter's shape: on row 1, the action leaves no row, Update(false); then the moves.
    [Test]
    procedure Action_NoRowsLeft_UpdateFalse_Moves()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 1);
        P.NoneFalse.Invoke();
        Observer.Observe('action', Shows(P));
        Moves(P);
        P.Close();
        Observer.Expect('on', '[1|1]:R1;R2;R3;R4;R1;R1;C1');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('action', '[|]:R1;a1;u1;R2;R3;R4');
#else
        Observer.Expect('action', '[|]:R1;a1;u1;R2');
#endif
        Observer.Expect('next', 'No[|]:');
        Observer.Expect('first', 'No[|]:');
        Observer.Expect('next 2', 'No[|]:');
        Observer.Expect('last', 'No[|]:');
        Observer.Expect('previous', 'No[|]:');
        Observer.Verify();
    end;

    // The same with Update(true).
    [Test]
    procedure Action_NoRowsLeft_UpdateTrue_Moves()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 1);
        P.NoneTrue.Invoke();
        Observer.Observe('action', Shows(P));
        Moves(P);
        P.Close();
        Observer.Expect('on', '[1|1]:R1;R2;R3;R4;R1;R1;C1');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('action', '[|]:R1;a1;u1;R2;R3;R4');
#else
        Observer.Expect('action', '[|]:R1;a1;u1;R2');
#endif
        Observer.Expect('next', 'No[|]:');
        Observer.Expect('first', 'No[|]:');
        Observer.Expect('next 2', 'No[|]:');
        Observer.Expect('last', 'No[|]:');
        Observer.Expect('previous', 'No[|]:');
        Observer.Verify();
    end;

    // No row left, Update(false): GoToRecord and GoToKey of a row outside the view.
    [Test]
    procedure Action_NoRowsLeft_UpdateFalse_GoTo()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 1);
        P.NoneFalse.Invoke();
        Observer.Observe('action', Shows(P));
        GoTo(P, 2);
        Observer.Observe('gotokey 3', Format(P.GoToKey(3)) + Shows(P));
        P.Close();
        Observer.Expect('on', '[1|1]:R1;R2;R3;R4;R1;R1;C1');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('action', '[|]:R1;a1;u1;R2;R3;R4');
#else
        Observer.Expect('action', '[|]:R1;a1;u1;R2');
#endif
        Observer.Expect('goto 2', 'No[|]:');
        Observer.Expect('gotokey 3', 'No[|]:');
        Observer.Verify();
    end;

    // No row left, Update(true): GoToRecord and GoToKey of a row outside the view.
    [Test]
    procedure Action_NoRowsLeft_UpdateTrue_GoTo()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 1);
        P.NoneTrue.Invoke();
        Observer.Observe('action', Shows(P));
        GoTo(P, 2);
        Observer.Observe('gotokey 3', Format(P.GoToKey(3)) + Shows(P));
        P.Close();
        Observer.Expect('on', '[1|1]:R1;R2;R3;R4;R1;R1;C1');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('action', '[|]:R1;a1;u1;R2;R3;R4');
#else
        Observer.Expect('action', '[|]:R1;a1;u1;R2');
#endif
        Observer.Expect('goto 2', 'No[|]:');
        Observer.Expect('gotokey 3', 'No[|]:');
        Observer.Verify();
    end;

    // From row 3 (not the first row), no row left, Update(false).
    [Test]
    procedure Action_NoRowsLeft_FromLaterRow_UpdateFalse()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 3);
        P.NoneFalse.Invoke();
        Observer.Observe('action', Shows(P));
        Observer.Observe('first', Format(P.First()) + Shows(P));
        P.Close();
        Observer.Expect('on', '[3|3]:R1;R2;R3;R4;R1;R1;C1;R2;R2;C2;R3;R3;C3');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('action', '[|]:R3;a3;u3;R2;R1;R4');
#else
        Observer.Expect('action', '[|]:R3;a3;u3;R2');
#endif
        Observer.Expect('first', 'No[|]:');
        Observer.Verify();
    end;

    // From row 3, no row left, Update(true).
    [Test]
    procedure Action_NoRowsLeft_FromLaterRow_UpdateTrue()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 3);
        P.NoneTrue.Invoke();
        Observer.Observe('action', Shows(P));
        Observer.Observe('first', Format(P.First()) + Shows(P));
        P.Close();
        Observer.Expect('on', '[3|3]:R1;R2;R3;R4;R1;R1;C1;R2;R2;C2;R3;R3;C3');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('action', '[|]:R3;a3;u3;R2;R1;R4');
#else
        Observer.Expect('action', '[|]:R3;a3;u3;R2');
#endif
        Observer.Expect('first', 'No[|]:');
        Observer.Verify();
    end;

    // No row left, then an action clears the filters again (Update(false) both times): the page shows rows again.
    [Test]
    procedure Action_NoRowsLeft_ThenCleared_UpdateFalse()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 2);
        P.NoneFalse.Invoke();
        Observer.Observe('action', Shows(P));
        P.ClearFalse.Invoke();
        Observer.Observe('cleared', Shows(P));
        Moves(P);
        P.Close();
        Observer.Expect('on', '[2|2]:R1;R2;R3;R4;R1;R1;C1;R2;R2;C2');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('action', '[|]:R2;a2;u2;R1;R3;R4');
#else
        Observer.Expect('action', '[|]:R2;a2;u2;R1');
#endif
        Observer.Expect('cleared', '[1|1]:a0;u0;R1;R2;R3;R4;R1;R1;C1');
        Observer.Expect('next', 'Yes[2|2]:R2;R2;C2');
        Observer.Expect('first', 'Yes[1|1]:R1;R1;C1');
        Observer.Expect('next 2', 'Yes[2|2]:R2;R2;C2');
        Observer.Expect('last', 'Yes[4|4]:R4;R4;C4');
        Observer.Expect('previous', 'Yes[3|3]:R3;R3;C3');
        Observer.Verify();
    end;

    // The same with Update(true) both times.
    [Test]
    procedure Action_NoRowsLeft_ThenCleared_UpdateTrue()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 2);
        P.NoneTrue.Invoke();
        Observer.Observe('action', Shows(P));
        P.ClearTrue.Invoke();
        Observer.Observe('cleared', Shows(P));
        Moves(P);
        P.Close();
        Observer.Expect('on', '[2|2]:R1;R2;R3;R4;R1;R1;C1;R2;R2;C2');
#if BC28PLUS and not BC29PLUS
        Observer.Expect('action', '[|]:R2;a2;u2;R1;R3;R4');
#else
        Observer.Expect('action', '[|]:R2;a2;u2;R1');
#endif
        Observer.Expect('cleared', '[1|1]:a0;u0;R1;R2;R3;R4;R1;R1;C1');
        Observer.Expect('next', 'Yes[2|2]:R2;R2;C2');
        Observer.Expect('first', 'Yes[1|1]:R1;R1;C1');
        Observer.Expect('next 2', 'Yes[2|2]:R2;R2;C2');
        Observer.Expect('last', 'Yes[4|4]:R4;R4;C4');
        Observer.Expect('previous', 'Yes[3|3]:R3;R3;C3');
        Observer.Verify();
    end;

    // On row 1, the action leaves rows 3 and 4 (the current row drops out, rows follow), Update(false).
    [Test]
    procedure Action_SomeRowsLeft_CurrentDropped_UpdateFalse()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 1);
        P.SomeFalse.Invoke();
        Observer.Observe('action', Shows(P));
        Moves(P);
        GoTo(P, 1);
        P.Close();
        Observer.Expect('on', '[1|1]:R1;R2;R3;R4;R1;R1;C1');
        Observer.Expect('action', '[3|3]:R1;a1;u1;R3;R3;R4;R3;R3;C3');
        Observer.Expect('next', 'Yes[4|4]:R4;R4;C4');
        Observer.Expect('first', 'Yes[3|3]:R3;R3;C3');
        Observer.Expect('next 2', 'Yes[4|4]:R4;R4;C4');
        Observer.Expect('last', 'Yes[4|4]:');
        Observer.Expect('previous', 'Yes[3|3]:R3;R3;C3');
        Observer.Expect('goto 1', 'No[3|3]:R4;R4;C4;R3;R3;C3');
        Observer.Verify();
    end;

    // The same with Update(true).
    [Test]
    procedure Action_SomeRowsLeft_CurrentDropped_UpdateTrue()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 1);
        P.SomeTrue.Invoke();
        Observer.Observe('action', Shows(P));
        Moves(P);
        GoTo(P, 1);
        P.Close();
        Observer.Expect('on', '[1|1]:R1;R2;R3;R4;R1;R1;C1');
        Observer.Expect('action', '[3|3]:R1;a1;u1;R3;R3;R4;R3;R3;C3');
        Observer.Expect('next', 'Yes[4|4]:R4;R4;C4');
        Observer.Expect('first', 'Yes[3|3]:R3;R3;C3');
        Observer.Expect('next 2', 'Yes[4|4]:R4;R4;C4');
        Observer.Expect('last', 'Yes[4|4]:');
        Observer.Expect('previous', 'Yes[3|3]:R3;R3;C3');
        Observer.Expect('goto 1', 'No[3|3]:R4;R4;C4;R3;R3;C3');
        Observer.Verify();
    end;

    // On row 3, the action leaves rows 3 and 4 (the current row stays), Update(false).
    [Test]
    procedure Action_SomeRowsLeft_CurrentKept_UpdateFalse()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 3);
        P.SomeFalse.Invoke();
        Observer.Observe('action', Shows(P));
        Moves(P);
        GoTo(P, 4);
        P.Close();
        Observer.Expect('on', '[3|3]:R1;R2;R3;R4;R1;R1;C1;R2;R2;C2;R3;R3;C3');
        Observer.Expect('action', '[3|3]:R3;a3;u3;R3;R3;R4;R3;R3;C3');
        Observer.Expect('next', 'Yes[4|4]:R4;R4;C4');
        Observer.Expect('first', 'Yes[3|3]:R3;R3;C3');
        Observer.Expect('next 2', 'Yes[4|4]:R4;R4;C4');
        Observer.Expect('last', 'Yes[4|4]:');
        Observer.Expect('previous', 'Yes[3|3]:R3;R3;C3');
        Observer.Expect('goto 4', 'Yes[4|4]:R4;R4;C4');
        Observer.Verify();
    end;

    // The same with Update(true).
    [Test]
    procedure Action_SomeRowsLeft_CurrentKept_UpdateTrue()
    var
        P: TestPage "PAG ActEmpty List";
    begin
        Open(P, 3);
        P.SomeTrue.Invoke();
        Observer.Observe('action', Shows(P));
        Moves(P);
        GoTo(P, 4);
        P.Close();
        Observer.Expect('on', '[3|3]:R1;R2;R3;R4;R1;R1;C1;R2;R2;C2;R3;R3;C3');
        Observer.Expect('action', '[3|3]:R3;a3;u3;R3;R3;R4;R3;R3;C3');
        Observer.Expect('next', 'Yes[4|4]:R4;R4;C4');
        Observer.Expect('first', 'Yes[3|3]:R3;R3;C3');
        Observer.Expect('next 2', 'Yes[4|4]:R4;R4;C4');
        Observer.Expect('last', 'Yes[4|4]:');
        Observer.Expect('previous', 'Yes[3|3]:R3;R3;C3');
        Observer.Expect('goto 4', 'Yes[4|4]:R4;R4;C4');
        Observer.Verify();
    end;
}
