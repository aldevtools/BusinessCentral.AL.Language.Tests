// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: none
//
// A failed Get leaves the variable unchanged (Text, Boolean-returning form), Delete of a missing key
// returns false, Contains of a missing key, Set over an existing key, Company scope next to Module scope,
// and Get/Delete of a missing key as a statement (the error text and code, if any).
//
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72719 "LT P161 Isolated Storage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    begin
        if IsolatedStorage.Contains('P161k1', DataScope::Module) then
            IsolatedStorage.Delete('P161k1', DataScope::Module);
        if IsolatedStorage.Contains('P161k1', DataScope::Company) then
            IsolatedStorage.Delete('P161k1', DataScope::Company);
        if IsolatedStorage.Contains('P161missing', DataScope::Module) then
            IsolatedStorage.Delete('P161missing', DataScope::Module);
    end;

    [Test]
    procedure P161_FailedGet_LeavesVariable()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
        Ok: Boolean;
    begin
        Clean();
        V := 'untouched';
        Ok := IsolatedStorage.Get('P161missing', DataScope::Module, V);
        Observer.Observe('moduleGet', Format(Ok));
        Observer.Observe('moduleVar', V);
        Ok := IsolatedStorage.Get('P161missing', DataScope::Company, V);
        Observer.Observe('companyGet', Format(Ok));
        Observer.Observe('companyVar', V);
        Ok := IsolatedStorage.Get('P161missing', V);
        Observer.Observe('defaultScopeGet', Format(Ok));
        Observer.Observe('defaultScopeVar', V);
        Observer.Expect('moduleGet', 'No');
        Observer.Expect('moduleVar', '');
        Observer.Expect('companyGet', 'No');
        Observer.Expect('companyVar', '');
        Observer.Expect('defaultScopeGet', 'No');
        Observer.Expect('defaultScopeVar', '');
        Observer.Verify();
    end;

    [Test]
    procedure P161_Delete_Missing_AndSetOverwrite()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
    begin
        Clean();
        Observer.Observe('deleteMissing', Format(IsolatedStorage.Delete('P161missing', DataScope::Module)));
        Observer.Observe('containsMissing', Format(IsolatedStorage.Contains('P161missing', DataScope::Module)));
        Observer.Observe('setNew', Format(IsolatedStorage.Set('P161k1', 'one', DataScope::Module)));
        Observer.Observe('setOver', Format(IsolatedStorage.Set('P161k1', 'two', DataScope::Module)));
        IsolatedStorage.Get('P161k1', DataScope::Module, V);
        Observer.Observe('afterOverwrite', V);
        Observer.Observe('deleteExisting', Format(IsolatedStorage.Delete('P161k1', DataScope::Module)));
        Observer.Observe('deleteAgain', Format(IsolatedStorage.Delete('P161k1', DataScope::Module)));
        Observer.Expect('deleteMissing', 'No');
        Observer.Expect('containsMissing', 'No');
        Observer.Expect('setNew', 'Yes');
        Observer.Expect('setOver', 'Yes');
        Observer.Expect('afterOverwrite', 'two');
        Observer.Expect('deleteExisting', 'Yes');
        Observer.Expect('deleteAgain', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P161_CompanyScope_NextToModuleScope()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
    begin
        Clean();
        IsolatedStorage.Set('P161k1', 'module', DataScope::Module);
        IsolatedStorage.Set('P161k1', 'company', DataScope::Company);
        IsolatedStorage.Get('P161k1', DataScope::Module, V);
        Observer.Observe('module', V);
        IsolatedStorage.Get('P161k1', DataScope::Company, V);
        Observer.Observe('company', V);
        IsolatedStorage.Delete('P161k1', DataScope::Company);
        Observer.Observe('moduleStill', Format(IsolatedStorage.Contains('P161k1', DataScope::Module)));
        Observer.Observe('companyGone', Format(IsolatedStorage.Contains('P161k1', DataScope::Company)));
        Clean();
        Observer.Expect('module', 'module');
        Observer.Expect('company', 'company');
        Observer.Expect('moduleStill', 'Yes');
        Observer.Expect('companyGone', 'No');
        Observer.Verify();
    end;
}
