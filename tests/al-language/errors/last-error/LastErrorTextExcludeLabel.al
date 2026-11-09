// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 70868 and codeunit 70869
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorText(true) against GetLastErrorText(false) for Error(Label), Error(Label, args of each type), a text built by StrSubstNo, ErrorInfo.Message from a Label, an error raised inside a nested TryFunction call, Error from a codeunit run through Codeunit.Run, a record Get with a composite key that is missing, Modify and Insert errors that carry a key value.
// BC versions: 29 (27 and 28 by CI)

table 70868 "LT LET Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Sub; Integer) { }
        field(3; Name; Text[50]) { }
    }

    keys { key(PK; Code, Sub) { Clustered = true; } }
}

codeunit 70869 "LT Err Text Exclude Label"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        PlainLbl: Label 'A label without arguments';
        OneArgLbl: Label 'A label with %1';
        TwoArgLbl: Label 'Customer %1 owes %2';
        NameLbl: Label 'Name', Locked = true;
        InfoLbl: Label 'Info message from a label %1';

    [TryFunction]
    local procedure TryLabel()
    begin
        Error(PlainLbl);
    end;

    [TryFunction]
    local procedure TryLabelOneArg(Value: Text)
    begin
        Error(OneArgLbl, Value);
    end;

    [TryFunction]
    local procedure TryLabelTwoArgs(Value: Text; Amount: Decimal)
    begin
        Error(TwoArgLbl, Value, Amount);
    end;

    [TryFunction]
    local procedure TryStrSubstNo(Value: Text)
    begin
        Error(StrSubstNo(OneArgLbl, Value));
    end;

    [TryFunction]
    local procedure TryErrorInfoLabel(Value: Text)
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := StrSubstNo(InfoLbl, Value);
        Error(ErrInfo);
    end;

    [TryFunction]
    local procedure TryDateArg(D: Date; T: Time; B: Boolean)
    begin
        Error('Date %1 time %2 bool %3', D, T, B);
    end;

    [TryFunction]
    local procedure TryOptionEnumArg(Kind: Option A,B,C)
    begin
        Error('Kind %1', Kind);
    end;

    [TryFunction]
    local procedure TryOuter(Value: Text)
    begin
        TryInner(Value);
        Error('Outer after inner %1', Value);
    end;

    [TryFunction]
    local procedure TryInner(Value: Text)
    begin
        Error('Inner %1', Value);
    end;

    [TryFunction]
    local procedure TryGetCompositeMissing()
    var
        Row: Record "LT LET Row";
    begin
        Row.Get('MISSING', 7);
    end;

    [TryFunction]
    local procedure TryFieldErrorLabel()
    var
        Row: Record "LT LET Row";
    begin
        Row.Code := 'SECRET1';
        Row.Sub := 3;
        Row.FieldError(Name, PlainLbl);
    end;

    [TryFunction]
    local procedure TryFieldErrorValue()
    var
        Row: Record "LT LET Row";
    begin
        Row.Code := 'SECRET2';
        Row.Name := 'secret name';
        Row.FieldError(Name);
    end;

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_true', GetLastErrorText(true));
        Observer.Observe(Name + '_false', GetLastErrorText(false));
        Observer.Observe(Name + '_code', GetLastErrorCode());
    end;

    [Test]
    procedure ExcludeFlag_LabelNoArgs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try', Format(TryLabel()));
        Forms('label', Observer);
        Observer.Expect('try', 'No');
        Observer.Expect('label_true', 'A label without arguments');
        Observer.Expect('label_false', 'A label without arguments');
        Observer.Expect('label_code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ExcludeFlag_LabelWithArgs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try1', Format(TryLabelOneArg('customer value')));
        Forms('one', Observer);
        Observer.Observe('try2', Format(TryLabelTwoArgs('C10', 12.5)));
        Forms('two', Observer);
        Observer.Observe('try3', Format(TryStrSubstNo('substituted')));
        Forms('subst', Observer);
        Observer.Expect('try1', 'No');
        Observer.Expect('one_true', 'A label with %1');
        Observer.Expect('one_false', 'A label with customer value');
        Observer.Expect('one_code', 'Dialog');
        Observer.Expect('try2', 'No');
        Observer.Expect('two_true', 'Customer %1 owes %2');
        Observer.Expect('two_false', 'Customer C10 owes 12.5');
        Observer.Expect('two_code', 'Dialog');
        Observer.Expect('try3', 'No');
        Observer.Expect('subst_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('subst_false', 'A label with substituted');
        Observer.Expect('subst_code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ExcludeFlag_ErrorInfoMessageFromLabel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try', Format(TryErrorInfoLabel('x')));
        Forms('info', Observer);
        Observer.Expect('try', 'No');
        Observer.Expect('info_true', 'This message had personal data removed. The original may still be in transient telemetry. Find it using the transientTelemetryId.');
        Observer.Expect('info_false', 'Info message from a label x');
        Observer.Expect('info_code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ExcludeFlag_DateTimeBooleanOptionArgs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try1', Format(TryDateArg(DMY2Date(5, 3, 2027), 123456T, true)));
        Forms('dtb', Observer);
        Observer.Observe('try2', Format(TryOptionEnumArg(1)));
        Forms('option', Observer);
        Observer.Expect('try1', 'No');
        Observer.Expect('dtb_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('dtb_false', 'Date 03/05/27 time 12:34:56 PM bool Yes');
        Observer.Expect('dtb_code', 'Dialog');
        Observer.Expect('try2', 'No');
        Observer.Expect('option_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('option_false', 'Kind B');
        Observer.Expect('option_code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ExcludeFlag_NestedTryFunctions()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try', Format(TryOuter('v')));
        Forms('nested', Observer);
        Observer.Expect('try', 'No');
        Observer.Expect('nested_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('nested_false', 'Inner v');
        Observer.Expect('nested_code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ExcludeFlag_GetWithCompositeKeyMissing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try', Format(TryGetCompositeMissing()));
        Forms('get', Observer);
        Observer.Expect('try', 'No');
        Observer.Expect('get_true', 'The LT LET Row does not exist. Identification fields and values: <redacted>');
        Observer.Expect('get_false', 'The LT LET Row does not exist. Identification fields and values: Code=''MISSING'',Sub=''7''');
        Observer.Expect('get_code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure ExcludeFlag_FieldErrorWithLabelAndValue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try1', Format(TryFieldErrorLabel()));
        Forms('fe_label', Observer);
        Observer.Observe('try2', Format(TryFieldErrorValue()));
        Forms('fe_value', Observer);
        Observer.Expect('try1', 'No');
        Observer.Expect('fe_label_true', 'FieldError on field LT LET Row.Name, message: A label without arguments');
        Observer.Expect('fe_label_false', 'Name A label without arguments in LT LET Row Code=''SECRET1'',Sub=''3''.');
        Observer.Expect('fe_label_code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('try2', 'No');
        Observer.Expect('fe_value_true', 'FieldError for incorrect value of LT LET Row.Name');
        Observer.Expect('fe_value_false', 'Name must not be secret name in LT LET Row Code=''SECRET2'',Sub=''0''.');
        Observer.Expect('fe_value_code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure ExcludeFlag_AsserterrorLabelAndStackAfterwards()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error(OneArgLbl, 'direct');
        Forms('direct', Observer);
        Observer.Observe('stack_true_empty', Format(GetLastErrorCallStack() = ''));
        ClearLastError();
        Forms('cleared', Observer);
        Observer.Expect('direct_true', 'A label with %1');
        Observer.Expect('direct_false', 'A label with direct');
        Observer.Expect('direct_code', 'Dialog');
        Observer.Expect('stack_true_empty', 'No');
        Observer.Expect('cleared_true', '');
        Observer.Expect('cleared_false', '');
        Observer.Expect('cleared_code', '');
        Observer.Verify();
    end;

    // ---- error text origin matrix: a Label declared locally, labels with properties, labels from another codeunit, labels passed on as text ----

    [TryFunction]
    local procedure TryLocalLabelNoArgs()
    var
        LocalLbl: Label 'A local label without arguments';
    begin
        Error(LocalLbl);
    end;

    [TryFunction]
    local procedure TryLocalLabelOneArg(Value: Text)
    var
        LocalLbl: Label 'A local label with %1';
    begin
        Error(LocalLbl, Value);
    end;

    [TryFunction]
    local procedure TryLocalLabelTwoArgs(Value: Text; Amount: Decimal)
    var
        LocalLbl: Label 'Local customer %1 owes %2';
    begin
        Error(LocalLbl, Value, Amount);
    end;

    [TryFunction]
    local procedure TryLocalLabelCodeArg(Value: Code[10])
    var
        LocalLbl: Label 'Local code %1';
    begin
        Error(LocalLbl, Value);
    end;

    [TryFunction]
    local procedure TryLocalLabelDateArg(Value: Date)
    var
        LocalLbl: Label 'Local date %1';
    begin
        Error(LocalLbl, Value);
    end;

    [TryFunction]
    local procedure TryLocalLabelIntegerArg(Value: Integer)
    var
        LocalLbl: Label 'Local integer %1';
    begin
        Error(LocalLbl, Value);
    end;

    [TryFunction]
    local procedure TryLocalLabelComment(Value: Text)
    var
        LocalLbl: Label 'Local commented %1', Comment = '%1 = a value';
    begin
        Error(LocalLbl, Value);
    end;

    [TryFunction]
    local procedure TryLocalLabelLocked()
    var
        LocalLbl: Label 'Local locked label', Locked = true;
    begin
        Error(LocalLbl);
    end;

    [TryFunction]
    local procedure TryLocalLabelMaxLength()
    var
        LocalLbl: Label 'Local max length label', MaxLength = 50;
    begin
        Error(LocalLbl);
    end;

    [TryFunction]
    local procedure TryLocalLabelCrLf()
    var
        LocalLbl: Label 'Line one%1Line two';
        CrLf: Text[2];
    begin
        CrLf[1] := 13;
        CrLf[2] := 10;
        Error(LocalLbl, CrLf);
    end;

    [TryFunction]
    local procedure TryLabelAsTextParameter()
    var
        LocalLbl: Label 'A label passed as a text parameter';
    begin
        RaiseText(LocalLbl);
    end;

    [TryFunction]
    local procedure TryLabelAssignedToTextVariable()
    var
        LocalLbl: Label 'A label assigned to a text variable';
        Msg: Text;
    begin
        Msg := LocalLbl;
        Error(Msg);
    end;

    [TryFunction]
    local procedure TryLabelAssignedToTextVariableWithArg(Value: Text)
    var
        LocalLbl: Label 'A label assigned with %1';
        Msg: Text;
    begin
        Msg := LocalLbl;
        Error(Msg, Value);
    end;

    [TryFunction]
    local procedure TryLabelReturnedByProcedure()
    var
        Source: Codeunit "LT LET Origin Source";
    begin
        Error(Source.LabelAsText());
    end;

    [TryFunction]
    local procedure TryLocalLabelErrorInfoMessage(Value: Text)
    var
        LocalLbl: Label 'Local error info message %1';
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := StrSubstNo(LocalLbl, Value);
        Error(ErrInfo);
    end;

    [TryFunction]
    local procedure TryLocalLabelErrorInfoMessageNoArgs()
    var
        LocalLbl: Label 'Local error info message without arguments';
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := LocalLbl;
        Error(ErrInfo);
    end;

    local procedure RaiseText(Msg: Text)
    begin
        Error(Msg);
    end;

    [Test]
    procedure ExcludeFlag_LocalLabelNoArgsOneArgTwoArgs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try0', Format(TryLocalLabelNoArgs()));
        Forms('zero', Observer);
        Observer.Observe('try1', Format(TryLocalLabelOneArg('customer value')));
        Forms('one', Observer);
        Observer.Observe('try2', Format(TryLocalLabelTwoArgs('C10', 12.5)));
        Forms('two', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ExcludeFlag_LocalLabelArgumentTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try_code', Format(TryLocalLabelCodeArg('ABC')));
        Forms('code', Observer);
        Observer.Observe('try_date', Format(TryLocalLabelDateArg(DMY2Date(5, 3, 2027))));
        Forms('date', Observer);
        Observer.Observe('try_int', Format(TryLocalLabelIntegerArg(42)));
        Forms('int', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ExcludeFlag_LocalLabelCommentLockedMaxLengthCrLf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try_comment', Format(TryLocalLabelComment('v')));
        Forms('comment', Observer);
        Observer.Observe('try_locked', Format(TryLocalLabelLocked()));
        Forms('locked', Observer);
        Observer.Observe('try_max', Format(TryLocalLabelMaxLength()));
        Forms('max', Observer);
        Observer.Observe('try_crlf', Format(TryLocalLabelCrLf()));
        Forms('crlf', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ExcludeFlag_LabelHandedOnAsText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try_param', Format(TryLabelAsTextParameter()));
        Forms('param', Observer);
        Observer.Observe('try_var', Format(TryLabelAssignedToTextVariable()));
        Forms('var', Observer);
        Observer.Observe('try_var_arg', Format(TryLabelAssignedToTextVariableWithArg('x')));
        Forms('var_arg', Observer);
        Observer.Observe('try_proc', Format(TryLabelReturnedByProcedure()));
        Forms('proc', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ExcludeFlag_LocalLabelInErrorInfoMessage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try_subst', Format(TryLocalLabelErrorInfoMessage('x')));
        Forms('subst', Observer);
        Observer.Observe('try_plain', Format(TryLocalLabelErrorInfoMessageNoArgs()));
        Forms('plain', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ExcludeFlag_LocalLabelAsserterrorAndCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Runner: Codeunit "LT LET Origin Runner";
        LocalLbl: Label 'Local label under asserterror %1';
    begin
        ClearLastError();
        asserterror Error(LocalLbl, 'direct');
        Forms('asserterror', Observer);
        ClearLastError();
        Observer.Observe('run', Format(Runner.Run()));
        Forms('run', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure ExcludeFlag_GlobalLabelPropertiesFromAnotherCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Source: Codeunit "LT LET Origin Source";
    begin
        ClearLastError();
        Observer.Observe('try_comment', Format(Source.RaiseComment('v')));
        Forms('comment', Observer);
        Observer.Observe('try_locked', Format(Source.RaiseLocked()));
        Forms('locked', Observer);
        Observer.Observe('try_max', Format(Source.RaiseMaxLength()));
        Forms('max', Observer);
        Observer.Observe('try_crlf', Format(Source.RaiseCrLf()));
        Forms('crlf', Observer);
        Observer.Finish();
    end;
}

// local object: the label sources of the origin matrix must live in another codeunit (a label returned by a procedure, global labels with properties)
codeunit 65001 "LT LET Origin Source"
{
    var
        GlobalPlain: Label 'A global label returned as text';
        GlobalComment: Label 'Global commented %1', Comment = '%1 = a value';
        GlobalLocked: Label 'Global locked label', Locked = true;
        GlobalMax: Label 'Global max length label', MaxLength = 50;
        GlobalCrLf: Label 'Global line one%1Global line two';

    procedure LabelAsText(): Text
    begin
        exit(GlobalPlain);
    end;

    [TryFunction]
    procedure RaiseComment(Value: Text)
    begin
        Error(GlobalComment, Value);
    end;

    [TryFunction]
    procedure RaiseLocked()
    begin
        Error(GlobalLocked);
    end;

    [TryFunction]
    procedure RaiseMaxLength()
    begin
        Error(GlobalMax);
    end;

    [TryFunction]
    procedure RaiseCrLf()
    var
        CrLf: Text[2];
    begin
        CrLf[1] := 13;
        CrLf[2] := 10;
        Error(GlobalCrLf, CrLf);
    end;
}

// local object: Codeunit.Run needs a codeunit whose OnRun raises the error from a local label
codeunit 65002 "LT LET Origin Runner"
{
    trigger OnRun()
    var
        LocalLbl: Label 'Local label in OnRun %1';
    begin
        Error(LocalLbl, 'run value');
    end;
}
