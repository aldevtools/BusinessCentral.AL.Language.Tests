// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-minimumactiverowversion-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 67516 "LT RV Row" (PlTRowVersionValue.al)
// Probe: how Database.MinimumActiveRowVersion() relates to LastUsedRowVersion() and to the SystemRowVersion of a written row, read in a
// fixed order of stages: the first read of a test (no write yet), an open Insert, an open Modify, after Commit, a second write after Commit,
// and a DeleteAll with and without Commit. The same sequence runs in a codeunit with the default TestIsolation, with TestIsolation = Codeunit
// and with TestIsolation = Function. Only relations are asserted (same, greater, less), plus the difference Min - Last where it is stable.
// The codeunits are new (not an extension of "LT RV Tests", 67515) because the first read of a test must come before any write of the
// codeunit, and because TestIsolation is a property of the whole codeunit.
// local object: the helper and the memory codeunit exist only to share one sequence between three test codeunits and to carry values from one test to the next.
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
        Observer.Observe(Tag + ' min vs first', Rel(Min, Min0));
        Observer.Observe(Tag + ' min vs prev', Rel(Min, PrevMin));
        Observer.Observe(Tag + ' last vs first', Rel(Last, Last0));
        Observer.Observe(Tag + ' min - last', Format(Min - Last));
        if RowVersion <> 0 then begin
            Observer.Observe(Tag + ' row vs min', Rel(RowVersion, Min));
            Observer.Observe(Tag + ' row vs last', Rel(RowVersion, Last));
        end;
        Observer.Observe(Tag + ' write tx', Format(IsInWriteTransaction()));
        PrevMin := Min;
    end;

    procedure Run(var Observer: Codeunit "Probe Observer"; var Memory: Codeunit "MRV Memory"; Tag: Text)
    var
        Row: Record "LT RV Row";
        Min0: BigInteger;
        Last0: BigInteger;
        PrevMin: BigInteger;
        Start: BigInteger;
    begin
        Min0 := MinimumActiveRowVersion();
        Last0 := LastUsedRowVersion();
        PrevMin := Min0;
        Observer.Observe(Tag + ' first min - last', Format(Min0 - Last0));
        Observer.Observe(Tag + ' first min positive', Format(Min0 > 0));
        Observer.Observe(Tag + ' first write tx', Format(IsInWriteTransaction()));
        Observer.Observe(Tag + ' first min vs previous test end', Memory.RelMin(Min0));
        Observer.Observe(Tag + ' first last vs previous test end', Memory.RelLast(Last0));
        Row.Id := 1;
        Row.Insert();
        Row.Get(1);
        Stage(Observer, Tag + ' insert open', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Row.Name := 'x';
        Row.Modify();
        Row.Get(1);
        Stage(Observer, Tag + ' modify open', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Commit();
        Stage(Observer, Tag + ' committed', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Row.Id := 2;
        Row.Insert();
        Row.Get(2);
        Stage(Observer, Tag + ' second insert open', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Row.Name := 'y';
        Row.Modify();
        Row.Get(2);
        Stage(Observer, Tag + ' second modify open', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Commit();
        Stage(Observer, Tag + ' second committed', Min0, Last0, PrevMin, Row.SystemRowVersion);
        Row.DeleteAll();
        Stage(Observer, Tag + ' deleteall open', Min0, Last0, PrevMin, 0);
        Commit();
        Stage(Observer, Tag + ' deleteall committed', Min0, Last0, PrevMin, 0);
        Memory.Keep(MinimumActiveRowVersion(), LastUsedRowVersion());
    end;
}

codeunit 97986 "MRV Memory"
{
    SingleInstance = true;

    var
        PrevMin: BigInteger;
        PrevLast: BigInteger;

    procedure Keep(Min: BigInteger; Last: BigInteger)
    begin
        PrevMin := Min;
        PrevLast := Last;
    end;

    procedure RelMin(Min: BigInteger): Text
    begin
        if PrevMin = 0 then
            exit('no previous test');
        if Min = PrevMin then
            exit('same');
        if Min > PrevMin then
            exit('greater');
        exit('less');
    end;

    procedure RelLast(Last: BigInteger): Text
    begin
        if PrevLast = 0 then
            exit('no previous test');
        if Last = PrevLast then
            exit('same');
        if Last > PrevLast then
            exit('greater');
        exit('less');
    end;
}

codeunit 97987 "MRV Default Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Sequence: Codeunit "MRV Sequence";
        Memory: Codeunit "MRV Memory";

    [Test]
    procedure MinRowVersion_DefaultIsolation_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, Memory, 'a');
        Observer.Finish();
    end;

    [Test]
    procedure MinRowVersion_DefaultIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, Memory, 'b');
        Observer.Finish();
    end;
}

codeunit 97988 "MRV Codeunit Isolation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestIsolation = Codeunit;

    var
        Sequence: Codeunit "MRV Sequence";
        Memory: Codeunit "MRV Memory";

    [Test]
    procedure MinRowVersion_CodeunitIsolation_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, Memory, 'a');
        Observer.Finish();
    end;

    [Test]
    procedure MinRowVersion_CodeunitIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, Memory, 'b');
        Observer.Finish();
    end;
}

codeunit 97989 "MRV Function Isolation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestIsolation = Function;

    var
        Sequence: Codeunit "MRV Sequence";
        Memory: Codeunit "MRV Memory";

    [Test]
    procedure MinRowVersion_FunctionIsolation_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, Memory, 'a');
        Observer.Finish();
    end;

    [Test]
    procedure MinRowVersion_FunctionIsolation_SecondTest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Sequence.Run(Observer, Memory, 'b');
        Observer.Finish();
    end;
}
