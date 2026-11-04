// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorobject-method
// Not pinned: GetLastErrorObject in a session where no error has happened. StartSession is refused inside a test ("Sessions can only be started in tests that are run by a TestRunner that has
//   TestIsolation set to Disabled"), and the state in the test session depends on the tests that ran before. The cleared state (null, Format = null) is pinned in GetLastErrorObject.al.
// Scope: in-scope, but ONLY for a Target = OnPrem app, AL compiler 18.0 or newer (see GetLastErrorObject.al and TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; Base Application codeunit "DotNet Exception Handler" (1291); self-contained codeunits 61480, 61481, 61483 and 61484
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: after an error caught by Codeunit.Run: the class (GetType().FullName), Message, GetLastErrorCode, InnerException null or not, and GetBaseException() class and Message, for
//   Error(Label), Error(Text variable), Error(ErrorInfo), a failing TestField, Modify and Delete of a row that does not exist and an Evaluate without a return value;
//   Type.Equals for two exceptions of the same and of different kinds; the lines of ToString of a dialog exception;
//   what "DotNet Exception Handler".Rethrow raises after each kind. Corpus issue 577.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Exception"; LtLekExc) { }
        type("System.Type"; LtLekType) { }
    }
}

codeunit 61480 "LT LEK Thrower"
{
    var
        Mode: Integer;
        MessageLabel: Label 'LT label error %1', Locked = true;

    trigger OnRun()
    var
        Entry: Record "Probe Observer Entry";
        Info: ErrorInfo;
        Text1: Text;
        Number: Integer;
        Zero: Integer;
        Result: Integer;
    begin
        case Mode of
            1:
                Error(MessageLabel, 'arg');
            2:
                begin
                    Text1 := 'LT text variable error';
                    Error(Text1);
                end;
            3:
                begin
                    Info := ErrorInfo.Create('LT errorinfo message');
                    Error(Info);
                end;
            4:
                begin
                    Entry."Entry No." := 0;
                    Entry.TestField("Entry No.", 5);
                end;
            5:
                begin
                    Entry."Entry No." := -987654;
                    Entry.Modify();
                end;
            6:
                begin
                    Entry."Entry No." := -987654;
                    Entry.Delete();
                end;
            7:
                Evaluate(Number, 'not a number');
            8:
                Error('LT plain literal');
            9:
                Result := 1 div Zero;
            10:
                Entry.TestField("Entry No.");
            11:
                Error('LT second literal');
        end;
    end;

    procedure SetMode(NewMode: Integer)
    begin
        Mode := NewMode;
    end;
}

codeunit 61481 "LT LEK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(Mode: Integer; var Observer: Codeunit "Probe Observer")
    var
        Thrower: Codeunit "LT LEK Thrower";
        Exc: DotNet LtLekExc;
        Base: DotNet LtLekExc;
        TypeOfExc: DotNet LtLekType;
        Ran: Boolean;
    begin
        Thrower.SetMode(Mode);
        Ran := Thrower.Run();
        Observer.Observe('ran', Format(Ran));
        Observer.Observe('lastErrorText', GetLastErrorText());
        Observer.Observe('lastErrorCode', GetLastErrorCode());
        Exc := GetLastErrorObject();
        Observer.Observe('isNull', Format(IsNull(Exc)));
        if IsNull(Exc) then
            exit;
        TypeOfExc := Exc.GetType();
        Observer.Observe('typeFullName', TypeOfExc.FullName);
        Observer.Observe('message', Exc.Message);
        Observer.Observe('innerExceptionIsNull', Format(IsNull(Exc.InnerException)));
        Base := Exc.GetBaseException();
        Observer.Observe('baseIsNull', Format(IsNull(Base)));
        if IsNull(Base) then
            exit;
        TypeOfExc := Base.GetType();
        Observer.Observe('baseTypeFullName', TypeOfExc.FullName);
        Observer.Observe('baseMessage', Base.Message);
    end;

    [Test]
    procedure Kind_ErrorWithLabel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(1, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'LT label error arg');
        Observer.Expect('lastErrorCode', 'Dialog');
        Observer.Expect('isNull', 'No');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('message', 'LT label error arg');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('baseIsNull', 'No');
        Observer.Expect('baseTypeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('baseMessage', 'LT label error arg');
        Observer.Verify();
    end;

    [Test]
    procedure Kind_ErrorWithTextVariable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(2, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'LT text variable error');
        Observer.Expect('lastErrorCode', 'Dialog');
        Observer.Expect('isNull', 'No');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('message', 'LT text variable error');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('baseIsNull', 'No');
        Observer.Expect('baseTypeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('baseMessage', 'LT text variable error');
        Observer.Verify();
    end;

    [Test]
    procedure Kind_ErrorWithErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(3, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'LT errorinfo message');
        Observer.Expect('lastErrorCode', 'Dialog');
        Observer.Expect('isNull', 'No');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('message', 'LT errorinfo message');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('baseIsNull', 'No');
        Observer.Expect('baseTypeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('baseMessage', 'LT errorinfo message');
        Observer.Verify();
    end;

    [Test]
    procedure Kind_FailingTestFieldWithValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(4, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'Entry No. must be equal to ''5''  in Probe Observer Entry: Entry No.=0. Current value is ''0''.');
        Observer.Expect('lastErrorCode', 'TestField');
        Observer.Expect('isNull', 'No');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.NavTestFieldException');
        Observer.Expect('message', 'Entry No. must be equal to ''5''  in Probe Observer Entry: Entry No.=0. Current value is ''0''.');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('baseIsNull', 'No');
        Observer.Expect('baseTypeFullName', 'Microsoft.Dynamics.Nav.Types.NavTestFieldException');
        Observer.Expect('baseMessage', 'Entry No. must be equal to ''5''  in Probe Observer Entry: Entry No.=0. Current value is ''0''.');
        Observer.Verify();
    end;

    [Test]
    procedure Kind_FailingTestFieldWithoutValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(10, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'Entry No. must have a value in Probe Observer Entry: Entry No.=0. It cannot be zero or empty.');
        Observer.Expect('lastErrorCode', 'TestField');
        Observer.Expect('isNull', 'No');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.NavTestFieldException');
        Observer.Expect('message', 'Entry No. must have a value in Probe Observer Entry: Entry No.=0. It cannot be zero or empty.');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('baseIsNull', 'No');
        Observer.Expect('baseTypeFullName', 'Microsoft.Dynamics.Nav.Types.NavTestFieldException');
        Observer.Expect('baseMessage', 'Entry No. must have a value in Probe Observer Entry: Entry No.=0. It cannot be zero or empty.');
        Observer.Verify();
    end;

    [Test]
    procedure Kind_ModifyOfMissingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(5, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('lastErrorCode', 'DB:RecordNotFound');
        Observer.Expect('isNull', 'No');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideRecordNotFoundException');
        Observer.Expect('message', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('baseIsNull', 'No');
        Observer.Expect('baseTypeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideRecordNotFoundException');
        Observer.Expect('baseMessage', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Verify();
    end;

    [Test]
    procedure Kind_DeleteOfMissingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(6, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('lastErrorCode', 'DB:RecordNotFound');
        Observer.Expect('isNull', 'No');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideRecordNotFoundException');
        Observer.Expect('message', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('baseIsNull', 'No');
        Observer.Expect('baseTypeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavCSideRecordNotFoundException');
        Observer.Expect('baseMessage', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Verify();
    end;

    [Test]
    procedure Kind_EvaluateWithoutReturnValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(7, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'The value "not a number" can''t be evaluated into type Integer.');
        Observer.Expect('lastErrorCode', 'Evaluate');
        Observer.Expect('isNull', 'No');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLEvaluateException');
        Observer.Expect('message', 'The value "not a number" can''t be evaluated into type Integer.');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('baseIsNull', 'No');
        Observer.Expect('baseTypeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLEvaluateException');
        Observer.Expect('baseMessage', 'The value "not a number" can''t be evaluated into type Integer.');
        Observer.Verify();
    end;

    [Test]
    procedure Kind_ErrorWithLiteral()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(8, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'LT plain literal');
        Observer.Expect('lastErrorCode', 'Dialog');
        Observer.Expect('isNull', 'No');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('message', 'LT plain literal');
        Observer.Expect('innerExceptionIsNull', 'Yes');
        Observer.Expect('baseIsNull', 'No');
        Observer.Expect('baseTypeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('baseMessage', 'LT plain literal');
        Observer.Verify();
    end;

    [Test]
    procedure Kind_DivisionByZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Describe(9, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'Attempted to divide by zero.');
        Observer.Expect('lastErrorCode', 'AL:DivideByZero');
        Observer.Expect('isNull', 'No');
        Observer.Expect('typeFullName', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavALException');
        Observer.Expect('message', 'Attempted to divide by zero.');
        Observer.Expect('innerExceptionIsNull', 'No');
        Observer.Expect('baseIsNull', 'No');
        Observer.Expect('baseTypeFullName', 'System.DivideByZeroException');
        Observer.Expect('baseMessage', 'Attempted to divide by zero.');
        Observer.Verify();
    end;
}

codeunit 61483 "LT LEK Member Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fail(Mode: Integer): Boolean
    var
        Thrower: Codeunit "LT LEK Thrower";
    begin
        Thrower.SetMode(Mode);
        exit(Thrower.Run());
    end;

    local procedure SameType(A: DotNet LtLekExc; B: DotNet LtLekExc): Text
    var
        TypeA: DotNet LtLekType;
        TypeB: DotNet LtLekType;
    begin
        TypeA := A.GetType();
        TypeB := B.GetType();
        exit(Format(TypeA.Equals(TypeB)));
    end;

    [Test]
    procedure Type_Equals_SameKinds()
    var
        Observer: Codeunit "Probe Observer";
        First: DotNet LtLekExc;
        Second: DotNet LtLekExc;
    begin
        Fail(8);
        First := GetLastErrorObject();
        Fail(11);
        Second := GetLastErrorObject();
        Observer.Observe('dialog_dialog', SameType(First, Second));
        Observer.Observe('dialog_dialog_messagesDiffer', Format(First.Message <> Second.Message));
        Observer.Observe('dialog_dialog_sameObject', Format(First.Equals(Second)));
        Observer.Observe('dialog_self_sameObject', Format(First.Equals(First)));
        Fail(5);
        First := GetLastErrorObject();
        Fail(6);
        Second := GetLastErrorObject();
        Observer.Observe('notFound_notFound', SameType(First, Second));
        Observer.Expect('dialog_dialog', 'Yes');
        Observer.Expect('dialog_dialog_messagesDiffer', 'Yes');
        Observer.Expect('dialog_dialog_sameObject', 'No');
        Observer.Expect('dialog_self_sameObject', 'Yes');
        Observer.Expect('notFound_notFound', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Type_Equals_DifferentKinds()
    var
        Observer: Codeunit "Probe Observer";
        Dialog: DotNet LtLekExc;
        NotFound: DotNet LtLekExc;
        Division: DotNet LtLekExc;
    begin
        Fail(8);
        Dialog := GetLastErrorObject();
        Fail(5);
        NotFound := GetLastErrorObject();
        Fail(9);
        Division := GetLastErrorObject();
        Observer.Observe('dialog_notFound', SameType(Dialog, NotFound));
        Observer.Observe('dialog_division', SameType(Dialog, Division));
        Observer.Observe('notFound_division', SameType(NotFound, Division));
        Observer.Expect('dialog_notFound', 'No');
        Observer.Expect('dialog_division', 'No');
        Observer.Expect('notFound_division', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ToString_DialogException_Lines()
    var
        Observer: Codeunit "Probe Observer";
        Exc: DotNet LtLekExc;
        Lines: List of [Text];
        Lf: Text[1];
        Text1: Text;
        Index: Integer;
    begin
        Fail(8);
        Exc := GetLastErrorObject();
        Lf[1] := 10;
        Text1 := Exc.ToString();
        Lines := Text1.Split(Lf);
        Observer.Observe('lineCount', Format(Lines.Count()));
        Observer.Observe('endsWithLineFeed', Format(Text1.EndsWith(Lf)));
        for Index := 1 to Lines.Count() do
            if Index <= 12 then
                Observer.Observe('line' + Format(Index), Lines.Get(Index));
        Observer.Expect('lineCount', '4');
        Observer.Expect('endsWithLineFeed', 'No');
        Observer.Expect('line1', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException: LT plain literal');
        Observer.Expect('line2', '   at Microsoft.Dynamics.Nav.Runtime.NavDialog.ALError(NavSession session, Guid automationId, String message, NavValue[] values)');
        Observer.Expect('line3', '   at Microsoft.Dynamics.Nav.BusinessApplication.Codeunit61480.OnRunAsync(INavRecordHandle εrec)');
        Observer.Expect('line4', '   at Microsoft.Dynamics.Nav.Runtime.NavCodeunit.DoRunAsync(DataError errorLevel, NavRecord record)');
        Observer.Verify();
    end;
}

codeunit 61484 "LT LEK Rethrow Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AfterError(Mode: Integer; var Observer: Codeunit "Probe Observer")
    var
        Thrower: Codeunit "LT LEK Thrower";
        Handler: Codeunit "DotNet Exception Handler";
        Exc: DotNet LtLekExc;
        TypeOfExc: DotNet LtLekType;
    begin
        Thrower.SetMode(Mode);
        Observer.Observe('ran', Format(Thrower.Run()));
        Observer.Observe('lastErrorText', GetLastErrorText());
        Handler.Collect();
        Observer.Observe('handlerMessage', Handler.GetMessage());
        Exc := GetLastErrorObject();
        TypeOfExc := Exc.GetType();
        Observer.Observe('tryCastToOwnType', Format(Handler.TryCastToType(TypeOfExc)));
        ClearLastError();
        asserterror Handler.Rethrow();
        Observer.Observe('rethrowText', GetLastErrorText());
        Observer.Observe('rethrowCode', GetLastErrorCode());
        Exc := GetLastErrorObject();
        TypeOfExc := Exc.GetType();
        Observer.Observe('rethrowType', TypeOfExc.FullName);
        Observer.Observe('rethrowInnerIsNull', Format(IsNull(Exc.InnerException)));
    end;

    [Test]
    procedure Rethrow_AfterErrorWithLabel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(1, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'LT label error arg');
        Observer.Expect('handlerMessage', 'LT label error arg');
        Observer.Expect('tryCastToOwnType', 'Yes');
        Observer.Expect('rethrowText', 'LT label error arg');
        Observer.Expect('rethrowCode', 'Dialog');
        Observer.Expect('rethrowType', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('rethrowInnerIsNull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rethrow_AfterErrorWithTextVariable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(2, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'LT text variable error');
        Observer.Expect('handlerMessage', 'LT text variable error');
        Observer.Expect('tryCastToOwnType', 'Yes');
        Observer.Expect('rethrowText', 'LT text variable error');
        Observer.Expect('rethrowCode', 'Dialog');
        Observer.Expect('rethrowType', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('rethrowInnerIsNull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rethrow_AfterErrorWithErrorInfo()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(3, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'LT errorinfo message');
        Observer.Expect('handlerMessage', 'LT errorinfo message');
        Observer.Expect('tryCastToOwnType', 'Yes');
        Observer.Expect('rethrowText', 'LT errorinfo message');
        Observer.Expect('rethrowCode', 'Dialog');
        Observer.Expect('rethrowType', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('rethrowInnerIsNull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rethrow_AfterFailingTestField()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(4, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'Entry No. must be equal to ''5''  in Probe Observer Entry: Entry No.=0. Current value is ''0''.');
        Observer.Expect('handlerMessage', 'Entry No. must be equal to ''5''  in Probe Observer Entry: Entry No.=0. Current value is ''0''.');
        Observer.Expect('tryCastToOwnType', 'Yes');
        Observer.Expect('rethrowText', 'Entry No. must be equal to ''5''  in Probe Observer Entry: Entry No.=0. Current value is ''0''.');
        Observer.Expect('rethrowCode', 'Dialog');
        Observer.Expect('rethrowType', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('rethrowInnerIsNull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rethrow_AfterModifyOfMissingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(5, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('handlerMessage', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('tryCastToOwnType', 'Yes');
        Observer.Expect('rethrowText', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('rethrowCode', 'Dialog');
        Observer.Expect('rethrowType', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('rethrowInnerIsNull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rethrow_AfterDeleteOfMissingRow()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(6, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('handlerMessage', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('tryCastToOwnType', 'Yes');
        Observer.Expect('rethrowText', 'The Probe Observer Entry does not exist. Identification fields and values: Entry No.=''-987654''');
        Observer.Expect('rethrowCode', 'Dialog');
        Observer.Expect('rethrowType', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('rethrowInnerIsNull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rethrow_AfterEvaluateWithoutReturnValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(7, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'The value "not a number" can''t be evaluated into type Integer.');
        Observer.Expect('handlerMessage', 'The value "not a number" can''t be evaluated into type Integer.');
        Observer.Expect('tryCastToOwnType', 'Yes');
        Observer.Expect('rethrowText', 'The value "not a number" can''t be evaluated into type Integer.');
        Observer.Expect('rethrowCode', 'Dialog');
        Observer.Expect('rethrowType', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('rethrowInnerIsNull', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Rethrow_AfterDivisionByZero()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AfterError(9, Observer);
        Observer.Expect('ran', 'No');
        Observer.Expect('lastErrorText', 'Attempted to divide by zero.');
        Observer.Expect('handlerMessage', 'Attempted to divide by zero.');
        Observer.Expect('tryCastToOwnType', 'No');
        Observer.Expect('rethrowText', 'Attempted to divide by zero.');
        Observer.Expect('rethrowCode', 'Dialog');
        Observer.Expect('rethrowType', 'Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLDialogException');
        Observer.Expect('rethrowInnerIsNull', 'Yes');
        Observer.Verify();
    end;
}
