// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-workdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 94960-94961
// Probe (al-runner issue 6862): WorkDate(Date) used as an expression. Pinned elsewhere: the statement form sets the work date
//   (session/TestSessionFunctions.al:63-65), WorkDate(0D) as a statement (session/TestProbeSessionMiscContracts.al:829).
//   Not pinned: what the call returns (the new date? the old one?), where an expression is allowed (assignment, argument, condition, exit,
//   Variant, Format), what it does to a later WorkDate(), Today(), CalcDate with and without a base date and the W filter letter, and
//   inside a TestPage run. Every date is a fixed one: no value depends on the run date.
// BC versions: 27, 28, 29

codeunit 94960 "LT R6862 WorkDate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure R6862_Expression_ReturnsWhat()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Date;
        Prev: Date;
        Result: Date;
    begin
        Saved := WorkDate();
        WorkDate(DMY2Date(1, 2, 2031));
        Prev := WorkDate();
        Result := WorkDate(DMY2Date(15, 3, 2032));
        Observer.Observe('result', Format(Result, 0, 9));
        Observer.Observe('result = new', Format(Result = DMY2Date(15, 3, 2032)));
        Observer.Observe('result = old', Format(Result = Prev));
        Observer.Observe('WorkDate after', Format(WorkDate(), 0, 9));
        Observer.Observe('WorkDate = new', Format(WorkDate() = DMY2Date(15, 3, 2032)));
        Result := WorkDate(DMY2Date(15, 3, 2032));
        Observer.Observe('same date result', Format(Result, 0, 9));
        WorkDate(Saved);
        Observer.Expect('result', '2032-03-15');
        Observer.Expect('result = new', 'Yes');
        Observer.Expect('result = old', 'No');
        Observer.Expect('WorkDate after', '2032-03-15');
        Observer.Expect('WorkDate = new', 'Yes');
        Observer.Expect('same date result', '2032-03-15');
        Observer.Verify();
    end;

    [Test]
    procedure R6862_Expression_EmptyDate()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Date;
        Result: Date;
    begin
        Saved := WorkDate();
        WorkDate(DMY2Date(1, 2, 2031));
        Result := WorkDate(0D);
        Observer.Observe('empty: result = Today', Format(Result = Today()));
        Observer.Observe('empty: result = 0D', Format(Result = 0D));
        Observer.Observe('empty: WorkDate = Today', Format(WorkDate() = Today()));
        Observer.Observe('empty: WorkDate = 0D', Format(WorkDate() = 0D));
        WorkDate(Saved);
        Observer.Expect('empty: result = Today', 'Yes');
        Observer.Expect('empty: result = 0D', 'No');
        Observer.Expect('empty: WorkDate = Today', 'Yes');
        Observer.Expect('empty: WorkDate = 0D', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure R6862_Expression_ClosingDate()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Date;
        Result: Date;
    begin
        Saved := WorkDate();
        WorkDate(DMY2Date(1, 2, 2031));
        Result := WorkDate(ClosingDate(DMY2Date(31, 12, 2031)));
        Observer.Observe('closing: result', Format(Result, 0, 9));
        Observer.Observe('closing: WorkDate after', Format(WorkDate(), 0, 9));
        Observer.Observe('closing: WorkDate = Normal', Format(WorkDate() = DMY2Date(31, 12, 2031)));
        WorkDate(Saved);
        Observer.Expect('closing: result', '2031-12-31');
        Observer.Expect('closing: WorkDate after', '2031-12-31');
        Observer.Expect('closing: WorkDate = Normal', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure R6862_Expression_Positions()
    var
        Observer: Codeunit "Probe Observer";
        DateRec: Record Date;
        V: Variant;
        T: Text;
        Saved: Date;
        D: Date;
    begin
        Saved := WorkDate();
        D := DMY2Date(15, 3, 2032);
        if WorkDate(D) = D then
            Observer.Observe('condition', 'equal')
        else
            Observer.Observe('condition', 'not equal');
        Observer.Observe('exit', Format(ExitIt(DMY2Date(16, 3, 2032)), 0, 9));
        Observer.Observe('exit then WorkDate', Format(WorkDate(), 0, 9));
        Observer.Observe('as argument', Format(Pass(WorkDate(DMY2Date(17, 3, 2032))), 0, 9));
        V := WorkDate(DMY2Date(18, 3, 2032));
        Observer.Observe('variant is date', Format(V.IsDate()));
        if V.IsDate() then
            Observer.Observe('variant value', Format(V, 0, 9));
        T := Format(WorkDate(DMY2Date(19, 3, 2032)), 0, 9);
        Observer.Observe('format of call', T);
        D := DMY2Date(20, 3, 2032);
        Observer.Observe('Date.Get', Format(DateRec.Get(DateRec."Period Type"::Date, WorkDate(D))));
        Observer.Observe('Date.Get start', Format(DateRec."Period Start", 0, 9));
        D := DMY2Date(21, 3, 2032);
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange("Period Start", WorkDate(D));
        Observer.Observe('SetRange count', Format(DateRec.Count()));
        Observer.Observe('nested', Format(WorkDate(WorkDate(DMY2Date(22, 3, 2032))), 0, 9));
        WorkDate(Saved);
        Observer.Expect('condition', 'equal');
        Observer.Expect('exit', '2032-03-16');
        Observer.Expect('exit then WorkDate', '2032-03-16');
        Observer.Expect('as argument', '2032-03-17');
        Observer.Expect('variant is date', 'Yes');
        Observer.Expect('variant value', '2032-03-18');
        Observer.Expect('format of call', '2032-03-19');
        Observer.Expect('Date.Get', 'Yes');
        Observer.Expect('Date.Get start', '2032-03-20');
        Observer.Expect('SetRange count', '1');
        Observer.Expect('nested', '2032-03-22');
        Observer.Verify();
    end;

    [Test]
    procedure R6862_Expression_LaterReads()
    var
        Observer: Codeunit "Probe Observer";
        DateRec: Record Date;
        Saved: Date;
        Result: Date;
    begin
        Saved := WorkDate();
        Result := WorkDate(DMY2Date(10, 5, 2032));
        Observer.Observe('Today unchanged', Format(Today() <> DMY2Date(10, 5, 2032)));
        Observer.Observe('CalcDate base WorkDate', Format(CalcDate('<CM>', WorkDate()), 0, 9));
        Observer.Observe('CalcDate 1D no base is tomorrow', Format(CalcDate('<1D>') = Today() + 1));
        Observer.Observe('CalcDate base result', Format(CalcDate('<CM+1D>', Result), 0, 9));
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetFilter("Period Start", 'W');
        Observer.Observe('filter W count', Format(DateRec.Count()));
        if DateRec.FindFirst() then
            Observer.Observe('filter W first', Format(DateRec."Period Start", 0, 9));
        DateRec.SetFilter("Period Start", '%1', WorkDate());
        Observer.Observe('filter %1 count', Format(DateRec.Count()));
        WorkDate(Saved);
        Observer.Expect('Today unchanged', 'Yes');
        Observer.Expect('CalcDate base WorkDate', '2032-05-31');
        Observer.Expect('CalcDate 1D no base is tomorrow', 'Yes');
        Observer.Expect('CalcDate base result', '2032-06-01');
        Observer.Expect('filter W count', '1');
        Observer.Expect('filter W first', '2032-05-10');
        Observer.Expect('filter %1 count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure R6862_Expression_InATestPage()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT R6862 Card";
        Saved: Date;
    begin
        Saved := WorkDate();
        WorkDate(DMY2Date(1, 2, 2031));
        Card.OpenView();
        Observer.Observe('page: returned by OnOpenPage', Card.Returned.Value());
        Observer.Observe('page: WorkDate before OnOpenPage', Card.Before.Value());
        Observer.Observe('page: WorkDate after OnOpenPage', Card.After.Value());
        Observer.Observe('test: WorkDate after open', Format(WorkDate(), 0, 9));
        Card.SetIt.Invoke();
        Observer.Observe('page: returned by action', Card.Returned.Value());
        Observer.Observe('test: WorkDate after action', Format(WorkDate(), 0, 9));
        Card.Close();
        Observer.Observe('test: WorkDate after close', Format(WorkDate(), 0, 9));
        WorkDate(Saved);
        Observer.Expect('page: returned by OnOpenPage', '2033-03-02');
        Observer.Expect('page: WorkDate before OnOpenPage', '2031-02-01');
        Observer.Expect('page: WorkDate after OnOpenPage', '2033-03-02');
        Observer.Expect('test: WorkDate after open', '2033-03-02');
        Observer.Expect('page: returned by action', '2034-04-03');
        Observer.Expect('test: WorkDate after action', '2034-04-03');
        Observer.Expect('test: WorkDate after close', '2034-04-03');
        Observer.Verify();
    end;

    [Test]
    procedure R6862_Expression_AcrossTests_1()
    var
        Observer: Codeunit "Probe Observer";
        Result: Date;
    begin
        Result := WorkDate(DMY2Date(5, 6, 2033));
        Observer.Observe('stays: first test returned', Format(Result, 0, 9));
        Observer.Expect('stays: first test returned', '2033-06-05');
        Observer.Verify();
    end;

    [Test]
    procedure R6862_Expression_AcrossTests_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('stays: second test WorkDate', Format(WorkDate(), 0, 9));
        Observer.Observe('stays: second test = 2033-06-05', Format(WorkDate() = DMY2Date(5, 6, 2033)));
        Observer.Expect('stays: second test WorkDate', '2033-06-05');
        Observer.Expect('stays: second test = 2033-06-05', 'Yes');
        Observer.Verify();
    end;

    local procedure ExitIt(D: Date): Date
    begin
        exit(WorkDate(D));
    end;

    local procedure Pass(D: Date): Date
    begin
        exit(D);
    end;
}

page 94961 "LT R6862 Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Returned; ReturnedText) { ApplicationArea = All; }
            field(Before; BeforeText) { ApplicationArea = All; }
            field(After; AfterText) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetIt)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ReturnedText := Format(WorkDate(DMY2Date(3, 4, 2034)), 0, 9);
                    AfterText := Format(WorkDate(), 0, 9);
                end;
            }
        }
    }

    var
        ReturnedText: Text;
        BeforeText: Text;
        AfterText: Text;

    trigger OnOpenPage()
    begin
        BeforeText := Format(WorkDate(), 0, 9);
        ReturnedText := Format(WorkDate(DMY2Date(2, 3, 2033)), 0, 9);
        AfterText := Format(WorkDate(), 0, 9);
    end;
}
