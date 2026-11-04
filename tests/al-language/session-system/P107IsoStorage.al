// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: none, Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: IsolatedStorage.Contains(Key, DataScope, var isSecret) and SetEncrypted(Key, SecretText, DataScope); own keys P107k*, deleted in each test
// BC versions: 29 (27 and 28 by CI)

codeunit 72703 "LT P107 IsoStorage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P107_ContainsIsSecret()
    var
        Observer: Codeunit "Probe Observer";
        Secret: Boolean;
        Found: Boolean;
    begin
        asserterror IsolatedStorage.Delete('P107kA');
        Observer.ObserveError('af20');
        asserterror IsolatedStorage.Delete('P107kB');
        Observer.ObserveError('af22');
        Secret := true;
        Found := IsolatedStorage.Contains('P107kA', DataScope::Module, Secret);
        Observer.Observe('absent_found', Format(Found));
        Observer.Observe('absent_secret', Format(Secret));
        IsolatedStorage.Set('P107kA', 'plain', DataScope::Module);
        Found := IsolatedStorage.Contains('P107kA', DataScope::Module, Secret);
        Observer.Observe('plain_found', Format(Found));
        Observer.Observe('plain_secret', Format(Secret));
        IsolatedStorage.SetEncrypted('P107kB', 'enc', DataScope::Module);
        Found := IsolatedStorage.Contains('P107kB', DataScope::Module, Secret);
        Observer.Observe('enc_found', Format(Found));
        Observer.Observe('enc_secret', Format(Secret));
        Found := IsolatedStorage.Contains('P107kB', DataScope::User, Secret);
        Observer.Observe('enc_other_scope_found', Format(Found));
        Observer.Observe('enc_other_scope_secret', Format(Secret));
        IsolatedStorage.Delete('P107kA', DataScope::Module);
        IsolatedStorage.Delete('P107kB', DataScope::Module);
        Observer.Expect('af20|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''P107kA''');
        Observer.Expect('af20|code', 'DB:RecordNotFound');
        Observer.Expect('af22|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''P107kB''');
        Observer.Expect('af22|code', 'DB:RecordNotFound');
        Observer.Expect('absent_found', 'No');
        Observer.Expect('absent_secret', 'No');
        Observer.Expect('plain_found', 'Yes');
        Observer.Expect('plain_secret', 'No');
        Observer.Expect('enc_found', 'Yes');
        Observer.Expect('enc_secret', 'No');
        Observer.Expect('enc_other_scope_found', 'No');
        Observer.Expect('enc_other_scope_secret', 'No');
        Observer.Verify();
    end;
}
