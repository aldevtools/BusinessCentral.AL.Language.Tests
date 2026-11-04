// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 74850
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorText(true) (ExcludeCustomerContent) against GetLastErrorText(false) and GetLastErrorCode for Error(TextVariable), Error(TextVariable with a %1 and no argument), Error(TextVariable, argument), Error(CodeVariable); raised in a TryFunction and directly under asserterror. Error(Label) forms are pinned in error-handling/lt-last-error-text-exclude/LastErrorTextExcludeLabel.al.
// BC versions: 29 (27 and 28 by CI)

codeunit 74850 "LT LET TextVar"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryTextVar()
    var
        Msg: Text;
    begin
        Msg := 'Text variable message';
        Error(Msg);
    end;

    [TryFunction]
    local procedure TryTextVarPercentNoArg()
    var
        Msg: Text;
    begin
        Msg := 'Percent %1 stays';
        Error(Msg);
    end;

    [TryFunction]
    local procedure TryTextVarWithArg(Value: Text)
    var
        Msg: Text;
    begin
        Msg := 'Text variable %1';
        Error(Msg, Value);
    end;

    [TryFunction]
    local procedure TryCodeVar()
    var
        CodeVal: Code[20];
    begin
        CodeVal := 'CODE1';
        Error(CodeVal);
    end;

    [TryFunction]
    local procedure TryTextVarEmpty()
    var
        Msg: Text;
    begin
        Error(Msg);
    end;

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_true', GetLastErrorText(true));
        Observer.Observe(Name + '_false', GetLastErrorText(false));
        Observer.Observe(Name + '_code', GetLastErrorCode());
    end;

    [Test]
    procedure ErrorTextVariable_TryFunction_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try_plain', Format(TryTextVar()));
        Forms('plain', Observer);
        Observer.Observe('try_percent', Format(TryTextVarPercentNoArg()));
        Forms('percent', Observer);
        Observer.Observe('try_arg', Format(TryTextVarWithArg('customer value')));
        Forms('arg', Observer);
        Observer.Observe('try_code', Format(TryCodeVar()));
        Forms('codevar', Observer);
        Observer.Expect('try_plain', 'No');
        Observer.Expect('plain_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('plain_false', 'Text variable message');
        Observer.Expect('plain_code', 'Dialog');
        Observer.Expect('try_percent', 'No');
        Observer.Expect('percent_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('percent_false', 'Percent %1 stays');
        Observer.Expect('percent_code', 'Dialog');
        Observer.Expect('try_arg', 'No');
        Observer.Expect('arg_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('arg_false', 'Text variable customer value');
        Observer.Expect('arg_code', 'Dialog');
        Observer.Expect('try_code', 'No');
        Observer.Expect('codevar_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('codevar_false', 'CODE1');
        Observer.Expect('codevar_code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorTextVariableEmpty_TryFunction_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try_empty', Format(TryTextVarEmpty()));
        Forms('empty', Observer);
        Observer.Expect('try_empty', 'No');
        Observer.Expect('empty_true', '');
        Observer.Expect('empty_false', '');
        Observer.Expect('empty_code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorTextVariable_Asserterror_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
        Msg: Text;
        CodeVal: Code[20];
    begin
        ClearLastError();
        Msg := 'Direct text variable message';
        asserterror Error(Msg);
        Forms('direct', Observer);
        Msg := 'Direct %1 and %2';
        asserterror Error(Msg, 'first', 42);
        Forms('direct_args', Observer);
        CodeVal := 'DIRECT';
        asserterror Error(CodeVal);
        Forms('direct_code', Observer);
        asserterror Error(Msg + ' concatenated');
        Forms('concat', Observer);
        Observer.Expect('direct_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('direct_false', 'Direct text variable message');
        Observer.Expect('direct_code', 'Dialog');
        Observer.Expect('direct_args_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('direct_args_false', 'Direct first and 42');
        Observer.Expect('direct_args_code', 'Dialog');
        Observer.Expect('direct_code_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('direct_code_false', 'DIRECT');
        Observer.Expect('direct_code_code', 'Dialog');
        Observer.Expect('concat_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('concat_false', 'Direct %1 and %2 concatenated');
        Observer.Expect('concat_code', 'Dialog');
        Observer.Verify();
    end;
}
