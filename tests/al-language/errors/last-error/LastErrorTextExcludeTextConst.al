// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 74851
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: TextConst variables may not compile in the Cloud app (own file so a compile failure drops only this file).
// Facts: GetLastErrorText(true) against GetLastErrorText(false) and GetLastErrorCode for Error(TextConst), Error(TextConst, argument) and a TextConst with two languages.
// BC versions: 29 (27 and 28 by CI)

codeunit 74851 "LT LET TextConst"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        PlainConst: TextConst ENU = 'Text const message';
        ArgConst: TextConst ENU = 'Text const with %1';
        TwoLangConst: TextConst ENU = 'English text const', DEU = 'Deutsche Textkonstante';

    [TryFunction]
    local procedure TryPlainConst()
    begin
        Error(PlainConst);
    end;

    [TryFunction]
    local procedure TryArgConst(Value: Text)
    begin
        Error(ArgConst, Value);
    end;

    [TryFunction]
    local procedure TryTwoLangConst()
    begin
        Error(TwoLangConst);
    end;

    local procedure Forms(Name: Text; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe(Name + '_true', GetLastErrorText(true));
        Observer.Observe(Name + '_false', GetLastErrorText(false));
        Observer.Observe(Name + '_code', GetLastErrorCode());
    end;

    [Test]
    procedure ErrorTextConst_TryFunction_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('try_plain', Format(TryPlainConst()));
        Forms('plain', Observer);
        Observer.Observe('try_arg', Format(TryArgConst('customer value')));
        Forms('arg', Observer);
        Observer.Observe('try_twolang', Format(TryTwoLangConst()));
        Forms('twolang', Observer);
        Observer.Expect('try_plain', 'No');
        Observer.Expect('plain_true', 'Text const message');
        Observer.Expect('plain_false', 'Text const message');
        Observer.Expect('plain_code', 'Dialog');
        Observer.Expect('try_arg', 'No');
        Observer.Expect('arg_true', 'Text const with %1');
        Observer.Expect('arg_false', 'Text const with customer value');
        Observer.Expect('arg_code', 'Dialog');
        Observer.Expect('try_twolang', 'No');
        Observer.Expect('twolang_true', 'English text const');
        Observer.Expect('twolang_false', 'English text const');
        Observer.Expect('twolang_code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ErrorTextConst_Asserterror_ExcludeFlag()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        asserterror Error(PlainConst);
        Forms('direct', Observer);
        asserterror Error(ArgConst, 'direct value');
        Forms('direct_arg', Observer);
        Observer.Expect('direct_true', 'Text const message');
        Observer.Expect('direct_false', 'Text const message');
        Observer.Expect('direct_code', 'Dialog');
        Observer.Expect('direct_arg_true', 'Text const with %1');
        Observer.Expect('direct_arg_false', 'Text const with direct value');
        Observer.Expect('direct_arg_code', 'Dialog');
        Observer.Verify();
    end;
}
