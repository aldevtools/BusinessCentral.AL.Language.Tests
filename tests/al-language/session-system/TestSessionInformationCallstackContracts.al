// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68930, codeunits 68931..68935 (log, runner, publisher,
//                subscriber, tests)
// Probe: written against a real BC 27.5 service tier started by bc-linux; every literal below is what that tier
// produced. Other BC versions were not measured (the line numbers of the platform's own runner frames are not pinned).
//
// Pins SessionInformation.Callstack and the separator of GetLastErrorCallStack:
//  - The frames are separated by a backslash and the text ENDS with a backslash (no line feed, no carriage return);
//    the innermost frame (the procedure that reads Callstack) is first; below the test procedure come the test
//    test runner's frames, IF the runner shows any: the websocket runner of the 27.5 CI and the local container does ("Test Runner - Mgt"
//    (CodeUnit 130454).RunTests ... down to the "Command Line Test Tool" page), the VSCodeTestClient / altool runner of 28.5 ends the
//    stack at the test procedure. The tests assert the frames from the innermost up to the test procedure and nothing below it.
//  - A frame is <"object name">(<Type> <id>).<procedure> line <n> - <app name> by <publisher> version <version>, where n is
//    the line inside the procedure or trigger counted from its header (the line of the header is 0, so a statement in the first line after begin is line 2) and, for the caller, the line of
//    the call. A trigger is "<table>"(Table n)."<field> - OnValidate"(Trigger) and ...OnInsert(Trigger) and
//    "<codeunit>"(CodeUnit n).OnRun(Trigger); an event subscriber follows its publisher's event frame:
//    "<subscriber>"(CodeUnit n).<procedure> line 0, then "<publisher>"(CodeUnit n).<event>(Event) line 0, then the firing procedure.
//  - Codeunit.Run and Run of a codeunit variable give the same OnRun(Trigger) frame.
//  - Inside a procedure that is called from an asserterror the stack is the plain stack; GetLastErrorCallStack after
//    the error has the same form and separator (the failing procedure's frame has the line of the Error call); after the
//    asserterror the stack no longer has the failing frames.
//  - The text is not cut: 300 nested procedures give 301 frames of the procedure plus the test procedure (more than 20000 characters).
// BC versions: 27.5

table 68930 "Probe CS Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Integer)
        {
            trigger OnValidate()
            begin
                CsLog.Add('OnValidate: ' + CutRunner(SessionInformation.Callstack));
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    var
        CsLog: Codeunit "Probe CS Log";

    trigger OnInsert()
    begin
        CsLog.Add('OnInsert: ' + CutRunner(SessionInformation.Callstack));
    end;

    local procedure CutRunner(Stack: Text): Text
    begin
        exit(CsLog.CutRunner(Stack));
    end;
}

codeunit 68931 "Probe CS Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + '|';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;

    procedure CutRunner(Stack: Text): Text
    var
        Position: Integer;
    begin
        Position := StrPos(Stack, '"Test Runner - Mgt"');
        if Position > 0 then
            exit(CopyStr(Stack, 1, Position - 1));
        exit(Stack);
    end;
}

codeunit 68932 "Probe CS Runner"
{
    trigger OnRun()
    var
        CsLog: Codeunit "Probe CS Log";
    begin
        CsLog.Add('OnRun: ' + CsLog.CutRunner(SessionInformation.Callstack));
    end;
}

codeunit 68933 "Probe CS Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnEvent()
    begin
    end;

    procedure Fire()
    begin
        OnEvent();
    end;
}

codeunit 68934 "Probe CS Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Probe CS Publisher", 'OnEvent', '', false, false)]
    local procedure Handle()
    var
        CsLog: Codeunit "Probe CS Log";
    begin
        CsLog.Add('Subscriber: ' + CsLog.CutRunner(SessionInformation.Callstack));
    end;
}

codeunit 68935 "Probe Session Callstack"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CsLog: Codeunit "Probe CS Log";

    local procedure AppSuffix(): Text
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(' - ' + Info.Name + ' by ' + Info.Publisher + ' version ' + Format(Info.AppVersion) + '\');
    end;

    local procedure Inner(): Text
    begin
        exit(SessionInformation.Callstack);
    end;

    local procedure Middle(): Text
    begin
        exit(Inner());
    end;

    local procedure Failing()
    begin
        CsLog.Add('in asserterror: ' + CsLog.CutRunner(SessionInformation.Callstack));
        Error('boom');
    end;

    local procedure Deep(Depth: Integer): Text
    begin
        if Depth = 0 then
            exit(SessionInformation.Callstack);
        exit(Deep(Depth - 1));
    end;

    [Test]
    procedure Callstack_Frames_BackslashSeparated_InnermostFirst()
    var
        Stack: Text;
        Suffix: Text;
    begin
        Suffix := AppSuffix();

        Stack := Middle();

        Assert.IsTrue(
            CsLog.CutRunner(Stack) = '"Probe Session Callstack"(CodeUnit 68935).Inner line 2' + Suffix +
            '"Probe Session Callstack"(CodeUnit 68935).Middle line 2' + Suffix +
            '"Probe Session Callstack"(CodeUnit 68935).Callstack_Frames_BackslashSeparated_InnermostFirst line 7' + Suffix,
            'frames of the test: ' + CsLog.CutRunner(Stack));
        Assert.IsTrue(Stack.EndsWith('\'), 'ends with a backslash');
        Assert.IsFalse(Stack.Contains(Format(CharAt(10))), 'no line feed');
        Assert.IsFalse(Stack.Contains(Format(CharAt(13))), 'no carriage return');
    end;

    local procedure CharAt(Code: Integer): Text
    var
        Result: Text[1];
    begin
        Result[1] := Code;
        exit(Result);
    end;

    [Test]
    procedure Callstack_InTriggersCodeunitRunsAndSubscribers()
    var
        CsRec: Record "Probe CS Table";
        CsRunner: Codeunit "Probe CS Runner";
        CsPublisher: Codeunit "Probe CS Publisher";
        Suffix: Text;
    begin
        Suffix := AppSuffix();
        CsLog.Take();

        CsRec.Id := 1;
        CsRec.Validate(Val, 5);
        CsRec.Insert(true);
        CsRunner.Run();
        Codeunit.Run(Codeunit::"Probe CS Runner");
        CsPublisher.Fire();

        Assert.AreEqual(
            'OnValidate: "Probe CS Table"(Table 68930)."Val - OnValidate"(Trigger) line 2' + Suffix + '"Probe Session Callstack"(CodeUnit 68935).Callstack_InTriggersCodeunitRunsAndSubscribers line 11' + Suffix + '|' +
            'OnInsert: "Probe CS Table"(Table 68930).OnInsert(Trigger) line 2' + Suffix + '"Probe Session Callstack"(CodeUnit 68935).Callstack_InTriggersCodeunitRunsAndSubscribers line 12' + Suffix + '|' +
            'OnRun: "Probe CS Runner"(CodeUnit 68932).OnRun(Trigger) line 4' + Suffix + '"Probe Session Callstack"(CodeUnit 68935).Callstack_InTriggersCodeunitRunsAndSubscribers line 13' + Suffix + '|' +
            'OnRun: "Probe CS Runner"(CodeUnit 68932).OnRun(Trigger) line 4' + Suffix + '"Probe Session Callstack"(CodeUnit 68935).Callstack_InTriggersCodeunitRunsAndSubscribers line 14' + Suffix + '|' +
            'Subscriber: "Probe CS Subscriber"(CodeUnit 68934).Handle line 4' + Suffix + '"Probe CS Publisher"(CodeUnit 68933).OnEvent(Event) line 2' + Suffix +
            '"Probe CS Publisher"(CodeUnit 68933).Fire line 2' + Suffix + '"Probe Session Callstack"(CodeUnit 68935).Callstack_InTriggersCodeunitRunsAndSubscribers line 15' + Suffix + '|',
            CsLog.Take(), 'log');
    end;

    [Test]
    procedure Callstack_InAsserterror_AndGetLastErrorCallStack_UseTheSameForm()
    var
        Suffix: Text;
        Last: Text;
    begin
        Suffix := AppSuffix();
        CsLog.Take();

        asserterror Failing();
        Last := GetLastErrorCallStack();

        Assert.AreEqual(
            'in asserterror: "Probe Session Callstack"(CodeUnit 68935).Failing line 2' + Suffix + '"Probe Session Callstack"(CodeUnit 68935).Callstack_InAsserterror_AndGetLastErrorCallStack_UseTheSameForm line 8' + Suffix + '|',
            CsLog.Take(), 'inside');
        Assert.AreEqual(
            '"Probe Session Callstack"(CodeUnit 68935).Failing line 3' + Suffix + '"Probe Session Callstack"(CodeUnit 68935).Callstack_InAsserterror_AndGetLastErrorCallStack_UseTheSameForm line 8' + Suffix,
            CsLog.CutRunner(Last), 'GetLastErrorCallStack');
        Assert.IsFalse(Last.Contains('Failing line 2'), 'the error is at the Error call');
        Assert.AreEqual(
            '"Probe Session Callstack"(CodeUnit 68935).Callstack_InAsserterror_AndGetLastErrorCallStack_UseTheSameForm line 18' + Suffix,
            CsLog.CutRunner(SessionInformation.Callstack), 'after the asserterror');
    end;

    [Test]
    procedure Callstack_IsNotCut_OfNestedProcedures()
    var
        Stack: Text;
        Own: Text;
        Backslashes: Integer;
        Index: Integer;
    begin
        Stack := Deep(300);
        Own := CsLog.CutRunner(Stack);
        for Index := 1 to StrLen(Own) do
            if Own[Index] = '\' then
                Backslashes += 1;

        Assert.AreEqual(302, Backslashes, '301 nested frames and the test procedure, whatever the runner adds below');
        Assert.IsTrue(StrLen(Own) > 20000, 'not cut');
        Assert.IsTrue(Stack.EndsWith('\'), 'ends with a backslash');
    end;
}
