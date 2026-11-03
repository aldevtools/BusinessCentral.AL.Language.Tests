// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/secrettext/secrettext-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//
// SecretText (Unwrap, IsEmpty, comparison, SecretStrSubstNo, Format) and IsolatedStorage (every DataScope, SecretText overloads).
// Fixtures used: Probe Observer (69160); self-contained codeunits 73032, 73033, 73034
// BC versions: 29 (27 and 28 by CI)

codeunit 73032 "LT EnT SecretText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Default_IsEmpty()
    var
        Observer: Codeunit "Probe Observer";
        S: SecretText;
    begin
        Observer.Observe('isempty', Format(S.IsEmpty()));
        Clear(S);
        Observer.Observe('cleared isempty', Format(S.IsEmpty()));
        Observer.Expect('isempty', 'Yes');
        Observer.Expect('cleared isempty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Empty()
    var
        Observer: Codeunit "Probe Observer";
        A: SecretText;
        B: SecretText;
    begin
        B := A;
        Observer.Observe('copy isempty', Format(B.IsEmpty()));
        Observer.Expect('copy isempty', 'Yes');
        Observer.Verify();
    end;
}

codeunit 73033 "LT EnT Isolated Storage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SetGet_DefaultScope()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
    begin
        Cleanup();
        Observer.Observe('set', Format(IsolatedStorage.Set('EnTk1', 'v1')));
        Observer.Observe('contains', Format(IsolatedStorage.Contains('EnTk1')));
        Observer.Observe('get', Format(IsolatedStorage.Get('EnTk1', V)));
        Observer.Observe('value', V);
        Observer.Observe('contains module', Format(IsolatedStorage.Contains('EnTk1', DataScope::Module)));
        Observer.Observe('contains company', Format(IsolatedStorage.Contains('EnTk1', DataScope::Company)));
        Observer.Observe('contains user', Format(IsolatedStorage.Contains('EnTk1', DataScope::User)));
        Observer.Observe('contains cau', Format(IsolatedStorage.Contains('EnTk1', DataScope::CompanyAndUser)));
        Cleanup();
        Observer.Expect('set', 'Yes');
        Observer.Expect('contains', 'Yes');
        Observer.Expect('get', 'Yes');
        Observer.Expect('value', 'v1');
        Observer.Expect('contains module', 'Yes');
        Observer.Expect('contains company', 'No');
        Observer.Expect('contains user', 'No');
        Observer.Expect('contains cau', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Scopes_AreIndependent()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
    begin
        Cleanup();
        IsolatedStorage.Set('EnTk', 'module', DataScope::Module);
        IsolatedStorage.Set('EnTk', 'company', DataScope::Company);
        IsolatedStorage.Set('EnTk', 'user', DataScope::User);
        IsolatedStorage.Set('EnTk', 'cau', DataScope::CompanyAndUser);
        IsolatedStorage.Get('EnTk', DataScope::Module, V);
        Observer.Observe('module', V);
        IsolatedStorage.Get('EnTk', DataScope::Company, V);
        Observer.Observe('company', V);
        IsolatedStorage.Get('EnTk', DataScope::User, V);
        Observer.Observe('user', V);
        IsolatedStorage.Get('EnTk', DataScope::CompanyAndUser, V);
        Observer.Observe('cau', V);
        IsolatedStorage.Get('EnTk', V);
        Observer.Observe('default is module', V);
        Observer.Observe('delete company', Format(IsolatedStorage.Delete('EnTk', DataScope::Company)));
        Observer.Observe('company gone', Format(IsolatedStorage.Contains('EnTk', DataScope::Company)));
        Observer.Observe('module stays', Format(IsolatedStorage.Contains('EnTk', DataScope::Module)));
        Cleanup();
        Observer.Expect('module', 'module');
        Observer.Expect('company', 'company');
        Observer.Expect('user', 'user');
        Observer.Expect('cau', 'cau');
        Observer.Expect('default is module', 'module');
        Observer.Expect('delete company', 'Yes');
        Observer.Expect('company gone', 'No');
        Observer.Expect('module stays', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Get_Missing()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
    begin
        Cleanup();
        V := 'preset';
        Observer.Observe('get missing', Format(IsolatedStorage.Get('EnTmissing', V)));
        Observer.Observe('value after', V);
        Observer.Observe('get missing company', Format(IsolatedStorage.Get('EnTmissing', DataScope::Company, V)));
        asserterror IsolatedStorage.Delete('EnTmissing');
        Observer.ObserveError('delete missing');
        Observer.Observe('contains missing', Format(IsolatedStorage.Contains('EnTmissing')));
        Observer.Expect('get missing', 'No');
        Observer.Expect('value after', '');
        Observer.Expect('get missing company', 'No');
        Observer.Expect('delete missing|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''EnTmissing''');
        Observer.Expect('delete missing|code', 'DB:RecordNotFound');
        Observer.Expect('contains missing', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Overwrite_And_Delete()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
    begin
        Cleanup();
        IsolatedStorage.Set('EnTk1', 'one');
        IsolatedStorage.Set('EnTk1', 'two');
        IsolatedStorage.Get('EnTk1', V);
        Observer.Observe('overwritten', V);
        IsolatedStorage.Set('EnTk1', '');
        Observer.Observe('empty contains', Format(IsolatedStorage.Contains('EnTk1')));
        V := 'x';
        Observer.Observe('empty get', Format(IsolatedStorage.Get('EnTk1', V)));
        Observer.Observe('empty value len', Format(StrLen(V)));
        Observer.Observe('delete', Format(IsolatedStorage.Delete('EnTk1')));
        asserterror IsolatedStorage.Delete('EnTk1');
        Observer.ObserveError('delete again');
        Observer.Observe('contains after', Format(IsolatedStorage.Contains('EnTk1')));
        Observer.Expect('overwritten', 'two');
        Observer.Expect('empty contains', 'Yes');
        Observer.Expect('empty get', 'Yes');
        Observer.Expect('empty value len', '0');
        Observer.Expect('delete', 'Yes');
        Observer.Expect('delete again|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''EnTk1''');
        Observer.Expect('delete again|code', 'DB:RecordNotFound');
        Observer.Expect('contains after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure KeyCase_Characters()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
    begin
        Cleanup();
        IsolatedStorage.Set('EnTKey', 'upper');
        Observer.Observe('lower contains', Format(IsolatedStorage.Contains('entkey')));
        V := '';
        Observer.Observe('lower get', Format(IsolatedStorage.Get('entkey', V)));
        Observer.Observe('lower value', V);
        IsolatedStorage.Set('EnT key with spaces', 's');
        Observer.Observe('spaces', Format(IsolatedStorage.Contains('EnT key with spaces')));
        IsolatedStorage.Set('EnT/\:*?<>|', 'sym');
        Observer.Observe('symbols', Format(IsolatedStorage.Contains('EnT/\:*?<>|')));
        IsolatedStorage.Set('EnTäöü✓', 'uni');
        Observer.Observe('unicode', Format(IsolatedStorage.Contains('EnTäöü✓')));
        IsolatedStorage.Set('EnT trail ', 't');
        Observer.Observe('trailing', Format(IsolatedStorage.Contains('EnT trail')));
        Cleanup();
        if IsolatedStorage.Contains('EnT/\:*?<>|') then
            IsolatedStorage.Delete('EnT/\:*?<>|');
        if IsolatedStorage.Contains('EnTäöü✓') then
            IsolatedStorage.Delete('EnTäöü✓');
        if IsolatedStorage.Contains('EnT key with spaces') then
            IsolatedStorage.Delete('EnT key with spaces');
        if IsolatedStorage.Contains('EnT trail ') then
            IsolatedStorage.Delete('EnT trail ');
        Observer.Expect('lower contains', 'No');
        Observer.Expect('lower get', 'No');
        Observer.Expect('lower value', '');
        Observer.Expect('spaces', 'Yes');
        Observer.Expect('symbols', 'Yes');
        Observer.Expect('unicode', 'Yes');
        Observer.Expect('trailing', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Key_Empty()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
    begin
        Observer.Observe('empty key contains', Format(IsolatedStorage.Contains('')));
        asserterror IsolatedStorage.Delete('');
        Observer.ObserveError('empty key delete');
        asserterror IsolatedStorage.Get('', K);
        Observer.ObserveError('empty key get');
        Observer.Expect('empty key contains', 'No');
        Observer.Expect('empty key delete|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''''');
        Observer.Expect('empty key delete|code', 'DB:RecordNotFound');
        Observer.Expect('empty key get|text', 'The Isolated Storage does not exist. Identification fields and values: App Id=''{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}'',Scope=''Module'',Company Name='''',User Id=''{00000000-0000-0000-0000-000000000000}'',Key=''''');
        Observer.Expect('empty key get|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Key_Empty_Set()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty key set', Format(IsolatedStorage.Set('', 'v')));
        Observer.Observe('contains after', Format(IsolatedStorage.Contains('')));
        Observer.Expect('empty key set', 'Yes');
        Observer.Expect('contains after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Key_Length_200()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
    begin
        K := PadStr('', 200, 'k');
        IsolatedStorage.Set(K, 'v');
        Observer.Observe('200 chars', Format(IsolatedStorage.Contains(K)));
        IsolatedStorage.Delete(K);
        Observer.Expect('200 chars', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Key_Length_201()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
    begin
        K := PadStr('', 201, 'k');
        asserterror Observer.Observe('201 set', Format(IsolatedStorage.Set(K, 'v')));
        Observer.ObserveError('af207');
        asserterror Observer.Observe('201 contains', Format(IsolatedStorage.Contains(K)));
        Observer.ObserveError('af209');
        Observer.Expect('af207|text', 'Key must not be longer than 200.');
        Observer.Expect('af207|code', 'AL');
        Observer.Expect('af209|text', 'Key must not be longer than 200.');
        Observer.Expect('af209|code', 'AL');
        Observer.Verify();
    end;

    [Test]
    procedure Key_Length_1000()
    var
        Observer: Codeunit "Probe Observer";
        K: Text;
    begin
        K := PadStr('', 1000, 'k');
        asserterror Observer.Observe('1000 set', Format(IsolatedStorage.Set(K, 'v')));
        Observer.ObserveError('af220');
        asserterror Observer.Observe('1000 contains', Format(IsolatedStorage.Contains(K)));
        Observer.ObserveError('af223');
        Observer.Expect('af220|text', 'Key must not be longer than 200.');
        Observer.Expect('af220|code', 'AL');
        Observer.Expect('af223|text', 'Key must not be longer than 200.');
        Observer.Expect('af223|code', 'AL');
        Observer.Verify();
    end;

    [Test]
    procedure Value_Lengths()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
        Back: Text;
    begin
        Cleanup();
        V := PadStr('', 1000, 'a');
        IsolatedStorage.Set('EnTlong', V);
        IsolatedStorage.Get('EnTlong', Back);
        Observer.Observe('1000', Format(StrLen(Back)));
        V := PadStr('', 100000, 'b');
        IsolatedStorage.Set('EnTlong', V);
        IsolatedStorage.Get('EnTlong', Back);
        Observer.Observe('100000', Format(StrLen(Back)));
        Observer.Observe('100000 equal', Format(Back = V));
        Cleanup();
        Observer.Expect('1000', '1000');
        Observer.Expect('100000', '100000');
        Observer.Expect('100000 equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Value_Length_500000()
    var
        Observer: Codeunit "Probe Observer";
        Back: Text;
    begin
        Cleanup();
        IsolatedStorage.Set('EnTlong', PadStr('', 500000, 'c'));
        IsolatedStorage.Get('EnTlong', Back);
        Observer.Observe('500000', Format(StrLen(Back)));
        Cleanup();
        Observer.Expect('500000', '500000');
        Observer.Verify();
    end;

    [Test]
    procedure Value_Length_1000000()
    var
        Observer: Codeunit "Probe Observer";
        Back: Text;
    begin
        Cleanup();
        IsolatedStorage.Set('EnTlong', PadStr('', 1000000, 'd'));
        IsolatedStorage.Get('EnTlong', Back);
        Observer.Observe('1000000', Format(StrLen(Back)));
        Cleanup();
        Observer.Expect('1000000', '1000000');
        Observer.Verify();
    end;

    [Test]
    procedure Value_Special_Texts()
    var
        Observer: Codeunit "Probe Observer";
        Back: Text;
    begin
        Cleanup();
        IsolatedStorage.Set('EnTv', 'äöü ✓ 😀');
        IsolatedStorage.Get('EnTv', Back);
        Observer.Observe('unicode', Back);
        IsolatedStorage.Set('EnTv', ' lead and trail ');
        IsolatedStorage.Get('EnTv', Back);
        Observer.Observe('spaces len', Format(StrLen(Back)));
        IsolatedStorage.Set('EnTv', 'a' + Format(CreateGuid()).Substring(1, 0) + 'b');
        IsolatedStorage.Get('EnTv', Back);
        Observer.Observe('plain', Back);
        if IsolatedStorage.Contains('EnTv') then
            IsolatedStorage.Delete('EnTv');
        Observer.Expect('unicode', 'äöü ✓ \uD83D\uDE00');
        Observer.Expect('spaces len', '16');
        Observer.Expect('plain', 'ab');
        Observer.Verify();
    end;

    [Test]
    procedure SecretText_Overloads()
    var
        Observer: Codeunit "Probe Observer";
        S: SecretText;
        Back: SecretText;
    begin
        Cleanup();
        IsolatedStorage.Set('EnTs', S);
        Observer.Observe('empty secret contains', Format(IsolatedStorage.Contains('EnTs')));
        Observer.Observe('get', Format(IsolatedStorage.Get('EnTs', Back)));
        Observer.Observe('get isempty', Format(Back.IsEmpty()));
        Observer.Observe('missing', Format(IsolatedStorage.Get('EnTmissing', DataScope::Company, Back)));
        Cleanup();
        Observer.Expect('empty secret contains', 'Yes');
        Observer.Expect('get', 'Yes');
        Observer.Expect('get isempty', 'Yes');
        Observer.Expect('missing', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Get_Text_Into_Fixed_Length()
    var
        Observer: Codeunit "Probe Observer";
        Short: Text[5];
    begin
        Cleanup();
        IsolatedStorage.Set('EnTfix', '0123456789');
        asserterror Observer.Observe('get', Format(IsolatedStorage.Get('EnTfix', Short)));
        Observer.ObserveError('into text5');
        Observer.Observe('short', Short);
        Cleanup();
        Observer.Expect('into text5|text', 'The length of the string is 10, but it must be less than or equal to 5 characters. Value: 0123456789');
        Observer.Expect('into text5|code', 'StringLengthExceeded');
        Observer.Expect('short', '');
        Observer.Verify();
    end;

    local procedure Cleanup()
    var
        Names: List of [Text];
        N: Text;
    begin
        Names.Add('EnTk1');
        Names.Add('EnTk');
        Names.Add('EnTKey');
        Names.Add('EnTs');
        Names.Add('EnTfix');
        Names.Add('EnTv');
        Names.Add('EnTlong');
        foreach N in Names do begin
            if IsolatedStorage.Contains(N, DataScope::Module) then
                IsolatedStorage.Delete(N, DataScope::Module);
            if IsolatedStorage.Contains(N, DataScope::Company) then
                IsolatedStorage.Delete(N, DataScope::Company);
            if IsolatedStorage.Contains(N, DataScope::User) then
                IsolatedStorage.Delete(N, DataScope::User);
            if IsolatedStorage.Contains(N, DataScope::CompanyAndUser) then
                IsolatedStorage.Delete(N, DataScope::CompanyAndUser);
        end;
    end;
}
