// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope (OnPrem app: UseDefaultNetworkWindowsAuthentication and UseWindowsAuthentication are Scope = OnPrem, must-not-compile cases 0651 to 0653)
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 61284
// Probe: written against BC 29 (runtime 16); the values are measured on the corpus CI service tiers.
// Facts: HttpClient.UseDefaultNetworkWindowsAuthentication, UseWindowsAuthentication (Text and SecretText): return values and errors
// BC versions: 27, 28, 29
codeunit 61284 "LT S Http Client Auth Config"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    local procedure Sec(Value: Text) Result: SecretText
    begin
        Result := Value;
    end;

    [Test]
    procedure UseDefaultNetworkWindowsAuthentication()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Ok: Boolean;
    begin
        Ok := Client.UseDefaultNetworkWindowsAuthentication();
        Observer.Observe('first', Format(Ok));
        Ok := Client.UseDefaultNetworkWindowsAuthentication();
        Observer.Observe('second', Format(Ok));
        Observer.Expect('first', 'Yes');
        Observer.Expect('second', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UseWindowsAuthentication_Text()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Ok: Boolean;
    begin
        Ok := Client.UseWindowsAuthentication('user', 'password', 'DOMAIN');
        Observer.Observe('with_domain', Format(Ok));
        Ok := Client.UseWindowsAuthentication('user', 'password');
        Observer.Observe('without_domain', Format(Ok));
        Ok := Client.UseWindowsAuthentication('', '', '');
        Observer.Observe('empty', Format(Ok));
        Observer.Expect('with_domain', 'Yes');
        Observer.Expect('without_domain', 'Yes');
        Observer.Expect('empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UseWindowsAuthentication_SecretText()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Ok: Boolean;
    begin
        Ok := Client.UseWindowsAuthentication(Sec('user'), Sec('password'), Sec('DOMAIN'));
        Observer.Observe('with_domain', Format(Ok));
        Ok := Client.UseWindowsAuthentication(Sec('user'), Sec('password'));
        Observer.Observe('without_domain', Format(Ok));
        Ok := Client.UseWindowsAuthentication(Sec(''), Sec(''), Sec(''));
        Observer.Observe('empty', Format(Ok));
        Observer.Expect('with_domain', 'Yes');
        Observer.Expect('without_domain', 'Yes');
        Observer.Expect('empty', 'Yes');
        Observer.Verify();
    end;
}

#if BC29PLUS
codeunit 61285 "LT S Http Client After Config"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowOutboundFromHandler;

    var
        Calls: Integer;

    [HttpClientHandler]
    procedure Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        Response.HttpStatusCode := 200;
        Response.Content.WriteFrom('reply ' + Format(Calls));
        exit(false);
    end;

    local procedure Sec(Value: Text) Result: SecretText
    begin
        Result := Value;
    end;

    local procedure Request(var Client: HttpClient): Text
    var
        Resp: HttpResponseMessage;
        Body: Text;
        Ok: Boolean;
    begin
        Ok := Client.Get('https://example.invalid/after-config', Resp);
        Resp.Content.ReadAs(Body);
        exit(Format(Ok) + ' ' + Format(Resp.HttpStatusCode) + ' [' + Body + ']');
    end;

    [Test]
    [HandlerFunctions('Handler')]
    procedure RequestAfterEachConfiguration()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Ok: Boolean;
    begin
        Calls := 0;
        Observer.Observe('plain', Request(Client));
        Ok := Client.UseServerCertificateValidation(false);
        Observer.Observe('after_certificate_validation_off', Request(Client));
        Ok := Client.UseServerCertificateValidation(true);
        Observer.Observe('after_certificate_validation_on', Request(Client));
        Ok := Client.UseDefaultNetworkWindowsAuthentication();
        Observer.Observe('after_default_network_auth', Request(Client));
        Ok := Client.UseWindowsAuthentication('user', 'password', 'DOMAIN');
        Observer.Observe('after_windows_auth_text', Request(Client));
        Ok := Client.UseWindowsAuthentication(Sec('user'), Sec('password'));
        Observer.Observe('after_windows_auth_secret', Request(Client));
        Observer.Observe('handler_calls', Format(Calls));
        Observer.Expect('plain', 'Yes 200 [reply 1]');
        Observer.Expect('after_certificate_validation_off', 'Yes 200 [reply 2]');
        Observer.Expect('after_certificate_validation_on', 'Yes 200 [reply 3]');
        Observer.Expect('after_default_network_auth', 'Yes 200 [reply 4]');
        Observer.Expect('after_windows_auth_text', 'Yes 200 [reply 5]');
        Observer.Expect('after_windows_auth_secret', 'Yes 200 [reply 6]');
        Observer.Expect('handler_calls', '6');
        Observer.Verify();
    end;
}
#endif
