// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-writewithsecretsto-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 61283
// Probe: written against BC 29 (runtime 16); the values are measured on the corpus CI service tiers.
// Facts: JsonObject.WriteWithSecretsTo(Path, Secret, var Result) and WriteWithSecretsTo(Secrets, var Result): substitution, several secrets, missing path or key
// BC versions: 27, 28, 29

codeunit 61283 "LT S Write With Secrets"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Load(var O: JsonObject)
    begin
        O.ReadFrom('{"user":"anna","password":"placeholder","nested":{"token":"t0","list":[1,2]},"n":5}');
    end;

    local procedure Sec(Value: Text) Result: SecretText
    begin
        Result := Value;
    end;

    [NonDebuggable]
    local procedure Plain(Result: SecretText): Text
    begin
        exit(Result.Unwrap());
    end;

    [Test]
    procedure WriteWithSecretsTo_SinglePath()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Secret: SecretText;
        Result: SecretText;
        Ok: Boolean;
    begin
        Load(O);
        Secret := Sec('s3cret');
        Ok := O.WriteWithSecretsTo('password', Secret, Result);
        Observer.Observe('top', Format(Ok) + ' ' + Plain(Result));
        Ok := O.WriteWithSecretsTo('$.password', Secret, Result);
        Observer.Observe('dollar', Format(Ok) + ' ' + Plain(Result));
        Ok := O.WriteWithSecretsTo('nested.token', Secret, Result);
        Observer.Observe('nested', Format(Ok) + ' ' + Plain(Result));
        Ok := O.WriteWithSecretsTo('n', Secret, Result);
        Observer.Observe('number_value', Format(Ok) + ' ' + Plain(Result));
        Ok := O.WriteWithSecretsTo('nested', Secret, Result);
        Observer.Observe('object_value', Format(Ok) + ' ' + Plain(Result));
        Ok := O.WriteWithSecretsTo('nested.list[0]', Secret, Result);
        Observer.Observe('array_element', Format(Ok) + ' ' + Plain(Result));
        Ok := O.WriteWithSecretsTo('missing', Secret, Result);
        Observer.Observe('missing_ok', Format(Ok));
        Observer.Observe('missing_result', Plain(Result));
        Ok := O.WriteWithSecretsTo('', Secret, Result);
        Observer.Observe('empty_path_ok', Format(Ok));
        Observer.Observe('empty_path_result', Plain(Result));
        Clear(Result);
        Ok := O.WriteWithSecretsTo('missing', Secret, Result);
        Observer.Observe('missing_cleared_ok', Format(Ok));
        Observer.Observe('missing_cleared_result', Plain(Result));
        Clear(Secret);
        Ok := O.WriteWithSecretsTo('password', Secret, Result);
        Observer.Observe('empty_secret', Format(Ok) + ' ' + Plain(Result));
        Secret := Sec('a"b\c');
        Ok := O.WriteWithSecretsTo('password', Secret, Result);
        Observer.Observe('escaped_secret', Format(Ok) + ' ' + Plain(Result));
        Observer.Observe('source_unchanged', Format(O));
        Ok := O.WriteWithSecretsTo('bad[', Secret, Result);
        Observer.Observe('invalid_path_ok', Format(Ok));
        Observer.Observe('invalid_path_result', Plain(Result));
        Ok := O.WriteWithSecretsTo('a..b', Secret, Result);
        Observer.Observe('double_dot_ok', Format(Ok));
        Observer.Observe('double_dot_result', Plain(Result));
        Observer.Expect('top', 'Yes {"user":"anna","password":"s3cret","nested":{"token":"t0","list":[1,2]},"n":5}');
        Observer.Expect('dollar', 'Yes {"user":"anna","password":"s3cret","nested":{"token":"t0","list":[1,2]},"n":5}');
        Observer.Expect('nested', 'Yes {"user":"anna","password":"placeholder","nested":{"token":"s3cret","list":[1,2]},"n":5}');
        Observer.Expect('number_value', 'No {"user":"anna","password":"placeholder","nested":{"token":"s3cret","list":[1,2]},"n":5}');
        Observer.Expect('object_value', 'No {"user":"anna","password":"placeholder","nested":{"token":"s3cret","list":[1,2]},"n":5}');
        Observer.Expect('array_element', 'No {"user":"anna","password":"placeholder","nested":{"token":"s3cret","list":[1,2]},"n":5}');
        Observer.Expect('missing_ok', 'No');
        Observer.Expect('missing_result', '{"user":"anna","password":"placeholder","nested":{"token":"s3cret","list":[1,2]},"n":5}');
        Observer.Expect('empty_path_ok', 'No');
        Observer.Expect('empty_path_result', '{"user":"anna","password":"placeholder","nested":{"token":"s3cret","list":[1,2]},"n":5}');
        Observer.Expect('missing_cleared_ok', 'No');
        Observer.Expect('missing_cleared_result', '');
        Observer.Expect('empty_secret', 'Yes {"user":"anna","password":"","nested":{"token":"t0","list":[1,2]},"n":5}');
        Observer.Expect('escaped_secret', 'Yes {"user":"anna","password":"a\"b\\c","nested":{"token":"t0","list":[1,2]},"n":5}');
        Observer.Expect('source_unchanged', '{"user":"anna","password":"placeholder","nested":{"token":"t0","list":[1,2]},"n":5}');
        Observer.Expect('invalid_path_ok', 'No');
        Observer.Expect('invalid_path_result', '{"user":"anna","password":"a\"b\\c","nested":{"token":"t0","list":[1,2]},"n":5}');
        Observer.Expect('double_dot_ok', 'No');
        Observer.Expect('double_dot_result', '{"user":"anna","password":"a\"b\\c","nested":{"token":"t0","list":[1,2]},"n":5}');
        Observer.Verify();
    end;

    [Test]
    procedure WriteWithSecretsTo_Dictionary()
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        Secrets: Dictionary of [Text, SecretText];
        Result: SecretText;
        Ok: Boolean;
    begin
        Load(O);
        Ok := O.WriteWithSecretsTo(Secrets, Result);
        Observer.Observe('empty_dictionary', Format(Ok) + ' ' + Plain(Result));
        Secrets.Add('password', Sec('pw'));
        Ok := O.WriteWithSecretsTo(Secrets, Result);
        Observer.Observe('one', Format(Ok) + ' ' + Plain(Result));
        Secrets.Add('nested.token', Sec('tk'));
        Secrets.Add('user', Sec('bob'));
        Ok := O.WriteWithSecretsTo(Secrets, Result);
        Observer.Observe('three', Format(Ok) + ' ' + Plain(Result));
        Secrets.Add('missing', Sec('zz'));
        Ok := O.WriteWithSecretsTo(Secrets, Result);
        Observer.Observe('with_missing_key_ok', Format(Ok));
        Observer.Observe('with_missing_key_result', Plain(Result));
        Clear(Secrets);
        Secrets.Add('$.n', Sec('77'));
        Ok := O.WriteWithSecretsTo(Secrets, Result);
        Observer.Observe('dollar_path', Format(Ok) + ' ' + Plain(Result));
        Observer.Observe('source_unchanged', Format(O));
        Clear(Secrets);
        Secrets.Add('bad[', Sec('x'));
        Ok := O.WriteWithSecretsTo(Secrets, Result);
        Observer.Observe('invalid_path_ok', Format(Ok));
        Observer.Observe('invalid_path_result', Plain(Result));
        Observer.Expect('empty_dictionary', 'Yes {"user":"anna","password":"placeholder","nested":{"token":"t0","list":[1,2]},"n":5}');
        Observer.Expect('one', 'Yes {"user":"anna","password":"pw","nested":{"token":"t0","list":[1,2]},"n":5}');
        Observer.Expect('three', 'Yes {"user":"bob","password":"pw","nested":{"token":"tk","list":[1,2]},"n":5}');
        Observer.Expect('with_missing_key_ok', 'No');
        Observer.Expect('with_missing_key_result', '{"user":"bob","password":"pw","nested":{"token":"tk","list":[1,2]},"n":5}');
        Observer.Expect('dollar_path', 'No {"user":"bob","password":"pw","nested":{"token":"tk","list":[1,2]},"n":5}');
        Observer.Expect('source_unchanged', '{"user":"anna","password":"placeholder","nested":{"token":"t0","list":[1,2]},"n":5}');
        Observer.Expect('invalid_path_ok', 'No');
        Observer.Expect('invalid_path_result', '{"user":"bob","password":"pw","nested":{"token":"tk","list":[1,2]},"n":5}');
        Observer.Verify();
    end;
}
