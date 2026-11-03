// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/isolatedstorage/isolatedstorage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); worker codeunit 74191, test codeunit 74192
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 5 (NP Retail blockers): IsolatedStorage Set, Contains, Get and Delete with a key that is not a Text, passed through a Variant
// (Integer, Code, Guid, Decimal, Boolean, Date) in each DataScope: accepted (and which Text key it matches) or the error text and code.
// An Integer variable as the key does not compile (AL0133): tests/must-not-compile/cases/0480-isolated-storage-integer-key.al.
// A Guid variable and a Code variable compile; the Guid key is pinned in session/lt-isolated-storage-guid/IsoStorageGuidKey.al.
// The calls run in a worker codeunit through Codeunit.Run so that an error is read with GetLastErrorText; every key is deleted at the end of its test.
// BC versions: 27, 28, 29

codeunit 74191 "LT ISK Worker"
{
    var
        Op: Integer;
        KeyValue: Variant;
        Scope: DataScope;
        Stored: Text;
        Result: Text;

    procedure Prepare(NewOp: Integer; NewKey: Variant; NewScope: DataScope; NewStored: Text)
    begin
        Op := NewOp;
        KeyValue := NewKey;
        Scope := NewScope;
        Stored := NewStored;
        Result := '';
    end;

    procedure GetResult(): Text
    begin
        exit(Result);
    end;

    trigger OnRun()
    begin
        case Op of
            1:
                IsolatedStorage.Set(KeyValue, Stored, Scope);
            2:
                Result := Format(IsolatedStorage.Contains(KeyValue, Scope));
            3:
                begin
                    Result := Format(IsolatedStorage.Get(KeyValue, Scope, Stored));
                    Result += '|' + Stored;
                end;
            4:
                Result := Format(IsolatedStorage.Delete(KeyValue, Scope));
        end;
    end;
}

codeunit 74192 "LT ISK Variant Key"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LastErrorText: Text;

    local procedure Exec(Op: Integer; KeyValue: Variant; Scope: DataScope; Stored: Text): Text
    var
        Worker: Codeunit "LT ISK Worker";
    begin
        LastErrorText := '';
        ClearLastError();
        Worker.Prepare(Op, KeyValue, Scope, Stored);
        if Worker.Run() then
            exit('ok:' + Worker.GetResult());
        LastErrorText := GetLastErrorText();
        exit('err:' + GetLastErrorCode());
    end;

    local procedure AllScopes(Observer: Codeunit "Probe Observer"; KeyValue: Variant; Prefix: Text; AsText: Text)
    begin
        Observer.Observe(Prefix + '_module_set', Exec(1, KeyValue, DataScope::Module, 'v'));
        Observer.Observe(Prefix + '_module_set_error_text', LastErrorText);
        Observer.Observe(Prefix + '_module_contains', Exec(2, KeyValue, DataScope::Module, ''));
        Observer.Observe(Prefix + '_module_get', Exec(3, KeyValue, DataScope::Module, ''));
        Observer.Observe(Prefix + '_module_contains_as_text', Format(IsolatedStorage.Contains(AsText, DataScope::Module)));
        Observer.Observe(Prefix + '_module_delete', Exec(4, KeyValue, DataScope::Module, ''));
        Observer.Observe(Prefix + '_company_set', Exec(1, KeyValue, DataScope::Company, 'v'));
        Observer.Observe(Prefix + '_company_contains', Exec(2, KeyValue, DataScope::Company, ''));
        Observer.Observe(Prefix + '_company_delete', Exec(4, KeyValue, DataScope::Company, ''));
        Observer.Observe(Prefix + '_user_set', Exec(1, KeyValue, DataScope::User, 'v'));
        Observer.Observe(Prefix + '_user_contains', Exec(2, KeyValue, DataScope::User, ''));
        Observer.Observe(Prefix + '_user_delete', Exec(4, KeyValue, DataScope::User, ''));
        Observer.Observe(Prefix + '_cu_set', Exec(1, KeyValue, DataScope::CompanyAndUser, 'v'));
        Observer.Observe(Prefix + '_cu_contains', Exec(2, KeyValue, DataScope::CompanyAndUser, ''));
        Observer.Observe(Prefix + '_cu_delete', Exec(4, KeyValue, DataScope::CompanyAndUser, ''));
    end;

    [Test]
    procedure VariantKey_Integer()
    var
        Observer: Codeunit "Probe Observer";
        K: Integer;
    begin
        K := 5;
        AllScopes(Observer, K, 'int', '5');
        if IsolatedStorage.Delete('5', DataScope::Module) then;
        Observer.Expect('int_module_set', 'err:TypeConversion');
        Observer.Expect('int_module_set_error_text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('int_module_contains', 'err:TypeConversion');
        Observer.Expect('int_module_get', 'err:TypeConversion');
        Observer.Expect('int_module_contains_as_text', 'No');
        Observer.Expect('int_module_delete', 'err:TypeConversion');
        Observer.Expect('int_company_set', 'err:TypeConversion');
        Observer.Expect('int_company_contains', 'err:TypeConversion');
        Observer.Expect('int_company_delete', 'err:TypeConversion');
        Observer.Expect('int_user_set', 'err:TypeConversion');
        Observer.Expect('int_user_contains', 'err:TypeConversion');
        Observer.Expect('int_user_delete', 'err:TypeConversion');
        Observer.Expect('int_cu_set', 'err:TypeConversion');
        Observer.Expect('int_cu_contains', 'err:TypeConversion');
        Observer.Expect('int_cu_delete', 'err:TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantKey_Code()
    var
        Observer: Codeunit "Probe Observer";
        K: Code[20];
    begin
        K := 'abc';
        AllScopes(Observer, K, 'code', 'ABC');
        if IsolatedStorage.Delete('ABC', DataScope::Module) then;
        if IsolatedStorage.Delete('abc', DataScope::Module) then;
        Observer.Expect('code_module_set', 'ok:');
        Observer.Expect('code_module_set_error_text', '');
        Observer.Expect('code_module_contains', 'ok:Yes');
        Observer.Expect('code_module_get', 'ok:Yes|v');
        Observer.Expect('code_module_contains_as_text', 'Yes');
        Observer.Expect('code_module_delete', 'ok:Yes');
        Observer.Expect('code_company_set', 'ok:');
        Observer.Expect('code_company_contains', 'ok:Yes');
        Observer.Expect('code_company_delete', 'ok:Yes');
        Observer.Expect('code_user_set', 'ok:');
        Observer.Expect('code_user_contains', 'ok:Yes');
        Observer.Expect('code_user_delete', 'ok:Yes');
        Observer.Expect('code_cu_set', 'ok:');
        Observer.Expect('code_cu_contains', 'ok:Yes');
        Observer.Expect('code_cu_delete', 'ok:Yes');
        Observer.Verify();
    end;

    [Test]
    procedure VariantKey_Guid()
    var
        Observer: Codeunit "Probe Observer";
        K: Guid;
    begin
        Evaluate(K, '{12345678-1234-1234-1234-123456789ABC}');
        AllScopes(Observer, K, 'guid', Format(K));
        if IsolatedStorage.Delete(Format(K), DataScope::Module) then;
        Observer.Expect('guid_module_set', 'ok:');
        Observer.Expect('guid_module_set_error_text', '');
        Observer.Expect('guid_module_contains', 'ok:Yes');
        Observer.Expect('guid_module_get', 'ok:Yes|v');
        Observer.Expect('guid_module_contains_as_text', 'Yes');
        Observer.Expect('guid_module_delete', 'ok:Yes');
        Observer.Expect('guid_company_set', 'ok:');
        Observer.Expect('guid_company_contains', 'ok:Yes');
        Observer.Expect('guid_company_delete', 'ok:Yes');
        Observer.Expect('guid_user_set', 'ok:');
        Observer.Expect('guid_user_contains', 'ok:Yes');
        Observer.Expect('guid_user_delete', 'ok:Yes');
        Observer.Expect('guid_cu_set', 'ok:');
        Observer.Expect('guid_cu_contains', 'ok:Yes');
        Observer.Expect('guid_cu_delete', 'ok:Yes');
        Observer.Verify();
    end;

    [Test]
    procedure VariantKey_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        K: Decimal;
    begin
        K := 1.5;
        AllScopes(Observer, K, 'dec', '1.5');
        if IsolatedStorage.Delete('1.5', DataScope::Module) then;
        Observer.Expect('dec_module_set', 'err:TypeConversion');
        Observer.Expect('dec_module_set_error_text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('dec_module_contains', 'err:TypeConversion');
        Observer.Expect('dec_module_get', 'err:TypeConversion');
        Observer.Expect('dec_module_contains_as_text', 'No');
        Observer.Expect('dec_module_delete', 'err:TypeConversion');
        Observer.Expect('dec_company_set', 'err:TypeConversion');
        Observer.Expect('dec_company_contains', 'err:TypeConversion');
        Observer.Expect('dec_company_delete', 'err:TypeConversion');
        Observer.Expect('dec_user_set', 'err:TypeConversion');
        Observer.Expect('dec_user_contains', 'err:TypeConversion');
        Observer.Expect('dec_user_delete', 'err:TypeConversion');
        Observer.Expect('dec_cu_set', 'err:TypeConversion');
        Observer.Expect('dec_cu_contains', 'err:TypeConversion');
        Observer.Expect('dec_cu_delete', 'err:TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantKey_Boolean()
    var
        Observer: Codeunit "Probe Observer";
        K: Boolean;
    begin
        K := true;
        AllScopes(Observer, K, 'bool', Format(K));
        if IsolatedStorage.Delete(Format(K), DataScope::Module) then;
        Observer.Expect('bool_module_set', 'err:TypeConversion');
        Observer.Expect('bool_module_set_error_text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('bool_module_contains', 'err:TypeConversion');
        Observer.Expect('bool_module_get', 'err:TypeConversion');
        Observer.Expect('bool_module_contains_as_text', 'No');
        Observer.Expect('bool_module_delete', 'err:TypeConversion');
        Observer.Expect('bool_company_set', 'err:TypeConversion');
        Observer.Expect('bool_company_contains', 'err:TypeConversion');
        Observer.Expect('bool_company_delete', 'err:TypeConversion');
        Observer.Expect('bool_user_set', 'err:TypeConversion');
        Observer.Expect('bool_user_contains', 'err:TypeConversion');
        Observer.Expect('bool_user_delete', 'err:TypeConversion');
        Observer.Expect('bool_cu_set', 'err:TypeConversion');
        Observer.Expect('bool_cu_contains', 'err:TypeConversion');
        Observer.Expect('bool_cu_delete', 'err:TypeConversion');
        Observer.Verify();
    end;

    [Test]
    procedure VariantKey_Date()
    var
        Observer: Codeunit "Probe Observer";
        K: Date;
    begin
        K := DMY2Date(2, 1, 2026);
        AllScopes(Observer, K, 'date', Format(K));
        if IsolatedStorage.Delete(Format(K), DataScope::Module) then;
        Observer.Expect('date_module_set', 'err:TypeConversion');
        Observer.Expect('date_module_set_error_text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('date_module_contains', 'err:TypeConversion');
        Observer.Expect('date_module_get', 'err:TypeConversion');
        Observer.Expect('date_module_contains_as_text', 'No');
        Observer.Expect('date_module_delete', 'err:TypeConversion');
        Observer.Expect('date_company_set', 'err:TypeConversion');
        Observer.Expect('date_company_contains', 'err:TypeConversion');
        Observer.Expect('date_company_delete', 'err:TypeConversion');
        Observer.Expect('date_user_set', 'err:TypeConversion');
        Observer.Expect('date_user_contains', 'err:TypeConversion');
        Observer.Expect('date_user_delete', 'err:TypeConversion');
        Observer.Expect('date_cu_set', 'err:TypeConversion');
        Observer.Expect('date_cu_contains', 'err:TypeConversion');
        Observer.Expect('date_cu_delete', 'err:TypeConversion');
        Observer.Verify();
    end;
}
