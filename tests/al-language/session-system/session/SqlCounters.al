// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 81860; writer RO: tests RO_* (al-runner issue 5761)
// Probe: corpus issue 673 item 2 (al-runtime-rs #293). The counters are not deterministic: only properties are observed (sign of a difference, equal or not), never a count. Asserted only where every CI run on BC 27.5, 28.5 and 29.0 gave the same answer.
// Facts: SessionInformation.SqlStatementsExecuted() and SqlRowsRead(): not negative; two reads with nothing between them; the change after Get, FindSet, Insert, Modify, Delete and Count on a table and on a temporary record; the type read through a Variant.
// BC versions: 27+

table 81860 "LT BL Sql Row"
{
    DataClassification = CustomerContent;

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

codeunit 81861 "LT BL Sql Counters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        StmtBefore: BigInteger;
        RowsBefore: BigInteger;

    local procedure Seed()
    var
        Row: Record "LT BL Sql Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 3 do begin
            Row.Id := I;
            Row.Name := 'row ' + Format(I);
            Row.Insert();
        end;
        Commit();
    end;

    local procedure Mark()
    begin
        StmtBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
    end;

    local procedure Sign(Delta: BigInteger): Text
    begin
        if Delta > 0 then
            exit('increased');
        if Delta < 0 then
            exit('decreased');
        exit('same');
    end;

    local procedure Note(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Stmt: BigInteger;
        Rows: BigInteger;
    begin
        Stmt := SessionInformation.SqlStatementsExecuted();
        Rows := SessionInformation.SqlRowsRead();
        Observer.Observe(Name, 'statements ' + Sign(Stmt - StmtBefore) + ', rows ' + Sign(Rows - RowsBefore));
    end;

    // The al-runtime-rs #293 repro, and the sign of both counters.
    [Test]
    procedure Counters_NotNegative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('statements >= 0', Format(SessionInformation.SqlStatementsExecuted() >= 0));
        Observer.Observe('rows >= 0', Format(SessionInformation.SqlRowsRead() >= 0));
        Observer.Expect('statements >= 0', 'Yes');
        Observer.Expect('rows >= 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Counters_Type()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := SessionInformation.SqlStatementsExecuted();
        Observer.Observe('statements isbiginteger', Format(V.IsBigInteger()));
        Observer.Observe('statements isinteger', Format(V.IsInteger()));
        V := SessionInformation.SqlRowsRead();
        Observer.Observe('rows isbiginteger', Format(V.IsBigInteger()));
        Observer.Observe('rows isinteger', Format(V.IsInteger()));
        Observer.Expect('statements isbiginteger', 'Yes');
        Observer.Expect('statements isinteger', 'No');
        Observer.Expect('rows isbiginteger', 'Yes');
        Observer.Expect('rows isinteger', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Counters_NothingBetween()
    var
        Observer: Codeunit "Probe Observer";
        X: Integer;
    begin
        Mark();
        Note(Observer, 'two reads');
        Mark();
        X := 1 + 2;
        Note(Observer, 'arithmetic only');
        Observer.Expect('two reads', 'statements same, rows same');
        Observer.Expect('arithmetic only', 'statements same, rows same');
        Observer.Verify();
    end;

    [Test]
    procedure Counters_TableOperations()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Sql Row";
        N: Integer;
    begin
        Seed();
        Mark();
        Row.Get(2);
        Note(Observer, 'get');
        Mark();
        Row.FindSet();
        repeat
        until Row.Next() = 0;
        Note(Observer, 'findset loop');
        Mark();
        N := Row.Count();
        Note(Observer, 'count');
        Mark();
        Row.Id := 10;
        Row.Name := 'ten';
        Row.Insert();
        Note(Observer, 'insert');
        Mark();
        Row.Name := 'TEN';
        Row.Modify();
        Note(Observer, 'modify');
        Mark();
        Row.Delete();
        Note(Observer, 'delete');
        Observer.Expect('get', 'statements increased, rows increased');
        Observer.Expect('findset loop', 'statements increased, rows increased');
        Observer.Expect('count', 'statements same, rows same');
        Observer.Expect('insert', 'statements same, rows same');
        Observer.Expect('modify', 'statements increased, rows increased');
        Observer.Expect('delete', 'statements increased, rows same');
        Observer.Verify();
    end;

    [Test]
    procedure Counters_TemporaryOperations()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Sql Row" temporary;
        N: Integer;
    begin
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Mark();
        Row.Get(2);
        Note(Observer, 'get');
        Mark();
        Row.FindSet();
        repeat
        until Row.Next() = 0;
        Note(Observer, 'findset loop');
        Mark();
        N := Row.Count();
        Note(Observer, 'count');
        Mark();
        Row.Id := 10;
        Row.Insert();
        Note(Observer, 'insert');
        Mark();
        Row.Name := 'TEN';
        Row.Modify();
        Note(Observer, 'modify');
        Mark();
        Row.Delete();
        Note(Observer, 'delete');
        Observer.Expect('get', 'statements same, rows same');
        Observer.Expect('findset loop', 'statements same, rows same');
        Observer.Expect('count', 'statements same, rows same');
        Observer.Expect('insert', 'statements same, rows same');
        Observer.Expect('modify', 'statements same, rows same');
        Observer.Expect('delete', 'statements same, rows same');
        Observer.Verify();
    end;

    // Writer RO (al-runner issue 5761): the size of the change of both counters around N operations of one kind, for several N,
    // each measured three times in the same run (table emptied and committed before each measurement).
    local procedure RoReset(Rows: Integer)
    var
        Row: Record "LT BL Sql Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to Rows do begin
            Row.Id := I;
            Row.Name := 'row ' + Format(I);
            Row.Insert();
        end;
        Commit();
    end;

    // Kind: 1 N inserts; 2 N inserts then Count; 3 Get of N different rows; 4 N Gets of the same row; 5 FindSet loop over N rows;
    // 6 Get and Modify of N rows; 7 Get and Delete of N rows; 8 DeleteAll of N rows; 9 Count over N rows.
    local procedure RoMeasure(Kind: Integer; N: Integer): Text
    var
        Row: Record "LT BL Sql Row";
        I: Integer;
        Cnt: Integer;
        Stmt: BigInteger;
        Rows: BigInteger;
    begin
        if Kind in [1, 2] then
            RoReset(0)
        else
            RoReset(N);
        Mark();
        case Kind of
            1, 2:
                begin
                    for I := 1 to N do begin
                        Row.Init();
                        Row.Id := 100 + I;
                        Row.Name := 'Row';
                        Row.Insert();
                    end;
                    if Kind = 2 then
                        Cnt := Row.Count();
                end;
            3:
                for I := 1 to N do
                    Row.Get(I);
            4:
                for I := 1 to N do
                    Row.Get(1);
            5:
                if Row.FindSet() then
                    repeat
                    until Row.Next() = 0;
            6:
                for I := 1 to N do begin
                    Row.Get(I);
                    Row.Name := 'changed';
                    Row.Modify();
                end;
            7:
                for I := 1 to N do begin
                    Row.Get(I);
                    Row.Delete();
                end;
            8:
                Row.DeleteAll();
            9:
                Cnt := Row.Count();
        end;
        Stmt := SessionInformation.SqlStatementsExecuted();
        Rows := SessionInformation.SqlRowsRead();
        exit(Format(Stmt - StmtBefore) + '/' + Format(Rows - RowsBefore));
    end;

    local procedure RoRepeat(Kind: Integer; N: Integer): Text
    begin
        exit(RoMeasure(Kind, N) + ' ' + RoMeasure(Kind, N) + ' ' + RoMeasure(Kind, N));
    end;

    local procedure RoSeries(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Integer)
    begin
        Observer.Observe(Name + ' N=1', RoRepeat(Kind, 1));
        Observer.Observe(Name + ' N=2', RoRepeat(Kind, 2));
        Observer.Observe(Name + ' N=5', RoRepeat(Kind, 5));
        Observer.Observe(Name + ' N=10', RoRepeat(Kind, 10));
        Observer.Observe(Name + ' N=20', RoRepeat(Kind, 20));
    end;

    // The reporter's shape: 10 inserts and a Count, the statement difference within (0, 100].
    [Test]
    procedure RO_Counters_StatementBudget_Repro()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Sql Row";
        Before: BigInteger;
        After: BigInteger;
        Executed: BigInteger;
        I: Integer;
    begin
        Row.DeleteAll();
        Commit();
        Before := SessionInformation.SqlStatementsExecuted();
        for I := 1 to 10 do begin
            Row.Init();
            Row.Id := I;
            Row.Name := 'Row';
            Row.Insert();
        end;
        if Row.Count() <> 10 then
            Error('Expected 10 rows.');
        After := SessionInformation.SqlStatementsExecuted();
        Executed := After - Before;
        Observer.Observe('within (0, 100]', Format((Executed > 0) and (Executed <= 100)));
        Observer.Observe('raw', Format(Executed));
        Observer.Expect('within (0, 100]', 'Yes');
        Observer.Expect('raw', '3');
        Observer.Verify();
    end;

    // Each value: three measurements "statements/rows" of the same operations.
    [Test]
    procedure RO_Counters_Sizes_Inserts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RoSeries(Observer, 'insert', 1);
        RoSeries(Observer, 'insert+count', 2);
        Observer.Expect('insert N=1', '0/0 0/0 0/0');
        Observer.Expect('insert N=2', '0/0 0/0 0/0');
        Observer.Expect('insert N=5', '1/0 1/0 1/0');
        Observer.Expect('insert N=10', '2/0 2/0 2/0');
        Observer.Expect('insert N=20', '4/0 4/0 4/0');
        Observer.Expect('insert+count N=1', '2/1 2/1 2/1');
        Observer.Expect('insert+count N=2', '3/1 3/1 3/1');
        Observer.Expect('insert+count N=5', '2/1 2/1 2/1');
        Observer.Expect('insert+count N=10', '3/1 3/1 3/1');
        Observer.Expect('insert+count N=20', '5/1 5/1 5/1');
        Observer.Verify();
    end;

    [Test]
    procedure RO_Counters_Sizes_Reads()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RoSeries(Observer, 'get distinct', 3);
        RoSeries(Observer, 'get same', 4);
        RoSeries(Observer, 'findset loop', 5);
        Observer.Expect('get distinct N=1', '1/1 1/1 1/1');
        Observer.Expect('get distinct N=2', '2/2 2/2 2/2');
        Observer.Expect('get distinct N=5', '5/5 5/5 5/5');
        Observer.Expect('get distinct N=10', '10/10 10/10 10/10');
        Observer.Expect('get distinct N=20', '20/20 20/20 20/20');
        Observer.Expect('get same N=1', '1/1 1/1 1/1');
        Observer.Expect('get same N=2', '1/1 1/1 1/1');
        Observer.Expect('get same N=5', '1/1 1/1 1/1');
        Observer.Expect('get same N=10', '1/1 1/1 1/1');
        Observer.Expect('get same N=20', '1/1 1/1 1/1');
        Observer.Expect('findset loop N=1', '1/2 1/2 1/2');
        Observer.Expect('findset loop N=2', '1/3 1/3 1/3');
        Observer.Expect('findset loop N=5', '1/6 1/6 1/6');
        Observer.Expect('findset loop N=10', '1/11 1/11 1/11');
        Observer.Expect('findset loop N=20', '1/21 1/21 1/21');
        Observer.Verify();
    end;

    [Test]
    procedure RO_Counters_Sizes_Writes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RoSeries(Observer, 'modify', 6);
        RoSeries(Observer, 'delete', 7);
        RoSeries(Observer, 'deleteall', 8);
        RoSeries(Observer, 'count', 9);
        Observer.Expect('modify N=1', '2/2 2/2 2/2');
        Observer.Expect('modify N=2', '4/4 4/4 4/4');
        Observer.Expect('modify N=5', '10/10 10/10 10/10');
        Observer.Expect('modify N=10', '20/20 20/20 20/20');
        Observer.Expect('modify N=20', '40/40 40/40 40/40');
        Observer.Expect('delete N=1', '2/1 2/1 2/1');
        Observer.Expect('delete N=2', '4/2 4/2 4/2');
        Observer.Expect('delete N=5', '10/5 10/5 10/5');
        Observer.Expect('delete N=10', '20/10 20/10 20/10');
        Observer.Expect('delete N=20', '40/20 40/20 40/20');
        Observer.Expect('deleteall N=1', '1/0 1/0 1/0');
        Observer.Expect('deleteall N=2', '1/0 1/0 1/0');
        Observer.Expect('deleteall N=5', '1/0 1/0 1/0');
        Observer.Expect('deleteall N=10', '1/0 1/0 1/0');
        Observer.Expect('deleteall N=20', '1/0 1/0 1/0');
        Observer.Expect('count N=1', '1/1 1/1 1/1');
        Observer.Expect('count N=2', '1/1 1/1 1/1');
        Observer.Expect('count N=5', '1/1 1/1 1/1');
        Observer.Expect('count N=10', '1/1 1/1 1/1');
        Observer.Expect('count N=20', '1/1 1/1 1/1');
        Observer.Verify();
    end;

    // Writer P6924 (al-runtime-rs triage of issue 6924, section C step 1): a counter read stored in an Integer, a Decimal and a
    // Dictionary of [Guid, Integer] value, formatted, and passed to telemetry in a custom dimension. Only stable properties are
    // asserted (no error, not negative, digits only, a later read is not smaller), never a count.
    local procedure DigitsOnly(Value: Text): Boolean
    var
        I: Integer;
    begin
        if Value = '' then
            exit(false);
        for I := 1 to StrLen(Value) do
            if not (Value[I] in ['0' .. '9']) then
                exit(false);
        exit(true);
    end;

    [Test]
    procedure P6924_Counters_StoredInInteger_NotNegative()
    var
        Observer: Codeunit "Probe Observer";
        Stmt: Integer;
        Rows: Integer;
    begin
        Stmt := SessionInformation.SqlStatementsExecuted();
        Rows := SessionInformation.SqlRowsRead();
        Observer.Observe('statements in Integer >= 0', Format(Stmt >= 0));
        Observer.Observe('rows in Integer >= 0', Format(Rows >= 0));
        Observer.Expect('statements in Integer >= 0', 'Yes');
        Observer.Expect('rows in Integer >= 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P6924_Counters_Format_DigitsOnly()
    var
        Observer: Codeunit "Probe Observer";
        Stmt: Integer;
    begin
        Observer.Observe('format statements', Format(DigitsOnly(Format(SessionInformation.SqlStatementsExecuted()))));
        Observer.Observe('format rows', Format(DigitsOnly(Format(SessionInformation.SqlRowsRead()))));
        Stmt := SessionInformation.SqlStatementsExecuted();
        Observer.Observe('format of the Integer', Format(DigitsOnly(Format(Stmt))));
        Observer.Expect('format statements', 'Yes');
        Observer.Expect('format rows', 'Yes');
        Observer.Expect('format of the Integer', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P6924_Counters_DictionaryOfGuidInteger_AddGetAndLaterDifference()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Sql Row";
        Stored: Dictionary of [Guid, Integer];
        Key1: Guid;
        Value: Integer;
        Later: Integer;
    begin
        Seed();
        Key1 := CreateGuid();
        Stored.Add(Key1, SessionInformation.SqlStatementsExecuted());
        Value := Stored.Get(Key1);
        Observer.Observe('contains key', Format(Stored.ContainsKey(Key1)));
        Observer.Observe('stored value >= 0', Format(Value >= 0));
        Row.Get(2);
        Later := SessionInformation.SqlStatementsExecuted();
        Observer.Observe('later minus stored >= 0', Format(Later - Stored.Get(Key1) >= 0));
        Observer.Observe('later minus stored > 0 after a Get', Format(Later - Stored.Get(Key1) > 0));
        Observer.Expect('contains key', 'Yes');
        Observer.Expect('stored value >= 0', 'Yes');
        Observer.Expect('later minus stored >= 0', 'Yes');
        Observer.Expect('later minus stored > 0 after a Get', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P6924_Counters_StoredInDecimal_NotNegativeAndWhole()
    var
        Observer: Codeunit "Probe Observer";
        Stmt: Decimal;
        Rows: Decimal;
    begin
        Stmt := SessionInformation.SqlStatementsExecuted();
        Rows := SessionInformation.SqlRowsRead();
        Observer.Observe('statements in Decimal >= 0', Format(Stmt >= 0));
        Observer.Observe('rows in Decimal >= 0', Format(Rows >= 0));
        Observer.Observe('statements whole', Format(Stmt = Round(Stmt, 1)));
        Observer.Observe('later minus stored >= 0', Format(SessionInformation.SqlStatementsExecuted() - Stmt >= 0));
        Observer.Expect('statements in Decimal >= 0', 'Yes');
        Observer.Expect('rows in Decimal >= 0', 'Yes');
        Observer.Expect('statements whole', 'Yes');
        Observer.Expect('later minus stored >= 0', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySessionLogMessage(Value: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('SqlStatements', Value);
        Session.LogMessage('0000P69', 'LT P6924 sql counter', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    [TryFunction]
    local procedure TryTelemetryLogMessage(Value: Text)
    var
        Telemetry: Codeunit Telemetry;
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('SqlStatements', Value);
        Telemetry.LogMessage('0000P6A', 'LT P6924 sql counter', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    [Test]
    procedure P6924_Counters_FormattedInTelemetryDimension_NoError()
    var
        Observer: Codeunit "Probe Observer";
        Stored: Dictionary of [Guid, Integer];
        Key1: Guid;
    begin
        Key1 := CreateGuid();
        Stored.Add(Key1, SessionInformation.SqlStatementsExecuted());
        ClearLastError();
        Observer.Observe('Session.LogMessage', Format(TrySessionLogMessage(Format(SessionInformation.SqlStatementsExecuted() - Stored.Get(Key1)))));
        Observer.ObserveError('Session.LogMessage error');
        ClearLastError();
        Observer.Observe('Telemetry.LogMessage', Format(TryTelemetryLogMessage(Format(SessionInformation.SqlStatementsExecuted() - Stored.Get(Key1)))));
        Observer.ObserveError('Telemetry.LogMessage error');
        Observer.Expect('Session.LogMessage', 'Yes');
        Observer.Expect('Session.LogMessage error|text', '');
        Observer.Expect('Session.LogMessage error|code', '');
        Observer.Expect('Telemetry.LogMessage', 'Yes');
        Observer.Expect('Telemetry.LogMessage error|text', '');
        Observer.Expect('Telemetry.LogMessage error|code', '');
        Observer.Verify();
    end;
}
