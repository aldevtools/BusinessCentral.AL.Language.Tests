// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (own file): passes a Guid variable where the Key parameter is a Text. If the compiler rejects it, this file is a must-not-compile case
// and the file is dropped. If it compiles: Set/Get/Contains/Delete with the Guid-typed key against the Format(Guid) key, in every DataScope.
// BC versions: 29 (27 and 28 by CI)

codeunit 71573 "LT P175 Iso Guid Key"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean(G: Guid)
    var
        K: Text;
    begin
        K := Format(G);
        if IsolatedStorage.Contains(K, DataScope::Module) then
            IsolatedStorage.Delete(K, DataScope::Module);
        if IsolatedStorage.Contains(K, DataScope::Company) then
            IsolatedStorage.Delete(K, DataScope::Company);
        if IsolatedStorage.Contains(K, DataScope::User) then
            IsolatedStorage.Delete(K, DataScope::User);
        if IsolatedStorage.Contains(K, DataScope::CompanyAndUser) then
            IsolatedStorage.Delete(K, DataScope::CompanyAndUser);
    end;

    local procedure TheGuid(var G: Guid)
    begin
        Evaluate(G, '{6F2C3D4E-5B6C-4D7E-9F80-AB1C2D3E4F50}');
    end;

    [Test]
    procedure P175_GuidKey_SetGuidGetText()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        V: Text;
    begin
        TheGuid(G);
        Clean(G);
        Observer.Observe('set', Format(IsolatedStorage.Set(G, 'viaGuid')));
        Observer.Observe('containsGuid', Format(IsolatedStorage.Contains(G)));
        Observer.Observe('containsText', Format(IsolatedStorage.Contains(Format(G))));
        V := '';
        Observer.Observe('getText', Format(IsolatedStorage.Get(Format(G), V)) + '|' + V);
        V := '';
        Observer.Observe('getGuid', Format(IsolatedStorage.Get(G, V)) + '|' + V);
        Observer.Observe('deleteText', Format(IsolatedStorage.Delete(Format(G))));
        Observer.Observe('containsGuidAfter', Format(IsolatedStorage.Contains(G)));
        Clean(G);
        Observer.Expect('set', 'Yes');
        Observer.Expect('containsGuid', 'Yes');
        Observer.Expect('containsText', 'Yes');
        Observer.Expect('getText', 'Yes|viaGuid');
        Observer.Expect('getGuid', 'Yes|viaGuid');
        Observer.Expect('deleteText', 'Yes');
        Observer.Expect('containsGuidAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidKey_SetTextGetGuid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        V: Text;
    begin
        TheGuid(G);
        Clean(G);
        IsolatedStorage.Set(Format(G), 'viaText');
        Observer.Observe('containsGuid', Format(IsolatedStorage.Contains(G)));
        V := '';
        Observer.Observe('getGuid', Format(IsolatedStorage.Get(G, V)) + '|' + V);
        Observer.Observe('deleteGuid', Format(IsolatedStorage.Delete(G)));
        Observer.Observe('containsTextAfter', Format(IsolatedStorage.Contains(Format(G))));
        Clean(G);
        Observer.Expect('containsGuid', 'Yes');
        Observer.Expect('getGuid', 'Yes|viaText');
        Observer.Expect('deleteGuid', 'Yes');
        Observer.Expect('containsTextAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidKey_ModuleScope()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        V: Text;
    begin
        TheGuid(G);
        Clean(G);
        Observer.Observe('set', Format(IsolatedStorage.Set(G, 'm', DataScope::Module)));
        Observer.Observe('contains', Format(IsolatedStorage.Contains(G, DataScope::Module)));
        Observer.Observe('containsCompany', Format(IsolatedStorage.Contains(G, DataScope::Company)));
        V := '';
        Observer.Observe('get', Format(IsolatedStorage.Get(G, DataScope::Module, V)) + '|' + V);
        Observer.Observe('delete', Format(IsolatedStorage.Delete(G, DataScope::Module)));
        Clean(G);
        Observer.Expect('set', 'Yes');
        Observer.Expect('contains', 'Yes');
        Observer.Expect('containsCompany', 'No');
        Observer.Expect('get', 'Yes|m');
        Observer.Expect('delete', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidKey_CompanyScope()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        V: Text;
    begin
        TheGuid(G);
        Clean(G);
        Observer.Observe('set', Format(IsolatedStorage.Set(G, 'c', DataScope::Company)));
        Observer.Observe('contains', Format(IsolatedStorage.Contains(G, DataScope::Company)));
        Observer.Observe('containsModule', Format(IsolatedStorage.Contains(G, DataScope::Module)));
        V := '';
        Observer.Observe('get', Format(IsolatedStorage.Get(G, DataScope::Company, V)) + '|' + V);
        Observer.Observe('delete', Format(IsolatedStorage.Delete(G, DataScope::Company)));
        Clean(G);
        Observer.Expect('set', 'Yes');
        Observer.Expect('contains', 'Yes');
        Observer.Expect('containsModule', 'No');
        Observer.Expect('get', 'Yes|c');
        Observer.Expect('delete', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidKey_UserAndCompanyAndUserScope()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        V: Text;
    begin
        TheGuid(G);
        Clean(G);
        Observer.Observe('setUser', Format(IsolatedStorage.Set(G, 'u', DataScope::User)));
        Observer.Observe('setCau', Format(IsolatedStorage.Set(G, 'cu', DataScope::CompanyAndUser)));
        V := '';
        Observer.Observe('getUser', Format(IsolatedStorage.Get(G, DataScope::User, V)) + '|' + V);
        V := '';
        Observer.Observe('getCau', Format(IsolatedStorage.Get(G, DataScope::CompanyAndUser, V)) + '|' + V);
        Observer.Observe('deleteUser', Format(IsolatedStorage.Delete(G, DataScope::User)));
        Observer.Observe('containsCau', Format(IsolatedStorage.Contains(G, DataScope::CompanyAndUser)));
        Observer.Observe('deleteCau', Format(IsolatedStorage.Delete(G, DataScope::CompanyAndUser)));
        Clean(G);
        Observer.Expect('setUser', 'Yes');
        Observer.Expect('setCau', 'Yes');
        Observer.Expect('getUser', 'Yes|u');
        Observer.Expect('getCau', 'Yes|cu');
        Observer.Expect('deleteUser', 'Yes');
        Observer.Expect('containsCau', 'Yes');
        Observer.Expect('deleteCau', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidKey_EmptyGuid()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        V: Text;
    begin
        Clear(G);
        Clean(G);
        Observer.Observe('contains', Format(IsolatedStorage.Contains(G)));
        V := 'x';
        Observer.Observe('get', Format(IsolatedStorage.Get(G, V)) + '|' + V);
        Observer.Observe('delete', Format(IsolatedStorage.Delete(G)));
        Observer.Expect('contains', 'No');
        Observer.Expect('get', 'No|');
        Observer.Expect('delete', 'No');
        Observer.Verify();
    end;
}
