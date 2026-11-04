// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorobject-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (GetLastErrorObject has scope OnPrem; must-not-compile case 0110), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160) and table "Probe Observer Entry" (69162), from the AL Language Coverage Tests app; self-contained codeunits 61470 (thrower) and 61471 (tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorObject stored in a DotNet Exception: Message, GetType().FullName, whether InnerException is null, Format and ToString of it, and Message compared with GetLastErrorText;
//   after Error() caught by Codeunit.Run, by a TryFunction and by asserterror, after platform errors (Get without a row, division by zero), without an error and after ClearLastError.
//   Corpus issue 572.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Exception"; LtLeoExc) { }
        type("System.Type"; LtLeoType) { }
    }
}

codeunit 61470 "LT LEO Thrower"
{
    var
        Mode: Integer;

    trigger OnRun()
    var
        Entry: Record "Probe Observer Entry";
        Zero: Integer;
        Result: Integer;
    begin
        case Mode of
            1:
                Error('LT boom from Codeunit.Run');
            2:
                Entry.Get(-987654);
            3:
                Result := 1 div Zero;
            4:
                Error('LT boom with %1 and %2', 'arg', 42);
        end;
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;

    [TryFunction]
    procedure TryRaise()
    begin
        Error('LT boom from TryFunction');
    end;

    procedure Raise()
    begin
        Error('LT boom from asserterror');
    end;
}

codeunit 61471 "LT LEO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // The object is fetched once, directly (a try function would replace the last error), then every question is asked of it.
    local procedure Describe(var Observer: Codeunit "Probe Observer")
    var
        Exc: DotNet LtLeoExc;
        TypeOfExc: DotNet LtLeoType;
        LastText: Text;
        LastCode: Text;
    begin
        LastText := GetLastErrorText();
        LastCode := GetLastErrorCode();
        Exc := GetLastErrorObject();
        Observer.Observe('isNull', Format(IsNull(Exc)));
        Observer.Observe('lastErrorText', LastText);
        Observer.Observe('lastErrorCode', LastCode);
        if IsNull(Exc) then
            exit;
        Observer.Observe('message', Exc.Message);
        Observer.Observe('messageEqualsLastErrorText', Format(Exc.Message = LastText));
        TypeOfExc := Exc.GetType();
        Observer.Observe('typeFullName', TypeOfExc.FullName);
        Observer.Observe('innerExceptionIsNull', Format(IsNull(Exc.InnerException)));
        // The stack frames in the text depend on the BC version (compiler generated class names), so only the first line and the shape are asserted.
        Observer.Observe('formatEqualsToString', Format(Format(Exc) = Exc.ToString()));
        Observer.Observe('toStringFirstLine', FirstLine(Exc.ToString()));
        Observer.Observe('toStringHasStackFrames', Format(StrPos(Exc.ToString(), '   at ') > 0));
    end;

    local procedure FirstLine(Value: Text): Text
    var
        Lf: Text[1];
    begin
        Lf[1] := 10;
        exit(CopyStr(Value, 1, StrPos(Value + Lf, Lf) - 1));
    end;

    [TryFunction]
    local procedure TryOne(Which: Integer; var Result: Text)
    var
        Exc: DotNet LtLeoExc;
        TypeOfExc: DotNet LtLeoType;
    begin
        Exc := GetLastErrorObject();
        case Which of
            1:
                Result := Format(IsNull(Exc));
            2:
                Result := Exc.Message;
            3:
                begin
                    TypeOfExc := Exc.GetType();
                    Result := TypeOfExc.FullName;
                end;
            4:
                Result := Format(Exc);
            5:
                Result := Exc.ToString();
        end;
    end;

    local procedure DescribeGuarded(var Observer: Codeunit "Probe Observer")
    var
        Which: Integer;
        Result: Text;
    begin
        for Which := 1 to 5 do begin
            ClearLastError();
            Result := '';
            if TryOne(Which, Result) then
                Observer.Observe('field' + Format(Which), 'ok:' + Result)
            else
                Observer.Observe('field' + Format(Which), 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        end;
    end;

    [Test]
    procedure GetLastErrorObject_AfterErrorInCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Thrower: Codeunit "LT LEO Thrower";
        Ran: Boolean;
    begin
        Thrower.SetMode(1);
        Ran := Thrower.Run();
        Observer.Observe('ran', Format(Ran));
        Describe(Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('isNull', 'No');
        Observer.Expect('lastErrorText', 'LT boom from Codeunit.Run');
        Observer.Expect('lastErrorCode', 'Dialog');
        Observer.Expect('message', 'LT boom from Codeunit.Run');
        Observer.Expect('messageEqualsLastErrorText', 'Yes');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('formatEqualsToString', 'Yes');
        Observer.Expect('toStringFirstLine', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT boom from Codeunit.Run');
        Observer.Expect('toStringHasStackFrames', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetLastErrorObject_AfterErrorWithSubstitutionsInCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Thrower: Codeunit "LT LEO Thrower";
        Ran: Boolean;
    begin
        Thrower.SetMode(4);
        Ran := Thrower.Run();
        Observer.Observe('ran', Format(Ran));
        Describe(Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('isNull', 'No');
        Observer.Expect('lastErrorText', 'LT boom with arg and 42');
        Observer.Expect('lastErrorCode', 'Dialog');
        Observer.Expect('message', 'LT boom with arg and 42');
        Observer.Expect('messageEqualsLastErrorText', 'Yes');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('formatEqualsToString', 'Yes');
        Observer.Expect('toStringFirstLine', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT boom with arg and 42');
        Observer.Expect('toStringHasStackFrames', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetLastErrorObject_AfterErrorInTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Thrower: Codeunit "LT LEO Thrower";
        Ok: Boolean;
    begin
        Ok := Thrower.TryRaise();
        Observer.Observe('ok', Format(Ok));
        Describe(Observer);
        Observer.Expect('ok', 'No');
        Observer.Expect('isNull', 'No');
        Observer.Expect('lastErrorText', 'LT boom from TryFunction');
        Observer.Expect('lastErrorCode', 'Dialog');
        Observer.Expect('message', 'LT boom from TryFunction');
        Observer.Expect('messageEqualsLastErrorText', 'Yes');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('formatEqualsToString', 'Yes');
        Observer.Expect('toStringFirstLine', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT boom from TryFunction');
        Observer.Expect('toStringHasStackFrames', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetLastErrorObject_AfterErrorInAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Thrower: Codeunit "LT LEO Thrower";
    begin
        asserterror Thrower.Raise();
        Describe(Observer);
        Observer.Expect('isNull', 'No');
        Observer.Expect('lastErrorText', 'LT boom from asserterror');
        Observer.Expect('lastErrorCode', 'Dialog');
        Observer.Expect('message', 'LT boom from asserterror');
        Observer.Expect('messageEqualsLastErrorText', 'Yes');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('formatEqualsToString', 'Yes');
        Observer.Expect('toStringFirstLine', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT boom from asserterror');
        Observer.Expect('toStringHasStackFrames', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetLastErrorObject_AfterGetWithoutRow()
    var
        Observer: Codeunit "Probe Observer";
        Thrower: Codeunit "LT LEO Thrower";
        Ran: Boolean;
    begin
        Thrower.SetMode(2);
        Ran := Thrower.Run();
        Observer.Observe('ran', Format(Ran));
        Describe(Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('isNull', 'No');
        Observer.Expect('lastErrorText', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('lastErrorCode', 'DB:RecordNotFound');
        Observer.Expect('message', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('messageEqualsLastErrorText', 'Yes');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideRecordNotFoundException');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('formatEqualsToString', 'Yes');
        Observer.Expect('toStringFirstLine', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideRecordNotFoundException: The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('toStringHasStackFrames', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetLastErrorObject_AfterDivisionByZero()
    var
        Observer: Codeunit "Probe Observer";
        Thrower: Codeunit "LT LEO Thrower";
        Ran: Boolean;
    begin
        Thrower.SetMode(3);
        Ran := Thrower.Run();
        Observer.Observe('ran', Format(Ran));
        Describe(Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('isNull', 'No');
        Observer.Expect('lastErrorText', 'Attempted to divide by zero.');
        Observer.Expect('lastErrorCode', 'AL:DivideByZero');
        Observer.Expect('message', 'Attempted to divide by zero.');
        Observer.Expect('messageEqualsLastErrorText', 'Yes');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException');
        Observer.Expect('innerExceptionIsNull', 'No');
        Observer.Expect('formatEqualsToString', 'Yes');
        Observer.Expect('toStringFirstLine', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException: Attempted to divide by zero.');
        Observer.Expect('toStringHasStackFrames', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetLastErrorObject_AfterClearLastError_EachFieldGuarded()
    var
        Observer: Codeunit "Probe Observer";
        Thrower: Codeunit "LT LEO Thrower";
        Ran: Boolean;
    begin
        Thrower.SetMode(1);
        Ran := Thrower.Run();
        ClearLastError();
        Observer.Observe('lastErrorTextAfterClear', GetLastErrorText());
        DescribeGuarded(Observer);
        Observer.Expect('lastErrorTextAfterClear', '');
        Observer.Expect('field1', 'ok:Yes');
        Observer.Expect('field2', 'error:A DotNet variable has not been instantiated. Attempting to call System.Exception.Message in CodeUnit LT LEO Tests: TryOne|DotNetVariableNotCreated');
        Observer.Expect('field3', 'error:A DotNet variable has not been instantiated. Attempting to call System.Exception.GetType in CodeUnit LT LEO Tests: TryOne|DotNetVariableNotCreated');
        Observer.Expect('field4', 'ok:null');
        Observer.Expect('field5', 'error:A DotNet variable has not been instantiated. Attempting to call System.Exception.ToString in CodeUnit LT LEO Tests: TryOne|DotNetVariableNotCreated');
        Observer.Verify();
    end;

    [Test]
    procedure GetLastErrorObject_AfterSuccessfulRunFollowingAnError_EachFieldGuarded()
    var
        Observer: Codeunit "Probe Observer";
        Thrower: Codeunit "LT LEO Thrower";
        Ran: Boolean;
    begin
        Thrower.SetMode(1);
        Ran := Thrower.Run();
        Thrower.SetMode(0);
        Ran := Thrower.Run();
        Observer.Observe('ranSecond', Format(Ran));
        Observer.Observe('lastErrorTextAfterSuccess', GetLastErrorText());
        Describe(Observer);
        Observer.Expect('ranSecond', 'Yes');
        Observer.Expect('lastErrorTextAfterSuccess', 'LT boom from Codeunit.Run');
        Observer.Expect('isNull', 'No');
        Observer.Expect('lastErrorText', 'LT boom from Codeunit.Run');
        Observer.Expect('lastErrorCode', 'Dialog');
        Observer.Expect('message', 'LT boom from Codeunit.Run');
        Observer.Expect('messageEqualsLastErrorText', 'Yes');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('formatEqualsToString', 'Yes');
        Observer.Expect('toStringFirstLine', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT boom from Codeunit.Run');
        Observer.Expect('toStringHasStackFrames', 'Yes');
        Observer.Verify();
    end;
}
