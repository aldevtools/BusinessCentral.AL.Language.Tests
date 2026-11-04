// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-setencrypted-method
// Scope: in-scope
// Fixtures used: Probe Observer; own keys FRTF_k*, deleted in each test
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: IsolatedStorage.SetEncrypted(Key, Value: SecretText, DataScope) with a SecretText built by SecretStrSubstNo (the way a Cloud app builds one), read back with Get into a SecretText; Contains and IsEmpty of the result. Own file: compile-risky (SecretText overloads).
// BC versions: 29 (27 and 28 by CI)

codeunit 71728 "LT ISO SecretText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SetEncrypted_SecretText_GetIntoSecretText()
    var
        Observer: Codeunit "Probe Observer";
        Secret: SecretText;
        Back: SecretText;
        Res: Boolean;
    begin
        asserterror IsolatedStorage.Delete('FRTF_k1', DataScope::Module);
        Observer.ObserveError('af21');
        Secret := SecretStrSubstNo('abc-secret');
        Res := IsolatedStorage.SetEncrypted('FRTF_k1', Secret, DataScope::Module);
        Observer.Observe('set_result', Format(Res));
        Observer.Observe('contains', Format(IsolatedStorage.Contains('FRTF_k1', DataScope::Module)));
        Res := IsolatedStorage.Get('FRTF_k1', DataScope::Module, Back);
        Observer.Observe('get_result', Format(Res));
        Observer.Observe('back_is_empty', Format(Back.IsEmpty()));
        IsolatedStorage.Delete('FRTF_k1', DataScope::Module);
        Observer.Expect('af21|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''FRTF_k1''');
        Observer.Expect('af21|code', 'DB:RecordNotFound');
        Observer.Expect('set_result', 'Yes');
        Observer.Expect('contains', 'Yes');
        Observer.Expect('get_result', 'Yes');
        Observer.Expect('back_is_empty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetEncrypted_EmptySecretText_AndOverwrite()
    var
        Observer: Codeunit "Probe Observer";
        Empty: SecretText;
        Secret: SecretText;
        Back: SecretText;
        Res: Boolean;
    begin
        asserterror IsolatedStorage.Delete('FRTF_k2', DataScope::Module);
        Observer.ObserveError('af43');
        Res := IsolatedStorage.SetEncrypted('FRTF_k2', Empty, DataScope::Module);
        Observer.Observe('set_empty_result', Format(Res));
        Observer.Observe('contains_after_empty', Format(IsolatedStorage.Contains('FRTF_k2', DataScope::Module)));
        Secret := SecretStrSubstNo('second');
        Res := IsolatedStorage.SetEncrypted('FRTF_k2', Secret, DataScope::Module);
        Observer.Observe('set_overwrite_result', Format(Res));
        Res := IsolatedStorage.Get('FRTF_k2', DataScope::Module, Back);
        Observer.Observe('get_result', Format(Res));
        Observer.Observe('back_is_empty', Format(Back.IsEmpty()));
        IsolatedStorage.Delete('FRTF_k2', DataScope::Module);
        Observer.Expect('af43|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''FRTF_k2''');
        Observer.Expect('af43|code', 'DB:RecordNotFound');
        Observer.Expect('set_empty_result', 'Yes');
        Observer.Expect('contains_after_empty', 'Yes');
        Observer.Expect('set_overwrite_result', 'Yes');
        Observer.Expect('get_result', 'Yes');
        Observer.Expect('back_is_empty', 'No');
        Observer.Verify();
    end;
}
