// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 93430, test codeunit 93431
// Writer NP4 (NP lane, 2026-10-30). Probe: (1) Evaluate of a text made of a TAB (alone, around a number) into Integer, Decimal, Date, Boolean and Option, used as a
//   statement: error text and code or the value. (2) Reads under Record.ReadIsolation RepeatableRead and UpdLock (FindSet, Get, Find('-'), IsEmpty, Count, FindFirst) and
//   IsInWriteTransaction after each. (3) Windows Language Get(1078).
// Writer Y9 (NP lane 1030e, 2026-10-30): own table 91461, codeunit 91460 (tests Y9_* in codeunit 93431). Probe: (4) Get, Find('='), IsEmpty, Count, Next and
//   CalcFields under UpdLock, RepeatableRead (and ReadCommitted) as the FIRST read of a transaction, with the isolation set before the Commit and after it:
//   IsInWriteTransaction before and after the read, and what a guarded `if Codeunit.Run(...)` does after it.
// BC versions: 27, 28, 29

table 93430 "LT NP4 Misc Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 93431 "LT NP4 Misc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Option Integer,Decimal,Date,Boolean,Option;

    [TryFunction]
    local procedure TryEvaluate(Txt: Text; var Shown: Text)
    var
        IntVar: Integer;
        DecVar: Decimal;
        DateVar: Date;
        BoolVar: Boolean;
        OptVar: Option A,B;
    begin
        case Mode of
            Mode::Integer:
                begin
                    Evaluate(IntVar, Txt);
                    Shown := Format(IntVar);
                end;
            Mode::Decimal:
                begin
                    Evaluate(DecVar, Txt);
                    Shown := Format(DecVar);
                end;
            Mode::Date:
                begin
                    Evaluate(DateVar, Txt);
                    Shown := Format(DateVar, 0, 9);
                end;
            Mode::Boolean:
                begin
                    Evaluate(BoolVar, Txt);
                    Shown := Format(BoolVar);
                end;
            Mode::Option:
                begin
                    Evaluate(OptVar, Txt);
                    Shown := Format(OptVar);
                end;
        end;
    end;

    local procedure Ev(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        Shown: Text;
    begin
        if TryEvaluate(Txt, Shown) then
            Observer.Observe(Name, 'ok|' + Shown)
        else begin
            Observer.Observe(Name, CopyStr('error:' + GetLastErrorText() + '|' + GetLastErrorCode(), 1, 600));
            ClearLastError();
        end;
    end;

    local procedure AllShapes(var Observer: Codeunit "Probe Observer")
    var
        Tab: Text[1];
    begin
        Tab[1] := 9;
        Ev(Observer, 'tab', Tab);
        // a Date target reads '1' as day 1 of the current month: not asserted
        if Mode <> Mode::Date then begin
            Ev(Observer, 'tab_one', Tab + '1');
            Ev(Observer, 'one_tab', '1' + Tab);
        end;
        Ev(Observer, 'tab_tab', Tab + Tab);
        Ev(Observer, 'empty', '');
        Ev(Observer, 'space', ' ');
    end;

    [Test]
    procedure NP4_Evaluate_Tab_Integer()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := Mode::Integer;
        AllShapes(Observer);
        Observer.Expect('tab', 'error:The value "\t" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('tab_one', 'ok|1');
        Observer.Expect('one_tab', 'ok|1');
        Observer.Expect('tab_tab', 'error:The value "\t\t" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('empty', 'error:The value "" can''t be evaluated into type Integer.|Evaluate');
        Observer.Expect('space', 'error:The value " " can''t be evaluated into type Integer.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_Evaluate_Tab_Decimal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := Mode::Decimal;
        AllShapes(Observer);
        Observer.Expect('tab', 'error:The value "\t" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('tab_one', 'ok|1');
        Observer.Expect('one_tab', 'ok|1');
        Observer.Expect('tab_tab', 'error:The value "\t\t" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('empty', 'error:The value "" can''t be evaluated into type Decimal.|Evaluate');
        Observer.Expect('space', 'error:The value " " can''t be evaluated into type Decimal.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_Evaluate_Tab_Date()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := Mode::Date;
        AllShapes(Observer);
        Observer.Expect('tab', 'ok|');
        Observer.Expect('tab_tab', 'ok|');
        Observer.Expect('empty', 'ok|');
        Observer.Expect('space', 'ok|');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_Evaluate_Tab_Boolean()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := Mode::Boolean;
        AllShapes(Observer);
        Observer.Expect('tab', 'error:The value "" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('tab_one', 'ok|Yes');
        Observer.Expect('one_tab', 'ok|Yes');
        Observer.Expect('tab_tab', 'error:The value "" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('empty', 'error:The value "" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Expect('space', 'error:The value "" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_Evaluate_Tab_Option()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Mode := Mode::Option;
        AllShapes(Observer);
        Observer.Expect('tab', 'error:''\t'' is not an option. The existing options are: A,B|InvalidOptionString');
        Observer.Expect('tab_one', 'ok|B');
        Observer.Expect('one_tab', 'ok|B');
        Observer.Expect('tab_tab', 'error:''\t\t'' is not an option. The existing options are: A,B|InvalidOptionString');
        Observer.Expect('empty', 'error:'''' is not an option. The existing options are: A,B|InvalidOptionString');
        Observer.Expect('space', 'error:'' '' is not an option. The existing options are: A,B|InvalidOptionString');
        Observer.Verify();
    end;

    local procedure SeedRows()
    var
        Row: Record "LT NP4 Misc Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Commit();
    end;

    local procedure Reads(var Observer: Codeunit "Probe Observer"; Level: Text; Isolation: IsolationLevel)
    var
        Row: Record "LT NP4 Misc Row";
        Ok: Boolean;
    begin
        Row.ReadIsolation := Isolation;
        Ok := Row.FindSet();
        Observer.Observe(Level + ' findset', Format(Ok) + '|' + Format(Row.Id) + '|' + Format(IsInWriteTransaction()));
        Clear(Row);
        Row.ReadIsolation := Isolation;
        Ok := Row.Get(2);
        Observer.Observe(Level + ' get', Format(Ok) + '|' + Format(Row.Name) + '|' + Format(IsInWriteTransaction()));
        Clear(Row);
        Row.ReadIsolation := Isolation;
        Ok := Row.Find('-');
        Observer.Observe(Level + ' find first', Format(Ok) + '|' + Format(Row.Id) + '|' + Format(IsInWriteTransaction()));
        Clear(Row);
        Row.ReadIsolation := Isolation;
        Observer.Observe(Level + ' isempty', Format(Row.IsEmpty()) + '|' + Format(IsInWriteTransaction()));
        Observer.Observe(Level + ' count', Format(Row.Count()) + '|' + Format(IsInWriteTransaction()));
        Ok := Row.FindFirst();
        Observer.Observe(Level + ' findfirst', Format(Ok) + '|' + Format(Row.Id) + '|' + Format(IsInWriteTransaction()));
        Row.ReadIsolation := Isolation;
        Ok := Row.FindLast();
        Observer.Observe(Level + ' findlast', Format(Ok) + '|' + Format(Row.Id) + '|' + Format(IsInWriteTransaction()));
    end;

    [Test]
    procedure NP4_ReadIsolation_RepeatableRead_Reads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        Reads(Observer, 'repeatable', IsolationLevel::RepeatableRead);
        Observer.Expect('repeatable findset', 'Yes|1|Yes');
        Observer.Expect('repeatable get', 'Yes|two|Yes');
        Observer.Expect('repeatable find first', 'Yes|1|Yes');
        Observer.Expect('repeatable isempty', 'No|Yes');
        Observer.Expect('repeatable count', '2|Yes');
        Observer.Expect('repeatable findfirst', 'Yes|1|Yes');
        Observer.Expect('repeatable findlast', 'Yes|2|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_ReadIsolation_UpdLock_Reads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        Reads(Observer, 'updlock', IsolationLevel::UpdLock);
        Observer.Expect('updlock findset', 'Yes|1|Yes');
        Observer.Expect('updlock get', 'Yes|two|Yes');
        Observer.Expect('updlock find first', 'Yes|1|Yes');
        Observer.Expect('updlock isempty', 'No|Yes');
        Observer.Expect('updlock count', '2|Yes');
        Observer.Expect('updlock findfirst', 'Yes|1|Yes');
        Observer.Expect('updlock findlast', 'Yes|2|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_ReadIsolation_ReadCommitted_Reads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows();
        Reads(Observer, 'committed', IsolationLevel::ReadCommitted);
        Observer.Expect('committed findset', 'Yes|1|No');
        Observer.Expect('committed get', 'Yes|two|No');
        Observer.Expect('committed find first', 'Yes|1|No');
        Observer.Expect('committed isempty', 'No|No');
        Observer.Expect('committed count', '2|No');
        Observer.Expect('committed findfirst', 'Yes|1|No');
        Observer.Expect('committed findlast', 'Yes|2|No');
        Observer.Verify();
    end;

    [Test]
    procedure NP4_WindowsLanguage_Get1078()
    var
        Observer: Codeunit "Probe Observer";
        Lang: Record "Windows Language";
    begin
        Observer.Observe('get', Format(Lang.Get(1078)));
        Observer.Observe('id', Format(Lang."Language ID"));
        Observer.Observe('name', Lang.Name);
        Observer.Observe('abbreviated', Lang."Abbreviated Name");
        Observer.Observe('tag', Lang."Language Tag");
        Observer.Expect('get', 'Yes');
        Observer.Expect('id', '1078');
        Observer.Expect('name', 'Afrikaans (South Africa)');
        Observer.Expect('abbreviated', 'AFK');
        Observer.Expect('tag', 'af-ZA');
        Observer.Verify();
    end;

    // ---- Writer Y9 (NP lane 1030e, 2026-10-30): one read under UpdLock or RepeatableRead as the FIRST read of a new transaction ----

    local procedure Y9Seed()
    var
        Row: Record "LT Y9 RI Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Commit();
    end;

    // SetBeforeCommit: ReadIsolation is set, then Commit, then the read (the isolation was set in the previous transaction).
    // Otherwise: Commit, then ReadIsolation is set, then the read. 'before' is IsInWriteTransaction just before the read.
    // After the read a guarded `if Codeunit.Run(...)` runs inside asserterror; its error (or the 'ran' text) is recorded.
    local procedure Y9FirstRead(var Observer: Codeunit "Probe Observer"; Prefix: Text; Op: Text; Isolation: IsolationLevel; SetBeforeCommit: Boolean)
    var
        Row: Record "LT Y9 RI Row";
        Before: Text;
        Shown: Text;
        RunOk: Boolean;
    begin
        if Op = 'next' then begin
            if SetBeforeCommit then
                Row.ReadIsolation := Isolation;
            Row.FindFirst();
        end;
        if SetBeforeCommit then
            Row.ReadIsolation := Isolation;
        Commit();
        if not SetBeforeCommit then
            Row.ReadIsolation := Isolation;
        Before := Format(IsInWriteTransaction());
        case Op of
            'get':
                Shown := Format(Row.Get(2)) + '/' + Row.Name;
            'find=':
                begin
                    Row.Id := 2;
                    Shown := Format(Row.Find('=')) + '/' + Row.Name;
                end;
            'isempty':
                Shown := Format(Row.IsEmpty());
            'count':
                Shown := Format(Row.Count());
            'next':
                Shown := Format(Row.Next()) + '/' + Format(Row.Id);
            'calcfields':
                begin
                    Row.Id := 2;
                    Row.CalcFields(Cnt);
                    Shown := Format(Row.Cnt);
                end;
        end;
        Observer.Observe(Prefix + ' ' + Op, 'before=' + Before + '|' + Shown + '|after=' + Format(IsInWriteTransaction()));
        ClearLastError();
        asserterror begin
            RunOk := Codeunit.Run(Codeunit::"LT Y9 RI Noop");
            Error('ran=%1 tx=%2', RunOk, IsInWriteTransaction());
        end;
        Observer.Observe(Prefix + ' ' + Op + ' run', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
    end;

    local procedure Y9AllReads(var Observer: Codeunit "Probe Observer"; Prefix: Text; Isolation: IsolationLevel; SetBeforeCommit: Boolean)
    begin
        Y9Seed();
        Y9FirstRead(Observer, Prefix, 'get', Isolation, SetBeforeCommit);
        Y9FirstRead(Observer, Prefix, 'find=', Isolation, SetBeforeCommit);
        Y9FirstRead(Observer, Prefix, 'isempty', Isolation, SetBeforeCommit);
        Y9FirstRead(Observer, Prefix, 'count', Isolation, SetBeforeCommit);
        Y9FirstRead(Observer, Prefix, 'next', Isolation, SetBeforeCommit);
        Y9FirstRead(Observer, Prefix, 'calcfields', Isolation, SetBeforeCommit);
    end;

    [Test]
    procedure Y9_UpdLock_SetBeforeCommit_FirstRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y9AllReads(Observer, 'updlock', IsolationLevel::UpdLock, true);
        Observer.Expect('updlock get', 'before=No|Yes/two|after=No');
        Observer.Expect('updlock get run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('updlock find=', 'before=No|Yes/two|after=No');
        Observer.Expect('updlock find= run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('updlock isempty', 'before=No|No|after=No');
        Observer.Expect('updlock isempty run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('updlock count', 'before=No|2|after=No');
        Observer.Expect('updlock count run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('updlock next', 'before=No|1/2|after=No');
        Observer.Expect('updlock next run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('updlock calcfields', 'before=No|1|after=No');
        Observer.Expect('updlock calcfields run', 'ran=Yes tx=No|Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_RepeatableRead_SetBeforeCommit_FirstRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y9AllReads(Observer, 'repeatable', IsolationLevel::RepeatableRead, true);
        Observer.Expect('repeatable get', 'before=No|Yes/two|after=No');
        Observer.Expect('repeatable get run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('repeatable find=', 'before=No|Yes/two|after=No');
        Observer.Expect('repeatable find= run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('repeatable isempty', 'before=No|No|after=No');
        Observer.Expect('repeatable isempty run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('repeatable count', 'before=No|2|after=No');
        Observer.Expect('repeatable count run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('repeatable next', 'before=No|1/2|after=No');
        Observer.Expect('repeatable next run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('repeatable calcfields', 'before=No|1|after=No');
        Observer.Expect('repeatable calcfields run', 'ran=Yes tx=No|Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_UpdLock_SetAfterCommit_FirstRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y9AllReads(Observer, 'updlock', IsolationLevel::UpdLock, false);
        Observer.Expect('updlock get', 'before=Yes|Yes/two|after=Yes');
        Observer.Expect('updlock get run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Expect('updlock find=', 'before=Yes|Yes/two|after=Yes');
        Observer.Expect('updlock find= run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Expect('updlock isempty', 'before=Yes|No|after=Yes');
        Observer.Expect('updlock isempty run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Expect('updlock count', 'before=Yes|2|after=Yes');
        Observer.Expect('updlock count run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Expect('updlock next', 'before=Yes|1/2|after=Yes');
        Observer.Expect('updlock next run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Expect('updlock calcfields', 'before=Yes|1|after=Yes');
        Observer.Expect('updlock calcfields run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_RepeatableRead_SetAfterCommit_FirstRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y9AllReads(Observer, 'repeatable', IsolationLevel::RepeatableRead, false);
        Observer.Expect('repeatable get', 'before=Yes|Yes/two|after=Yes');
        Observer.Expect('repeatable get run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Expect('repeatable find=', 'before=Yes|Yes/two|after=Yes');
        Observer.Expect('repeatable find= run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Expect('repeatable isempty', 'before=Yes|No|after=Yes');
        Observer.Expect('repeatable isempty run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Expect('repeatable count', 'before=Yes|2|after=Yes');
        Observer.Expect('repeatable count run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Expect('repeatable next', 'before=Yes|1/2|after=Yes');
        Observer.Expect('repeatable next run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Expect('repeatable calcfields', 'before=Yes|1|after=Yes');
        Observer.Expect('repeatable calcfields run', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.|DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_ReadCommitted_SetBeforeCommit_FirstRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y9AllReads(Observer, 'committed', IsolationLevel::ReadCommitted, true);
        Observer.Expect('committed get', 'before=No|Yes/two|after=No');
        Observer.Expect('committed get run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('committed find=', 'before=No|Yes/two|after=No');
        Observer.Expect('committed find= run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('committed isempty', 'before=No|No|after=No');
        Observer.Expect('committed isempty run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('committed count', 'before=No|2|after=No');
        Observer.Expect('committed count run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('committed next', 'before=No|1/2|after=No');
        Observer.Expect('committed next run', 'ran=Yes tx=No|Dialog');
        Observer.Expect('committed calcfields', 'before=No|1|after=No');
        Observer.Expect('committed calcfields run', 'ran=Yes tx=No|Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Y9_ReadIsolation_ValueAcrossCommit()
    var
        Observer: Codeunit "Probe Observer";
        Locked: Record "LT Y9 RI Row";
        Repeatable: Record "LT Y9 RI Row";
    begin
        Y9Seed();
        Locked.ReadIsolation := IsolationLevel::UpdLock;
        Repeatable.ReadIsolation := IsolationLevel::RepeatableRead;
        Observer.Observe('before commit', Format(Locked.ReadIsolation) + '|' + Format(Repeatable.ReadIsolation) + '|tx=' + Format(IsInWriteTransaction()));
        Commit();
        Observer.Observe('after commit', Format(Locked.ReadIsolation) + '|' + Format(Repeatable.ReadIsolation) + '|tx=' + Format(IsInWriteTransaction()));
        Locked.Get(1);
        Observer.Observe('after updlock get', Format(Locked.ReadIsolation) + '|tx=' + Format(IsInWriteTransaction()));
        Locked.ReadIsolation := IsolationLevel::UpdLock;
        Observer.Observe('after setting again', Format(Locked.ReadIsolation) + '|tx=' + Format(IsInWriteTransaction()));
        Observer.Finish();
    end;
}

table 91461 "LT Y9 RI Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y9 RI Row" where(Id = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The codeunit a guarded Codeunit.Run runs: it does nothing.
codeunit 91460 "LT Y9 RI Noop"
{
    trigger OnRun()
    begin
    end;
}
