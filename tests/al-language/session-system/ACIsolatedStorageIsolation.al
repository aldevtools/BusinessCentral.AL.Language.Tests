// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-get-string-datascope-text-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the four IsolatedStorage.Get overloads that take an IsolationLevel (BC 29 and later; BC 27 and 28 reject them, see must-not-compile case 0963): with and without DataScope, Text and SecretText, every IsolationLevel, a missing key, a key stored in another scope. Settles #627 items 1 to 4.
// BC versions: 29

#if BC29PLUS
codeunit 77520 "LT AC IsoStorage IsoLevel"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_IsoGet_DataScope_Text()
    var
        Observer: Codeunit "Probe Observer";
        Value: Text;
        Found: Boolean;
    begin
        Clean();
        IsolatedStorage.Set('ac_key', 'module value', DataScope::Module);
        IsolatedStorage.Set('ac_key', 'company value', DataScope::Company);
        IsolatedStorage.Set('ac_key', 'user value', DataScope::User);
        IsolatedStorage.Set('ac_key', 'both value', DataScope::CompanyAndUser);

        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', DataScope::Module, IsolationLevel::Default, Value);
        Observer.Observe('module_default', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', DataScope::Module, IsolationLevel::ReadUncommitted, Value);
        Observer.Observe('module_readuncommitted', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', DataScope::Module, IsolationLevel::ReadCommitted, Value);
        Observer.Observe('module_readcommitted', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', DataScope::Module, IsolationLevel::RepeatableRead, Value);
        Observer.Observe('module_repeatableread', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', DataScope::Module, IsolationLevel::UpdLock, Value);
        Observer.Observe('module_updlock', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', DataScope::Company, IsolationLevel::ReadCommitted, Value);
        Observer.Observe('company', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', DataScope::User, IsolationLevel::ReadCommitted, Value);
        Observer.Observe('user', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', DataScope::CompanyAndUser, IsolationLevel::ReadCommitted, Value);
        Observer.Observe('company_and_user', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_missing', DataScope::Module, IsolationLevel::ReadCommitted, Value);
        Observer.Observe('missing', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('', DataScope::Module, IsolationLevel::ReadCommitted, Value);
        if not Found then
            Observer.Observe('empty_key', Format(Found) + '/' + Value)
        else
            Observer.Observe('empty_key', Format(Found) + '/' + Value);
        IsolatedStorage.Delete('ac_key', DataScope::Company);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', DataScope::Company, IsolationLevel::ReadCommitted, Value);
        Observer.Observe('company_after_delete', Format(Found) + '/' + Value);
        Clean();
        Observer.Expect('module_default', 'Yes/module value');
        Observer.Expect('module_readuncommitted', 'Yes/module value');
        Observer.Expect('module_readcommitted', 'Yes/module value');
        Observer.Expect('module_repeatableread', 'Yes/module value');
        Observer.Expect('module_updlock', 'Yes/module value');
        Observer.Expect('company', 'Yes/company value');
        Observer.Expect('user', 'Yes/user value');
        Observer.Expect('company_and_user', 'Yes/both value');
        Observer.Expect('missing', 'No/');
        Observer.Expect('empty_key', 'No/');
        Observer.Expect('company_after_delete', 'No/');
        Observer.Verify();
    end;

    [Test]
    procedure AC_IsoGet_DataScope_SecretText()
    var
        Observer: Codeunit "Probe Observer";
        Secret: SecretText;
        Found: Boolean;
    begin
        Clean();
        IsolatedStorage.Set('ac_key', 'module value', DataScope::Module);

        Found := IsolatedStorage.Get('ac_key', DataScope::Module, IsolationLevel::Default, Secret);
        Observer.Observe('module_default', Format(Found) + '/empty=' + Format(Secret.IsEmpty()));
        Clear(Secret);
        Found := IsolatedStorage.Get('ac_key', DataScope::Module, IsolationLevel::ReadCommitted, Secret);
        Observer.Observe('module_readcommitted', Format(Found) + '/empty=' + Format(Secret.IsEmpty()));
        Clear(Secret);
        Found := IsolatedStorage.Get('ac_key', DataScope::Module, IsolationLevel::UpdLock, Secret);
        Observer.Observe('module_updlock', Format(Found) + '/empty=' + Format(Secret.IsEmpty()));
        Clear(Secret);
        Found := IsolatedStorage.Get('ac_key', DataScope::Company, IsolationLevel::ReadCommitted, Secret);
        Observer.Observe('other_scope', Format(Found) + '/empty=' + Format(Secret.IsEmpty()));
        Clear(Secret);
        Found := IsolatedStorage.Get('ac_missing', DataScope::Module, IsolationLevel::ReadCommitted, Secret);
        Observer.Observe('missing', Format(Found) + '/empty=' + Format(Secret.IsEmpty()));
        Clean();
        Observer.Expect('module_default', 'Yes/empty=No');
        Observer.Expect('module_readcommitted', 'Yes/empty=No');
        Observer.Expect('module_updlock', 'Yes/empty=No');
        Observer.Expect('other_scope', 'No/empty=Yes');
        Observer.Expect('missing', 'No/empty=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AC_IsoGet_NoDataScope_Text()
    var
        Observer: Codeunit "Probe Observer";
        Value: Text;
        Found: Boolean;
    begin
        Clean();
        IsolatedStorage.Set('ac_key', 'module value', DataScope::Module);
        IsolatedStorage.Set('ac_key', 'company value', DataScope::Company);
        IsolatedStorage.Set('ac_user_only', 'user only', DataScope::User);

        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', IsolationLevel::Default, Value);
        Observer.Observe('default', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', IsolationLevel::ReadUncommitted, Value);
        Observer.Observe('readuncommitted', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', IsolationLevel::ReadCommitted, Value);
        Observer.Observe('readcommitted', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', IsolationLevel::RepeatableRead, Value);
        Observer.Observe('repeatableread', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_key', IsolationLevel::UpdLock, Value);
        Observer.Observe('updlock', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_user_only', IsolationLevel::ReadCommitted, Value);
        Observer.Observe('stored_in_user_scope', Format(Found) + '/' + Value);
        Value := 'untouched';
        Found := IsolatedStorage.Get('ac_missing', IsolationLevel::ReadCommitted, Value);
        Observer.Observe('missing', Format(Found) + '/' + Value);
        Clean();
        Observer.Expect('default', 'Yes/module value');
        Observer.Expect('readuncommitted', 'Yes/module value');
        Observer.Expect('readcommitted', 'Yes/module value');
        Observer.Expect('repeatableread', 'Yes/module value');
        Observer.Expect('updlock', 'Yes/module value');
        Observer.Expect('stored_in_user_scope', 'No/');
        Observer.Expect('missing', 'No/');
        Observer.Verify();
    end;

    [Test]
    procedure AC_IsoGet_NoDataScope_SecretText()
    var
        Observer: Codeunit "Probe Observer";
        Secret: SecretText;
        Found: Boolean;
    begin
        Clean();
        IsolatedStorage.Set('ac_key', 'module value', DataScope::Module);
        IsolatedStorage.Set('ac_user_only', 'user only', DataScope::User);

        Found := IsolatedStorage.Get('ac_key', IsolationLevel::Default, Secret);
        Observer.Observe('default', Format(Found) + '/empty=' + Format(Secret.IsEmpty()));
        Clear(Secret);
        Found := IsolatedStorage.Get('ac_key', IsolationLevel::ReadCommitted, Secret);
        Observer.Observe('readcommitted', Format(Found) + '/empty=' + Format(Secret.IsEmpty()));
        Clear(Secret);
        Found := IsolatedStorage.Get('ac_key', IsolationLevel::UpdLock, Secret);
        Observer.Observe('updlock', Format(Found) + '/empty=' + Format(Secret.IsEmpty()));
        Clear(Secret);
        Found := IsolatedStorage.Get('ac_user_only', IsolationLevel::ReadCommitted, Secret);
        Observer.Observe('stored_in_user_scope', Format(Found) + '/empty=' + Format(Secret.IsEmpty()));
        Clear(Secret);
        Found := IsolatedStorage.Get('ac_missing', IsolationLevel::ReadCommitted, Secret);
        Observer.Observe('missing', Format(Found) + '/empty=' + Format(Secret.IsEmpty()));
        Clean();
        Observer.Expect('default', 'Yes/empty=No');
        Observer.Expect('readcommitted', 'Yes/empty=No');
        Observer.Expect('updlock', 'Yes/empty=No');
        Observer.Expect('stored_in_user_scope', 'No/empty=Yes');
        Observer.Expect('missing', 'No/empty=Yes');
        Observer.Verify();
    end;

    local procedure Clean()
    begin
        if IsolatedStorage.Contains('ac_key', DataScope::Module) then IsolatedStorage.Delete('ac_key', DataScope::Module);
        if IsolatedStorage.Contains('ac_key', DataScope::Company) then IsolatedStorage.Delete('ac_key', DataScope::Company);
        if IsolatedStorage.Contains('ac_key', DataScope::User) then IsolatedStorage.Delete('ac_key', DataScope::User);
        if IsolatedStorage.Contains('ac_key', DataScope::CompanyAndUser) then IsolatedStorage.Delete('ac_key', DataScope::CompanyAndUser);
        if IsolatedStorage.Contains('ac_enc', DataScope::Module) then IsolatedStorage.Delete('ac_enc', DataScope::Module);
        if IsolatedStorage.Contains('ac_user_only', DataScope::User) then IsolatedStorage.Delete('ac_user_only', DataScope::User);
    end;
}
#endif
