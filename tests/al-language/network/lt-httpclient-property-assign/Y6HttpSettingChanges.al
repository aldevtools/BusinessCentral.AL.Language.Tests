// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunit 91311
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: what HttpClient keeps when UseServerCertificateValidation or UseResponseCookies is called (call form and property-assign form), split into a
//   call that changes the setting and one that keeps it: the Boolean the call answers, the Timeout, the base address and a default request header
//   added before the call. And that a request after each of these calls is blocked with the same error under TestHttpRequestPolicy =
//   BlockOutboundRequests. HttpClientServerCertificateValidation.al pins the call results of UseServerCertificateValidation on its own;
//   HttpClientPropertyAssign.al pins that the property-assign form with false resets a Timeout set before it.
// BC versions: 27, 28, 29
codeunit 91311 "LT Y6 Http Setting Changes"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    local procedure State(var Client: HttpClient): Text
    begin
        exit(Format(Client.Timeout()) + '|' + Client.GetBaseAddress() + '|' + Format(Client.DefaultRequestHeaders().Contains('X-Before')));
    end;

    local procedure Prepare(var Client: HttpClient)
    begin
        Client.Timeout := 5000;
        Client.SetBaseAddress('https://example.invalid/base/');
        Client.DefaultRequestHeaders().Add('X-Before', '1');
    end;

    [Test]
    procedure ServerCertificateValidation_CallForm_KeepAndChange()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Ok: Boolean;
    begin
        Prepare(Client);
        Ok := Client.UseServerCertificateValidation(true);
        Observer.Observe('true on fresh (keeps)', Format(Ok) + ' ' + State(Client));
        Prepare(Client);
        Ok := Client.UseServerCertificateValidation(false);
        Observer.Observe('false (changes)', Format(Ok) + ' ' + State(Client));
        Prepare(Client);
        Ok := Client.UseServerCertificateValidation(false);
        Observer.Observe('false again (keeps)', Format(Ok) + ' ' + State(Client));
        Prepare(Client);
        Ok := Client.UseServerCertificateValidation(true);
        Observer.Observe('true after false (changes)', Format(Ok) + ' ' + State(Client));
        Observer.Finish();
    end;

    [Test]
    procedure ServerCertificateValidation_PropertyAssign_KeepAndChange()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Prepare(Client);
        Client.UseServerCertificateValidation := true;
        Observer.Observe('true on fresh (keeps)', State(Client));
        Prepare(Client);
        Client.UseServerCertificateValidation := false;
        Observer.Observe('false (changes)', State(Client));
        Prepare(Client);
        Client.UseServerCertificateValidation := false;
        Observer.Observe('false again (keeps)', State(Client));
        Prepare(Client);
        Client.UseServerCertificateValidation := true;
        Observer.Observe('true after false (changes)', State(Client));
        Observer.Observe('call result after', Format(Client.UseServerCertificateValidation(true)));
        Observer.Finish();
    end;

    [Test]
    procedure ResponseCookies_KeepAndChange()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Prepare(Client);
        Client.UseResponseCookies(true);
        Observer.Observe('true on fresh', State(Client));
        Prepare(Client);
        Client.UseResponseCookies(false);
        Observer.Observe('false', State(Client));
        Prepare(Client);
        Client.UseResponseCookies(false);
        Observer.Observe('false again', State(Client));
        Prepare(Client);
        Client.UseResponseCookies := true;
        Observer.Observe('assign true after false', State(Client));
        Prepare(Client);
        Client.UseResponseCookies := true;
        Observer.Observe('assign true again', State(Client));
        Observer.Finish();
    end;

    [Test]
    procedure Timeout_AfterChangeThenSetAgain()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Client.UseServerCertificateValidation(false);
        Client.Timeout := 2000;
        Observer.Observe('set after false', Format(Client.Timeout()));
        Client.UseResponseCookies(false);
        Observer.Observe('after cookies false', Format(Client.Timeout()));
        Client.UseServerCertificateValidation(true);
        Observer.Observe('after validation true', Format(Client.Timeout()));
        Client.UseServerCertificateValidation(false);
        Observer.Observe('after validation false', Format(Client.Timeout()));
        Observer.Finish();
    end;

    [Test]
    procedure Request_AfterEachSetting_IsBlocked()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Other: HttpClient;
        Third: HttpClient;
        Resp: HttpResponseMessage;
        Ok: Boolean;
    begin
        Client.UseResponseCookies(false);
        asserterror Ok := Client.Get('https://example.invalid/', Resp);
        Observer.ObserveError('get after cookies false');
        Other.UseServerCertificateValidation(true);
        Other.Timeout := 1;
        asserterror Ok := Other.Get('https://example.invalid/', Resp);
        Observer.ObserveError('get after validation true and timeout 1');
        Third.UseServerCertificateValidation := false;
        Third.UseResponseCookies := true;
        Third.SetBaseAddress('https://example.invalid/base/');
        asserterror Ok := Third.Get('rel', Resp);
        Observer.ObserveError('relative get after both assigns');
        Observer.Finish();
    end;
}
