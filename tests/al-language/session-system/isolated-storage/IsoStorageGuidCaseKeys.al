// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: IsolatedStorage keys that are the Guid text in upper case, in lower case and without braces, SET AS THREE ENTRIES at once: do they coexist with their own values, or does the
// second Set overwrite the first? Get of each spelling, Delete of one spelling and what remains, in every DataScope. LT P175 Iso Guid Text (session/lt-isolated-storage-guid) pins only
// that a lower-case Contains misses an upper-case key; the coexistence of both spellings and the per-scope behaviour are new here.
// The keys are the test's own and are deleted at the end of each test.
// BC versions: 29 (27 and 28 by CI)

codeunit 71700 "LT Iso Guid Case"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Upper(): Text
    var
        G: Guid;
    begin
        Evaluate(G, '{AB1C2D3E-4F5A-4B6C-8D7E-9F0A1B2C3D4E}');
        exit(UpperCase(Format(G)));
    end;

    local procedure Bare(): Text
    begin
        exit(Upper().Replace('{', '').Replace('}', ''));
    end;

    local procedure Clean(Scope: DataScope)
    begin
        if IsolatedStorage.Contains(Upper(), Scope) then
            IsolatedStorage.Delete(Upper(), Scope);
        if IsolatedStorage.Contains(LowerCase(Upper()), Scope) then
            IsolatedStorage.Delete(LowerCase(Upper()), Scope);
        if IsolatedStorage.Contains(Bare(), Scope) then
            IsolatedStorage.Delete(Bare(), Scope);
        if IsolatedStorage.Contains(LowerCase(Bare()), Scope) then
            IsolatedStorage.Delete(LowerCase(Bare()), Scope);
    end;

    local procedure GetOf(KeyValue: Text; Scope: DataScope): Text
    var
        V: Text;
    begin
        V := '';
        exit(Format(IsolatedStorage.Get(KeyValue, Scope, V)) + '|' + V);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Scope: DataScope)
    var
        Lower: Text;
    begin
        Lower := LowerCase(Upper());
        Clean(Scope);
        IsolatedStorage.Set(Upper(), 'UP', Scope);
        IsolatedStorage.Set(Lower, 'low', Scope);
        Observer.Observe('getUpper', GetOf(Upper(), Scope));
        Observer.Observe('getLower', GetOf(Lower, Scope));
        Observer.Observe('containsBoth', Format(IsolatedStorage.Contains(Upper(), Scope)) + '/' + Format(IsolatedStorage.Contains(Lower, Scope)));
        Observer.Observe('deleteLower', Format(IsolatedStorage.Delete(Lower, Scope)));
        Observer.Observe('afterDelete', Format(IsolatedStorage.Contains(Upper(), Scope)) + '/' + Format(IsolatedStorage.Contains(Lower, Scope)));
        Observer.Observe('getUpperAfter', GetOf(Upper(), Scope));
        Observer.Observe('deleteUpper', Format(IsolatedStorage.Delete(Upper(), Scope)));
        Observer.Observe('deleteUpperAgain', Format(IsolatedStorage.Delete(Upper(), Scope)));
        Clean(Scope);
    end;

    [Test]
    procedure GuidTextUpperLower_Module_Coexist()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, DataScope::Module);
        Observer.Expect('getUpper', 'Yes|UP');
        Observer.Expect('getLower', 'Yes|low');
        Observer.Expect('containsBoth', 'Yes/Yes');
        Observer.Expect('deleteLower', 'Yes');
        Observer.Expect('afterDelete', 'Yes/No');
        Observer.Expect('getUpperAfter', 'Yes|UP');
        Observer.Expect('deleteUpper', 'Yes');
        Observer.Expect('deleteUpperAgain', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GuidTextUpperLower_Company_Coexist()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, DataScope::Company);
        Observer.Expect('getUpper', 'Yes|UP');
        Observer.Expect('getLower', 'Yes|low');
        Observer.Expect('containsBoth', 'Yes/Yes');
        Observer.Expect('deleteLower', 'Yes');
        Observer.Expect('afterDelete', 'Yes/No');
        Observer.Expect('getUpperAfter', 'Yes|UP');
        Observer.Expect('deleteUpper', 'Yes');
        Observer.Expect('deleteUpperAgain', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GuidTextUpperLower_User_Coexist()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, DataScope::User);
        Observer.Expect('getUpper', 'Yes|UP');
        Observer.Expect('getLower', 'Yes|low');
        Observer.Expect('containsBoth', 'Yes/Yes');
        Observer.Expect('deleteLower', 'Yes');
        Observer.Expect('afterDelete', 'Yes/No');
        Observer.Expect('getUpperAfter', 'Yes|UP');
        Observer.Expect('deleteUpper', 'Yes');
        Observer.Expect('deleteUpperAgain', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GuidTextUpperLower_CompanyAndUser_Coexist()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, DataScope::CompanyAndUser);
        Observer.Expect('getUpper', 'Yes|UP');
        Observer.Expect('getLower', 'Yes|low');
        Observer.Expect('containsBoth', 'Yes/Yes');
        Observer.Expect('deleteLower', 'Yes');
        Observer.Expect('afterDelete', 'Yes/No');
        Observer.Expect('getUpperAfter', 'Yes|UP');
        Observer.Expect('deleteUpper', 'Yes');
        Observer.Expect('deleteUpperAgain', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure GuidTextBracedBareLower_ThreeSpellings_Module()
    var
        Observer: Codeunit "Probe Observer";
        Lower: Text;
    begin
        Lower := LowerCase(Upper());
        Clean(DataScope::Module);
        IsolatedStorage.Set(Upper(), 'braced', DataScope::Module);
        IsolatedStorage.Set(Bare(), 'bare', DataScope::Module);
        IsolatedStorage.Set(Lower, 'lower', DataScope::Module);
        IsolatedStorage.Set(LowerCase(Bare()), 'lowerBare', DataScope::Module);
        Observer.Observe('getBraced', GetOf(Upper(), DataScope::Module));
        Observer.Observe('getBare', GetOf(Bare(), DataScope::Module));
        Observer.Observe('getLower', GetOf(Lower, DataScope::Module));
        Observer.Observe('getLowerBare', GetOf(LowerCase(Bare()), DataScope::Module));
        Observer.Observe('deleteBare', Format(IsolatedStorage.Delete(Bare(), DataScope::Module)));
        Observer.Observe('afterDeleteBare', Format(IsolatedStorage.Contains(Upper(), DataScope::Module)) + '/' + Format(IsolatedStorage.Contains(Bare(), DataScope::Module)) + '/' +
            Format(IsolatedStorage.Contains(Lower, DataScope::Module)) + '/' + Format(IsolatedStorage.Contains(LowerCase(Bare()), DataScope::Module)));
        Clean(DataScope::Module);
        Observer.Observe('afterClean', Format(IsolatedStorage.Contains(Upper(), DataScope::Module)) + '/' + Format(IsolatedStorage.Contains(Lower, DataScope::Module)));
        Observer.Expect('getBraced', 'Yes|braced');
        Observer.Expect('getBare', 'Yes|bare');
        Observer.Expect('getLower', 'Yes|lower');
        Observer.Expect('getLowerBare', 'Yes|lowerBare');
        Observer.Expect('deleteBare', 'Yes');
        Observer.Expect('afterDeleteBare', 'Yes/No/Yes/Yes');
        Observer.Expect('afterClean', 'No/No');
        Observer.Verify();
    end;

    [Test]
    procedure GuidTextLower_SetThenOverwriteUpper_Module()
    var
        Observer: Codeunit "Probe Observer";
        Lower: Text;
    begin
        Lower := LowerCase(Upper());
        Clean(DataScope::Module);
        IsolatedStorage.Set(Lower, 'first', DataScope::Module);
        Observer.Observe('containsUpperAfterLowerSet', Format(IsolatedStorage.Contains(Upper(), DataScope::Module)));
        IsolatedStorage.Set(Upper(), 'second', DataScope::Module);
        Observer.Observe('getLower', GetOf(Lower, DataScope::Module));
        Observer.Observe('getUpper', GetOf(Upper(), DataScope::Module));
        IsolatedStorage.Set(Lower, 'third', DataScope::Module);
        Observer.Observe('getLowerAfterSet', GetOf(Lower, DataScope::Module));
        Observer.Observe('getUpperAfterSet', GetOf(Upper(), DataScope::Module));
        Clean(DataScope::Module);
        Observer.Expect('containsUpperAfterLowerSet', 'No');
        Observer.Expect('getLower', 'Yes|first');
        Observer.Expect('getUpper', 'Yes|second');
        Observer.Expect('getLowerAfterSet', 'Yes|third');
        Observer.Expect('getUpperAfterSet', 'Yes|second');
        Observer.Verify();
    end;
}
