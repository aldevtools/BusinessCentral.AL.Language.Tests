// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testrunner-codeunits
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunits 67284-67288 and 67294, table 67295
// RISKY (runtime): a test that runs a codeunit of Subtype = TestRunner while the corpus runs under Microsoft's top-level runner; what a test sees is observed.
//
// The triggers OnBeforeTestRun (its Boolean result decides whether the test method runs) and OnAfterTestRun (it receives the success flag) of a test runner codeunit, and a runner without them.
// BC versions: 27, 28, 29
codeunit 67284 "LT P Runner Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Reset()
    var
        Flag: Record "LT P Runner Flag";
    begin
        Clear(Entries);
        Flag.DeleteAll();
    end;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Joined(): Text
    var
        E: Text;
        R: Text;
    begin
        foreach E in Entries do
            R += E + ';';
        exit(R);
    end;

    procedure SetFlag(FlagName: Text; FlagValue: Text)
    var
        Flag: Record "LT P Runner Flag";
    begin
        Flag.Init();
        Flag.Name := CopyStr(FlagName, 1, MaxStrLen(Flag.Name));
        Flag.Value := CopyStr(FlagValue, 1, MaxStrLen(Flag.Value));
        Flag.Insert();
    end;
}

table 67295 "LT P Runner Flag"
{
    fields
    {
        field(1; Name; Code[20]) { }
        field(2; Value; Text[50]) { }
    }
    keys
    {
        key(PK; Name) { Clustered = true; }
    }
}

codeunit 67294 "LT P Runner Subject Hook"
{
    procedure Body(Name: Text)
    var
        Flag: Record "LT P Runner Flag";
    begin
        if Flag.Get('FAIL') and (Flag.Value = Name) then
            Error('LT P subject failed on purpose');
    end;
}

codeunit 67285 "LT P Runner Subject"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PSubjectOne()
    var
        Hook: Codeunit "LT P Runner Subject Hook";
    begin
        Hook.Body('One');
    end;

    [Test]
    procedure PSubjectTwo()
    var
        Hook: Codeunit "LT P Runner Subject Hook";
    begin
        Hook.Body('Two');
    end;
}

codeunit 67286 "LT P Runner With Triggers"
{
    Subtype = TestRunner;

    trigger OnRun()
    var
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Add('runner OnRun');
        Codeunit.Run(Codeunit::"LT P Runner Subject");
    end;

    trigger OnBeforeTestRun(CodeunitId: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    var
        Log: Codeunit "LT P Runner Log";
        Flag: Record "LT P Runner Flag";
    begin
        Log.Add(StrSubstNo('before %1 %2 %3 %4', CodeunitId, CodeunitName, FunctionName, Format(FunctionTestPermissions)));
        exit(not Flag.Get('SKIP') or (Flag.Value <> FunctionName));
    end;

    trigger OnAfterTestRun(CodeunitId: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Add(StrSubstNo('after %1 %2 %3 %4', CodeunitId, CodeunitName, FunctionName, Format(IsSuccess)));
    end;
}

codeunit 67287 "LT P Runner Without Triggers"
{
    Subtype = TestRunner;

    trigger OnRun()
    var
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Add('plain runner OnRun');
        Codeunit.Run(Codeunit::"LT P Runner Subject");
    end;
}

codeunit 67288 "LT P Runner Triggers Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRun(RunnerId: Integer)
    begin
        Codeunit.Run(RunnerId);
    end;

    local procedure RunRunner(var Observer: Codeunit "Probe Observer"; RunnerId: Integer)
    var
        Log: Codeunit "LT P Runner Log";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryRun(RunnerId);
        Observer.Observe('run_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('run_error');
        Observer.Observe('log', Log.Joined());
    end;

    [Test]
    procedure PRunner_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Reset();
        RunRunner(Observer, Codeunit::"LT P Runner With Triggers");
        Observer.Expect('run_ok', 'No');
        Observer.Expect('run_error|text', 'You cannot nest the execution of test codeunits. Test codeunit 67285 LT P Runner Subject was called from another test codeunit.');
        Observer.Expect('run_error|code', 'TestCodeUnitNestedInvocation');
        Observer.Expect('log', 'runner OnRun;');
        Observer.Verify();
    end;

    [Test]
    procedure PRunner_BeforeTestRunSkipsAndAfterReportsFailure()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Reset();
        Log.SetFlag('SKIP', 'PSubjectOne');
        Log.SetFlag('FAIL', 'Two');
        RunRunner(Observer, Codeunit::"LT P Runner With Triggers");
        Log.Reset();
        Observer.Expect('run_ok', 'No');
        Observer.Expect('run_error|text', 'You cannot nest the execution of test codeunits. Test codeunit 67285 LT P Runner Subject was called from another test codeunit.');
        Observer.Expect('run_error|code', 'TestCodeUnitNestedInvocation');
        Observer.Expect('log', 'runner OnRun;');
        Observer.Verify();
    end;

    [Test]
    procedure PRunner_WithoutTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P Runner Log";
    begin
        Log.Reset();
        RunRunner(Observer, Codeunit::"LT P Runner Without Triggers");
        Observer.Expect('run_ok', 'No');
        Observer.Expect('run_error|text', 'You cannot nest the execution of test codeunits. Test codeunit 67285 LT P Runner Subject was called from another test codeunit.');
        Observer.Expect('run_error|code', 'TestCodeUnitNestedInvocation');
        Observer.Expect('log', 'plain runner OnRun;');
        Observer.Verify();
    end;
}
