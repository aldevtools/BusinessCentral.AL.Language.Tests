// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 85600
// Leads: corpus issue #671 (Http Content codeunit Create(SecretText); DefaultRequestHeaders reference kept across UseServerCertificateValidation).
// No request leaves the machine (TestHttpRequestPolicy = BlockOutboundRequests).
// Probe: measured on a local BC 29.0 service tier, then on the corpus CI legs.
// Facts:
//  - Codeunit "Http Content".Create(SecretText) and Create(SecretText; ContentType) do not raise (the lead's 'Invalid HTTP header' does not happen):
//    the content is secret content, not empty, and its Content-Type is text/plain (or the given type; '' gives text/plain).
//  - UseServerCertificateValidation(false) detaches an HttpHeaders taken earlier from DefaultRequestHeaders: headers added through the old
//    reference no longer reach the client (CzHttpOutbound.al EchoedRequestHeaders shows they are not sent either). A reference taken after the
//    call, and UseServerCertificateValidation(true), keep the link.
// BC versions: 27, 28, 29
codeunit 85600 "LT CZ Http No Network"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    local procedure Sec(Value: Text) Result: SecretText
    begin
        Result := Value;
    end;

    local procedure DescribeContent(Content: HttpContent): Text
    var
        Headers: HttpHeaders;
        Values: List of [Text];
        Body: Text;
        CT: Text;
        SecretBody: SecretText;
    begin
        if Content.IsSecretContent() then begin
            Content.ReadAs(SecretBody);
            Body := '<secret empty=' + Format(SecretBody.IsEmpty()) + '>';
        end else
            Content.ReadAs(Body);
        Content.GetHeaders(Headers);
        if Headers.GetValues('Content-Type', Values) then
            CT := Values.Get(1);
        exit('body=[' + Body + '] type=[' + CT + '] secret=' + Format(Content.IsSecretContent()));
    end;

    [TryFunction]
    local procedure TryCreateSecret(Value: SecretText; var Result: Text)
    var
        HttpContent: Codeunit "Http Content";
    begin
        Result := DescribeContent(HttpContent.Create(Value).GetHttpContent());
    end;

    [TryFunction]
    local procedure TryCreateSecretWithType(Value: SecretText; ContentType: Text; var Result: Text)
    var
        HttpContent: Codeunit "Http Content";
    begin
        Result := DescribeContent(HttpContent.Create(Value, ContentType).GetHttpContent());
    end;

    [Test]
    procedure HttpContentCodeunit_CreateFromSecretText()
    var
        Observer: Codeunit "Probe Observer";
        HttpContent: Codeunit "Http Content";
        Result: Text;
    begin
        Observer.Observe('secret_ok', Format(TryCreateSecret(Sec('test'), Result)));
        Observer.Observe('secret_result', Result);
        Observer.ObserveError('secret_err');
        Result := '';
        Observer.Observe('secret_type_ok', Format(TryCreateSecretWithType(Sec('test'), 'application/json', Result)));
        Observer.Observe('secret_type_result', Result);
        Observer.ObserveError('secret_type_err');
        Result := '';
        Observer.Observe('secret_type_empty_ok', Format(TryCreateSecretWithType(Sec('test'), '', Result)));
        Observer.Observe('secret_type_empty_result', Result);
        Observer.ObserveError('secret_type_empty_err');
        Observer.Observe('text', DescribeContent(HttpContent.Create('test').GetHttpContent()));
        Observer.Expect('secret_ok', 'Yes');
        Observer.Expect('secret_result', 'body=[<secret empty=No>] type=[text/plain] secret=Yes');
        Observer.Expect('secret_err|text', '');
        Observer.Expect('secret_err|code', '');
        Observer.Expect('secret_type_ok', 'Yes');
        Observer.Expect('secret_type_result', 'body=[<secret empty=No>] type=[application/json] secret=Yes');
        Observer.Expect('secret_type_err|text', '');
        Observer.Expect('secret_type_err|code', '');
        Observer.Expect('secret_type_empty_ok', 'Yes');
        Observer.Expect('secret_type_empty_result', 'body=[<secret empty=No>] type=[text/plain] secret=Yes');
        Observer.Expect('secret_type_empty_err|text', '');
        Observer.Expect('secret_type_empty_err|code', '');
        Observer.Expect('text', 'body=[test] type=[text/plain] secret=No');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultRequestHeaders_ReferenceLost_AfterValidationOff()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Headers: HttpHeaders;
        Other: HttpHeaders;
    begin
        Headers := Client.DefaultRequestHeaders();
        Client.UseServerCertificateValidation(false);
        Headers.Add('X-Test', '1');
        Observer.Observe('client_sees_after_false', Format(Client.DefaultRequestHeaders().Contains('X-Test')));
        Observer.Observe('ref_sees', Format(Headers.Contains('X-Test')));
        Other := Client.DefaultRequestHeaders();
        Client.UseServerCertificateValidation(true);
        Other.Add('X-Two', '2');
        Observer.Observe('client_sees_after_true', Format(Client.DefaultRequestHeaders().Contains('X-Two')));
        Observer.Observe('client_keeps_first', Format(Client.DefaultRequestHeaders().Contains('X-Test')));
        Observer.Observe('keys', Format(Client.DefaultRequestHeaders().Keys().Count()));
        Observer.Expect('client_sees_after_false', 'No');
        Observer.Expect('ref_sees', 'Yes');
        Observer.Expect('client_sees_after_true', 'Yes');
        Observer.Expect('client_keeps_first', 'No');
        Observer.Expect('keys', '1');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultRequestHeaders_Reference_ValidationTrueOnFreshClient()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Headers: HttpHeaders;
    begin
        Headers := Client.DefaultRequestHeaders();
        Client.UseServerCertificateValidation(true);
        Headers.Add('X-Test', '1');
        Observer.Observe('client_sees_after_true', Format(Client.DefaultRequestHeaders().Contains('X-Test')));
        Headers := Client.DefaultRequestHeaders();
        Client.UseServerCertificateValidation(false);
        Client.UseServerCertificateValidation(false);
        Headers.Add('X-Again', '1');
        Observer.Observe('client_sees_after_false_twice', Format(Client.DefaultRequestHeaders().Contains('X-Again')));
        Client.DefaultRequestHeaders().Add('X-Direct', '1');
        Observer.Observe('direct_add_after_false', Format(Client.DefaultRequestHeaders().Contains('X-Direct')));
        Observer.Expect('client_sees_after_true', 'Yes');
        Observer.Expect('client_sees_after_false_twice', 'No');
        Observer.Expect('direct_add_after_false', 'Yes');
        Observer.Verify();
    end;
}
