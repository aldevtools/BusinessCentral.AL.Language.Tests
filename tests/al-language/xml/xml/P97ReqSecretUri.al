// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httprequestmessage/httprequestmessage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: HttpRequestMessage SetSecretRequestUri and GetSecretRequestUri compared with SetRequestUri and GetRequestUri
// BC versions: 29 (27 and 28 by CI)

codeunit 74815 "LT P97 Req SecretUri"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Secret(Value: Text): SecretText
    var
        S: SecretText;
    begin
        S := SecretText.SecretStrSubstNo(Value);
        exit(S);
    end;

    [TryFunction]
    local procedure TrySetSecret(var Req: HttpRequestMessage; Value: Text; var Result: Boolean)
    begin
        Result := Req.SetSecretRequestUri(Secret(Value));
    end;

    [TryFunction]
    local procedure TrySetPlain(var Req: HttpRequestMessage; Value: Text; var Result: Boolean)
    begin
        Result := Req.SetRequestUri(Value);
    end;

    [TryFunction]
    local procedure TryGetSecret(var Req: HttpRequestMessage; var Result: Text)
    var
        S: SecretText;
    begin
        S := Req.GetSecretRequestUri();
        Result := Format(S.IsEmpty());
    end;

    [TryFunction]
    local procedure TryGetPlain(var Req: HttpRequestMessage; var Result: Text)
    begin
        Result := Req.GetRequestUri();
    end;

    local procedure Both(var Observer: Codeunit "Probe Observer"; Name: Text; var Req: HttpRequestMessage)
    var
        R: Text;
    begin
        if TryGetSecret(Req, R) then
            Observer.Observe(Name + '_secret', R)
        else
            Observer.ObserveError(Name + '_secret');
        if TryGetPlain(Req, R) then
            Observer.Observe(Name + '_plain', R)
        else
            Observer.ObserveError(Name + '_plain');
    end;

    [Test]
    procedure SecretUri_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        R: Boolean;
    begin
        Both(Observer, 'new', Req);
        if TrySetSecret(Req, 'https://example.invalid/a?token=1', R) then
            Observer.Observe('set_secret', Format(R))
        else
            Observer.ObserveError('set_secret');
        Both(Observer, 'after_secret', Req);
        Observer.Expect('new_secret', 'Yes');
        Observer.Expect('new_plain', '');
        Observer.Expect('set_secret', 'Yes');
        Observer.Expect('after_secret_secret', 'No');
        Observer.Expect('after_secret_plain', '');
        Observer.Verify();
    end;

    [Test]
    procedure PlainUri_ThenSecretGetter()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        R: Boolean;
    begin
        if TrySetPlain(Req, 'https://example.invalid/b?x=1', R) then
            Observer.Observe('set_plain', Format(R))
        else
            Observer.ObserveError('set_plain');
        Both(Observer, 'after_plain', Req);
        if TrySetSecret(Req, 'https://example.invalid/c', R) then
            Observer.Observe('set_secret_over_plain', Format(R))
        else
            Observer.ObserveError('set_secret_over_plain');
        Both(Observer, 'after_secret_over_plain', Req);
        if TrySetPlain(Req, 'https://example.invalid/d', R) then
            Observer.Observe('set_plain_over_secret', Format(R))
        else
            Observer.ObserveError('set_plain_over_secret');
        Both(Observer, 'after_plain_over_secret', Req);
        Observer.Expect('set_plain', 'Yes');
        Observer.Expect('after_plain_secret', 'No');
        Observer.Expect('after_plain_plain', 'https://example.invalid/b?x=1');
        Observer.Expect('set_secret_over_plain', 'Yes');
        Observer.Expect('after_secret_over_plain_secret', 'No');
        Observer.Expect('after_secret_over_plain_plain', '');
        Observer.Expect('set_plain_over_secret', 'Yes');
        Observer.Expect('after_plain_over_secret_secret', 'No');
        Observer.Expect('after_plain_over_secret_plain', 'https://example.invalid/d');
        Observer.Verify();
    end;

    [Test]
    procedure SecretUri_InvalidValues()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        R: Boolean;
    begin
        if TrySetSecret(Req, '', R) then
            Observer.Observe('empty', Format(R))
        else
            Observer.ObserveError('empty');
        Both(Observer, 'after_empty', Req);
        if TrySetSecret(Req, 'not a uri', R) then
            Observer.Observe('not_uri', Format(R))
        else
            Observer.ObserveError('not_uri');
        Both(Observer, 'after_not_uri', Req);
        if TrySetSecret(Req, '/relative/path', R) then
            Observer.Observe('relative', Format(R))
        else
            Observer.ObserveError('relative');
        Both(Observer, 'after_relative', Req);
        if TrySetSecret(Req, 'ftp://example.invalid/file', R) then
            Observer.Observe('ftp', Format(R))
        else
            Observer.ObserveError('ftp');
        Both(Observer, 'after_ftp', Req);
        Observer.Expect('empty', 'No');
        Observer.Expect('after_empty_secret', 'Yes');
        Observer.Expect('after_empty_plain', '');
        Observer.Expect('not_uri', 'No');
        Observer.Expect('after_not_uri_secret', 'Yes');
        Observer.Expect('after_not_uri_plain', '');
        Observer.Expect('relative', 'No');
        Observer.Expect('after_relative_secret', 'Yes');
        Observer.Expect('after_relative_plain', '');
        Observer.Expect('ftp', 'Yes');
        Observer.Expect('after_ftp_secret', 'No');
        Observer.Expect('after_ftp_plain', '');
        Observer.Verify();
    end;

    [Test]
    procedure SecretUri_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        R: Boolean;
    begin
        if TrySetSecret(Req, 'HTTPS://EXAMPLE.invalid:8443/Path x?a=b&c=d#frag', R) then
            Observer.Observe('mixed', Format(R))
        else
            Observer.ObserveError('mixed');
        Both(Observer, 'after_mixed', Req);
        if TrySetSecret(Req, 'https://user:pw@example.invalid/', R) then
            Observer.Observe('userinfo', Format(R))
        else
            Observer.ObserveError('userinfo');
        Both(Observer, 'after_userinfo', Req);
        if TrySetSecret(Req, 'https://example.invalid', R) then
            Observer.Observe('no_path', Format(R))
        else
            Observer.ObserveError('no_path');
        Both(Observer, 'after_no_path', Req);
        Observer.Expect('mixed', 'Yes');
        Observer.Expect('after_mixed_secret', 'No');
        Observer.Expect('after_mixed_plain', '');
        Observer.Expect('userinfo', 'Yes');
        Observer.Expect('after_userinfo_secret', 'No');
        Observer.Expect('after_userinfo_plain', '');
        Observer.Expect('no_path', 'Yes');
        Observer.Expect('after_no_path_secret', 'No');
        Observer.Expect('after_no_path_plain', '');
        Observer.Verify();
    end;

    [Test]
    procedure SecretUri_Method_Unchanged()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        R: Boolean;
    begin
        Req.Method('POST');
        if TrySetSecret(Req, 'https://example.invalid/m', R) then
            Observer.Observe('set', Format(R))
        else
            Observer.ObserveError('set');
        Observer.Observe('method', Req.Method());
        Observer.Expect('set', 'Yes');
        Observer.Expect('method', 'POST');
        Observer.Verify();
    end;
}
