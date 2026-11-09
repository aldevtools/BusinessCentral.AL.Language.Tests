// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-minimumactiverowversion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67516 "LT RV Row" (PlTRowVersionValue.al)
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

    procedure Stage(var Observer: Codeunit "Probe Observer"; Tag: Text; Min0: BigInteger; Last0: BigInteger; var PrevMin: BigInteger; RowVersion: BigInteger)
    var
        Min: BigInteger;
        Last: BigInteger;
    begin
        Min := MinimumActiveRowVersion();
        Last := LastUsedRowVersion();
        Observer.Observe(Tag + ' min/first', Rel(Min, Min0));
        Observer.Observe(Tag + ' min/prev', Rel(Min, PrevMin));
        Observer.Observe(Tag + ' last/first', Rel(Last, Last0));
        Observer.Observe(Tag + ' min-last', Format(Min - Last));
        if RowVersion <> 0 then begin
            Observer.Observe(Tag + ' row/min', Rel(RowVersion, Min));
            Observer.Observe(Tag + ' row/last', Rel(RowVersion, Last));
        end;
        Observer.Observe(Tag + ' tx', Format(IsInWriteTransaction()));
        PrevMin := Min;
    end;

    procedure Run(var Observer: Codeunit "Probe Observer"; Tag: Text)
    var
        Row: Record "LT RV Row";
        Min0: BigInteger;
        Last0: BigInteger;
        PrevMin: BigInteger;
    begin
        Min0 := MinimumActiveRowVersion();
        Last0 := LastUsedRowVersion();
        PrevMin := Min0;
        Observer.Observe(Tag + ' first min-last', Format(Min0 - Last0));
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
        Sequence.Run(Observer, 'a');
        Observer.Finish();
    end;

    [Test]
    procedure MinRowVersion_DefaultIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'b');
        Observer.Finish();
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
        Sequence.Run(Observer, 'a');
        Observer.Finish();
    end;

    [Test]
    procedure MinRowVersion_CodeunitIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'b');
        Observer.Finish();
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
        Sequence.Run(Observer, 'a');
        Observer.Finish();
    end;

    [Test]
    procedure MinRowVersion_FunctionIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, 'b');
        Observer.Finish();
    end;
}

codeunit 97990 "MRV Open Write First Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MinRowVersion_OpenWriteBeforeFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
    begin
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Row.Get(3);
        Observer.Observe('open first min-last', Format(MinimumActiveRowVersion() - LastUsedRowVersion()));
        Observer.Observe('open first row/min', Format(Row.SystemRowVersion - MinimumActiveRowVersion()));
        Observer.Observe('open first tx', Format(IsInWriteTransaction()));
        Observer.Finish();
    end;
}

codeunit 97991 "MRV Committed Write First Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MinRowVersion_CommittedWriteBeforeFirstRead()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT RV Row";
    begin
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Commit();
        Row.Get(3);
        Observer.Observe('committed first min-last', Format(MinimumActiveRowVersion() - LastUsedRowVersion()));
        Observer.Observe('committed first row/min', Format(Row.SystemRowVersion - MinimumActiveRowVersion()));
        Observer.Observe('committed first tx', Format(IsInWriteTransaction()));
        Observer.Finish();
    end;
}
