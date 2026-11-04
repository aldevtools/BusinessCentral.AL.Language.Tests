// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: IsolatedStorage with a key that is Format(Guid) (a Text of 38 characters with braces): Set, Contains, Get and Delete in every DataScope
// (Module, Company, User, CompanyAndUser), the same key in different scopes, the key spelling with and without braces and in lower case.
// The keys are the test's own and are deleted at the end of each test. The Guid-typed key form is in P175IsoStorageGuidKey.al.
// BC versions: 29 (27 and 28 by CI)

codeunit 71572 "LT P175 Iso Guid Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure KeyText(): Text
    var
        G: Guid;
    begin
        Evaluate(G, '{5E1B2C3D-4A5B-4C6D-8E7F-9A0B1C2D3E4F}');
        exit(Format(G));
    end;

    local procedure Clean(KeyValue: Text)
    begin
        if IsolatedStorage.Contains(KeyValue, DataScope::Module) then
            IsolatedStorage.Delete(KeyValue, DataScope::Module);
        if IsolatedStorage.Contains(KeyValue, DataScope::Company) then
            IsolatedStorage.Delete(KeyValue, DataScope::Company);
        if IsolatedStorage.Contains(KeyValue, DataScope::User) then
            IsolatedStorage.Delete(KeyValue, DataScope::User);
        if IsolatedStorage.Contains(KeyValue, DataScope::CompanyAndUser) then
            IsolatedStorage.Delete(KeyValue, DataScope::CompanyAndUser);
    end;

    local procedure Cnt(KeyValue: Text): Text
    begin
        exit(Format(IsolatedStorage.Contains(KeyValue, DataScope::Module)) + '/' +
             Format(IsolatedStorage.Contains(KeyValue, DataScope::Company)) + '/' +
             Format(IsolatedStorage.Contains(KeyValue, DataScope::User)) + '/' +
             Format(IsolatedStorage.Contains(KeyValue, DataScope::CompanyAndUser)));
    end;

    [Test]
    procedure P175_GuidText_KeyShape()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('len', Format(StrLen(KeyText())));
        Observer.Observe('hasBrace', Format(CopyStr(KeyText(), 1, 1) = '{'));
        Observer.Expect('len', '38');
        Observer.Expect('hasBrace', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidText_DefaultScopeRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
        V: Text;
        Ok: Boolean;
    begin
        K := KeyText();
        Clean(K);
        Observer.Observe('setDefault', Format(IsolatedStorage.Set(K, 'v1')));
        Observer.Observe('contains', Format(IsolatedStorage.Contains(K)));
        Observer.Observe('scopes', Cnt(K));
        V := 'x';
        Ok := IsolatedStorage.Get(K, V);
        Observer.Observe('get', Format(Ok) + '|' + V);
        Observer.Observe('getModule', Format(IsolatedStorage.Get(K, DataScope::Module, V)) + '|' + V);
        Observer.Observe('delete', Format(IsolatedStorage.Delete(K)));
        Observer.Observe('containsAfter', Format(IsolatedStorage.Contains(K)));
        Observer.Observe('deleteAgain', Format(IsolatedStorage.Delete(K)));
        Clean(K);
        Observer.Expect('setDefault', 'Yes');
        Observer.Expect('contains', 'Yes');
        Observer.Expect('scopes', 'Yes/No/No/No');
        Observer.Expect('get', 'Yes|v1');
        Observer.Expect('getModule', 'Yes|v1');
        Observer.Expect('delete', 'Yes');
        Observer.Expect('containsAfter', 'No');
        Observer.Expect('deleteAgain', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidText_ModuleScope()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
        V: Text;
    begin
        K := KeyText();
        Clean(K);
        Observer.Observe('set', Format(IsolatedStorage.Set(K, 'module', DataScope::Module)));
        Observer.Observe('scopes', Cnt(K));
        V := '';
        Observer.Observe('get', Format(IsolatedStorage.Get(K, DataScope::Module, V)) + '|' + V);
        V := '';
        Observer.Observe('getCompany', Format(IsolatedStorage.Get(K, DataScope::Company, V)) + '|' + V);
        Observer.Observe('deleteCompany', Format(IsolatedStorage.Delete(K, DataScope::Company)));
        Observer.Observe('delete', Format(IsolatedStorage.Delete(K, DataScope::Module)));
        Observer.Observe('scopesAfter', Cnt(K));
        Clean(K);
        Observer.Expect('set', 'Yes');
        Observer.Expect('scopes', 'Yes/No/No/No');
        Observer.Expect('get', 'Yes|module');
        Observer.Expect('getCompany', 'No|');
        Observer.Expect('deleteCompany', 'No');
        Observer.Expect('delete', 'Yes');
        Observer.Expect('scopesAfter', 'No/No/No/No');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidText_CompanyScope()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
        V: Text;
    begin
        K := KeyText();
        Clean(K);
        Observer.Observe('set', Format(IsolatedStorage.Set(K, 'company', DataScope::Company)));
        Observer.Observe('scopes', Cnt(K));
        V := '';
        Observer.Observe('get', Format(IsolatedStorage.Get(K, DataScope::Company, V)) + '|' + V);
        V := '';
        Observer.Observe('getModule', Format(IsolatedStorage.Get(K, DataScope::Module, V)) + '|' + V);
        Observer.Observe('delete', Format(IsolatedStorage.Delete(K, DataScope::Company)));
        Observer.Observe('scopesAfter', Cnt(K));
        Clean(K);
        Observer.Expect('set', 'Yes');
        Observer.Expect('scopes', 'No/Yes/No/No');
        Observer.Expect('get', 'Yes|company');
        Observer.Expect('getModule', 'No|');
        Observer.Expect('delete', 'Yes');
        Observer.Expect('scopesAfter', 'No/No/No/No');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidText_UserScope()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
        V: Text;
    begin
        K := KeyText();
        Clean(K);
        Observer.Observe('set', Format(IsolatedStorage.Set(K, 'user', DataScope::User)));
        Observer.Observe('scopes', Cnt(K));
        V := '';
        Observer.Observe('get', Format(IsolatedStorage.Get(K, DataScope::User, V)) + '|' + V);
        V := '';
        Observer.Observe('getCompanyAndUser', Format(IsolatedStorage.Get(K, DataScope::CompanyAndUser, V)) + '|' + V);
        Observer.Observe('delete', Format(IsolatedStorage.Delete(K, DataScope::User)));
        Observer.Observe('scopesAfter', Cnt(K));
        Clean(K);
        Observer.Expect('set', 'Yes');
        Observer.Expect('scopes', 'No/No/Yes/No');
        Observer.Expect('get', 'Yes|user');
        Observer.Expect('getCompanyAndUser', 'No|');
        Observer.Expect('delete', 'Yes');
        Observer.Expect('scopesAfter', 'No/No/No/No');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidText_CompanyAndUserScope()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
        V: Text;
    begin
        K := KeyText();
        Clean(K);
        Observer.Observe('set', Format(IsolatedStorage.Set(K, 'cau', DataScope::CompanyAndUser)));
        Observer.Observe('scopes', Cnt(K));
        V := '';
        Observer.Observe('get', Format(IsolatedStorage.Get(K, DataScope::CompanyAndUser, V)) + '|' + V);
        V := '';
        Observer.Observe('getUser', Format(IsolatedStorage.Get(K, DataScope::User, V)) + '|' + V);
        Observer.Observe('delete', Format(IsolatedStorage.Delete(K, DataScope::CompanyAndUser)));
        Observer.Observe('scopesAfter', Cnt(K));
        Clean(K);
        Observer.Expect('set', 'Yes');
        Observer.Expect('scopes', 'No/No/No/Yes');
        Observer.Expect('get', 'Yes|cau');
        Observer.Expect('getUser', 'No|');
        Observer.Expect('delete', 'Yes');
        Observer.Expect('scopesAfter', 'No/No/No/No');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidText_AllScopesIndependent()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
        V: Text;
    begin
        K := KeyText();
        Clean(K);
        IsolatedStorage.Set(K, 'm', DataScope::Module);
        IsolatedStorage.Set(K, 'c', DataScope::Company);
        IsolatedStorage.Set(K, 'u', DataScope::User);
        IsolatedStorage.Set(K, 'cu', DataScope::CompanyAndUser);
        Observer.Observe('scopes', Cnt(K));
        V := '';
        IsolatedStorage.Get(K, DataScope::Module, V);
        Observer.Observe('m', V);
        IsolatedStorage.Get(K, DataScope::Company, V);
        Observer.Observe('c', V);
        IsolatedStorage.Get(K, DataScope::User, V);
        Observer.Observe('u', V);
        IsolatedStorage.Get(K, DataScope::CompanyAndUser, V);
        Observer.Observe('cu', V);
        IsolatedStorage.Delete(K, DataScope::Company);
        Observer.Observe('afterDeleteCompany', Cnt(K));
        Clean(K);
        Observer.Observe('afterClean', Cnt(K));
        Observer.Expect('scopes', 'Yes/Yes/Yes/Yes');
        Observer.Expect('m', 'm');
        Observer.Expect('c', 'c');
        Observer.Expect('u', 'u');
        Observer.Expect('cu', 'cu');
        Observer.Expect('afterDeleteCompany', 'Yes/No/Yes/Yes');
        Observer.Expect('afterClean', 'No/No/No/No');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidText_KeySpellings()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
        Bare: Text;
        V: Text;
    begin
        K := KeyText();
        Bare := K.Replace('{', '').Replace('}', '');
        Clean(K);
        Clean(Bare);
        Clean(LowerCase(K));
        IsolatedStorage.Set(K, 'braced', DataScope::Module);
        Observer.Observe('braced', Format(IsolatedStorage.Contains(K, DataScope::Module)));
        Observer.Observe('bare', Format(IsolatedStorage.Contains(Bare, DataScope::Module)));
        Observer.Observe('lower', Format(IsolatedStorage.Contains(LowerCase(K), DataScope::Module)));
        Observer.Observe('upper', Format(IsolatedStorage.Contains(UpperCase(K), DataScope::Module)));
        V := '';
        Observer.Observe('getBare', Format(IsolatedStorage.Get(Bare, DataScope::Module, V)) + '|' + V);
        V := '';
        Observer.Observe('getLower', Format(IsolatedStorage.Get(LowerCase(K), DataScope::Module, V)) + '|' + V);
        Observer.Observe('deleteBare', Format(IsolatedStorage.Delete(Bare, DataScope::Module)));
        Observer.Observe('stillThere', Format(IsolatedStorage.Contains(K, DataScope::Module)));
        Clean(K);
        Clean(Bare);
        Clean(LowerCase(K));
        Observer.Expect('braced', 'Yes');
        Observer.Expect('bare', 'No');
        Observer.Expect('lower', 'No');
        Observer.Expect('upper', 'Yes');
        Observer.Expect('getBare', 'No|');
        Observer.Expect('getLower', 'No|');
        Observer.Expect('deleteBare', 'No');
        Observer.Expect('stillThere', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P175_GuidText_OverwriteAndEmptyValue()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
        V: Text;
    begin
        K := KeyText();
        Clean(K);
        IsolatedStorage.Set(K, 'one', DataScope::Module);
        IsolatedStorage.Set(K, 'two', DataScope::Module);
        V := '';
        IsolatedStorage.Get(K, DataScope::Module, V);
        Observer.Observe('overwritten', V);
        IsolatedStorage.Set(K, '', DataScope::Module);
        V := 'x';
        Observer.Observe('getEmpty', Format(IsolatedStorage.Get(K, DataScope::Module, V)) + '|' + V);
        Observer.Observe('containsEmpty', Format(IsolatedStorage.Contains(K, DataScope::Module)));
        Clean(K);
        Observer.Expect('overwritten', 'two');
        Observer.Expect('getEmpty', 'Yes|');
        Observer.Expect('containsEmpty', 'Yes');
        Observer.Verify();
    end;
}
