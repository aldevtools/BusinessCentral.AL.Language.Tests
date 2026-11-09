// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-minimumactiverowversion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67516 "LT RV Row" (PlTRowVersionValue.al)
// Measured on BC 27.5, 28.5 and 29.0 (Linux legs): Min is fixed per test codeunit. Its first read in a codeunit is LastUsedRowVersion() + 1, and
// it does not move again for the rest of the codeunit: not through an open Insert or Modify, not through Commit, not through a second write, a
// DeleteAll, or the next test (also under RequiredTestIsolation = Codeunit and = Function). LastUsedRowVersion() grows with each Insert and Modify,
// so after the first write Min is below LastUsedRowVersion() + 1. The first row inserted after the first read has SystemRowVersion = Min; later rows
// are above Min; a row's SystemRowVersion is never above LastUsedRowVersion(). The distance Min - Last differs between BC versions and runs and is not asserted.
// Probe: how Database.MinimumActiveRowVersion() relates to LastUsedRowVersion() and to the SystemRowVersion of a written row, read in a
// fixed order of stages: the first read of a test (no write yet), an open Insert, an open Modify, after Commit, a second write after Commit,
// and a DeleteAll with and without Commit. The same sequence runs in a codeunit with the default TestIsolation, with RequiredTestIsolation = Codeunit
// and with RequiredTestIsolation = Function. Only relations are asserted (same, greater, less), plus the difference Min - Last where it is stable.
// The codeunits are new (not an extension of "LT RV Tests", 67515) because the first read of a test must come before any write of the
// codeunit, and because RequiredTestIsolation is a property of the whole codeunit.
// Observation names: <test tag> <stage> <what>; stages: first (before any write), ins and mod (open Insert and Modify of row 1), com (after Commit),
// ins2, mod2 and com2 (the same for row 2), del (DeleteAll of both rows, open) and delcom (after its Commit). 'min/first' is Min compared with the first
// read, 'min/prev' with the previous stage, 'last/first' is LastUsedRowVersion against its first read, 'row/min' and 'row/last' compare the row's SystemRowVersion,
// 'tx' is IsInWriteTransaction.
// local object: the helper codeunit exists only to share one sequence between three test codeunits.
// BC versions: 27+

codeunit 97985 "MRV Sequence"
{
    local procedure Rel(Value: BigInteger; Other: BigInteger): Text
    begin
        if Value = Other then
            exit('same');
        if Value > Other then
            exit('greater');
        exit('less');
    end;

    local procedure Stage(var Observer: Codeunit "Probe Observer"; Tag: Text; Min0: BigInteger; Last0: BigInteger; var PrevMin: BigInteger; RowVersion: BigInteger)
    var
        Min: BigInteger;
        Last: BigInteger;
    begin
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        Observer.Observe(Tag + ' min/first', Rel(Min, Min0));
        Observer.Observe(Tag + ' min/prev', Rel(Min, PrevMin));
        Observer.Observe(Tag + ' last/first', Rel(Last, Last0));
        Observer.Observe(Tag + ' min/last+1', Rel(Min, Last + 1));
        if RowVersion <> 0 then begin
            Observer.Observe(Tag + ' row/min', Rel(RowVersion, Min));
            Observer.Observe(Tag + ' row<=last', Format(RowVersion <= Last));
        end;
        Observer.Observe(Tag + ' tx', Format(IsInWriteTransaction()));
        PrevMin := Min;
    end;

    local procedure Expect(var Observer: Codeunit "Probe Observer"; Tag: Text; HasRow: Boolean; RowVsMin: Text; Tx: Text)
    begin
        Observer.Expect(Tag + ' min/first', 'same');
        Observer.Expect(Tag + ' min/prev', 'same');
        Observer.Expect(Tag + ' last/first', 'greater');
        Observer.Expect(Tag + ' min/last+1', 'less');
        if HasRow then begin
            Observer.Expect(Tag + ' row/min', RowVsMin);
            Observer.Expect(Tag + ' row<=last', 'Yes');
        end;
        Observer.Expect(Tag + ' tx', Tx);
    end;

    // FirstTest: the first test of its codeunit (nothing written yet), so Min = Last + 1 at the first read and the first row has SystemRowVersion = Min.
    procedure Run(var Observer: Codeunit "Probe Observer"; Tag: Text; FirstTest: Boolean)
    var
        Row: Record "LT RV Row";
        Min0: BigInteger;
        Last0: BigInteger;
        PrevMin: BigInteger;
        FirstRowVsMin: Text;
    begin
        Min0 := MinimumActiveRowVersion();
        Last0 := LastUsedRowVersion();
        PrevMin := Min0;
        Observer.Observe(Tag + ' first min/last+1', Rel(Min0, Last0 + 1));
        Observer.Observe(Tag + ' first min>0', Format(Min0 > 0));
        Observer.Observe(Tag + ' first tx', Format(IsInWriteTransaction()));
        Row.Id := 1;
        Row.Insert();
        Row.Get(1);
        Stage(Observer, Tag + ' ins', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Row.Name := 'x';
        Row.Modify();
        Row.Get(1);
        Stage(Observer, Tag + ' mod', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Commit();
        Stage(Observer, Tag + ' com', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Row.Id := 2;
        Row.Insert();
        Row.Get(2);
        Stage(Observer, Tag + ' ins2', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Row.Name := 'y';
        Row.Modify();
        Row.Get(2);
        Stage(Observer, Tag + ' mod2', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Commit();
        Stage(Observer, Tag + ' com2', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Row.DeleteAll();
        Stage(Observer, Tag + ' del', Min0, Last0, PrevMin, 0);
        Commit();
        Stage(Observer, Tag + ' delcom', Min0, Last0, PrevMin, 0);

        if FirstTest then begin
            Observer.Expect(Tag + ' first min/last+1', 'same');
            FirstRowVsMin := 'same';
        end else begin
            Observer.Expect(Tag + ' first min/last+1', 'less');
            FirstRowVsMin := 'greater';
        end;
        Observer.Expect(Tag + ' first min>0', 'Yes');
        Observer.Expect(Tag + ' first tx', 'No');
        Expect(Observer, Tag + ' ins', true, FirstRowVsMin, 'Yes');
        Expect(Observer, Tag + ' mod', true, 'greater', 'Yes');
        Expect(Observer, Tag + ' com', true, 'greater', 'No');
        Expect(Observer, Tag + ' ins2', true, 'greater', 'Yes');
        Expect(Observer, Tag + ' mod2', true, 'greater', 'Yes');
        Expect(Observer, Tag + ' com2', true, 'greater', 'No');
        Expect(Observer, Tag + ' del', false, '', 'Yes');
        Expect(Observer, Tag + ' delcom', false, '', 'No');
    end;
}

codeunit 97987 "MRV Default Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Sequence: Codeunit "MRV Sequence";

    [Test]
    procedure MinRowVersion_DefaultIsolation_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'a', true);
        Observer.Verify();
    end;

    [Test]
    procedure MinRowVersion_DefaultIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'b', false);
        Observer.Verify();
    end;
}

codeunit 97988 "MRV Codeunit Isolation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Sequence: Codeunit "MRV Sequence";

    [Test]
    procedure MinRowVersion_CodeunitIsolation_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'a', true);
        Observer.Verify();
    end;

    [Test]
    procedure MinRowVersion_CodeunitIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'b', false);
        Observer.Verify();
    end;
}

codeunit 97989 "MRV Function Isolation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;

    var
        Sequence: Codeunit "MRV Sequence";

    [Test]
    procedure MinRowVersion_FunctionIsolation_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'a', true);
        Observer.Verify();
    end;

    [Test]
    procedure MinRowVersion_FunctionIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'b', false);
        Observer.Verify();
    end;
}

codeunit 97990 "MRV Open First Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Hypothesis checked here: Min is fixed when the codeunit starts, not at the first read, so after three writes Min is below Last + 1 and
    // the last written row is above Min.
    [Test]
    procedure MinRowVersion_OpenWriteBeforeFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Min: BigInteger;
        Last: BigInteger;
    begin
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Row.Get(3);
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        if Min = Last + 1 then
            Observer.Observe('open write first min/last+1', 'same')
        else
            if Min > Last + 1 then
                Observer.Observe('open write first min/last+1', 'greater')
            else
                Observer.Observe('open write first min/last+1', 'less');
        Observer.Observe('open write first row/min', Format(Row.SystemRowVersion > Min));
        Observer.Observe('open write first tx', Format(IsInWriteTransaction()));
        Observer.Expect('open write first min/last+1', 'less');
        Observer.Expect('open write first row/min', 'Yes');
        Observer.Expect('open write first tx', 'Yes');
        Observer.Verify();
    end;
}

codeunit 97991 "MRV Committed First Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Hypothesis checked here: Min is fixed when the codeunit starts, not at the first read, so after three writes Min is below Last + 1 and
    // the last written row is above Min.
    [Test]
    procedure MinRowVersion_CommittedWriteBeforeFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
        Min: BigInteger;
        Last: BigInteger;
    begin
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Commit();
        Row.Get(3);
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        if Min = Last + 1 then
            Observer.Observe('committed write first min/last+1', 'same')
        else
            if Min > Last + 1 then
                Observer.Observe('committed write first min/last+1', 'greater')
            else
                Observer.Observe('committed write first min/last+1', 'less');
        Observer.Observe('committed write first row/min', Format(Row.SystemRowVersion > Min));
        Observer.Observe('committed write first tx', Format(IsInWriteTransaction()));
        Observer.Expect('committed write first min/last+1', 'less');
        Observer.Expect('committed write first row/min', 'Yes');
        Observer.Expect('committed write first tx', 'No');
        Observer.Verify();
    end;
}
