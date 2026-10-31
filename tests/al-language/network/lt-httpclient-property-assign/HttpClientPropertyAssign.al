// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunit 91220
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the property-assign form Client.<Member> := Value for HttpClient members that take one Boolean (UseServerCertificateValidation, UseResponseCookies),
//   with a literal, a variable, a negated expression and a field of a record on the right; the same form with Timeout is pinned in network/lt-http/HttpClient.al.
//   What the member answers afterwards in its call form, and that a request on a client with the setting still obeys the request policy of the test.
// BC versions: 27, 28, 29
codeunit 91220 "LT SC HttpClient Prop Assign"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    procedure UseServerCertificateValidation_PropertyAssign()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Flag: Boolean;
        Resp: HttpResponseMessage;
        Ok: Boolean;
    begin
        Client.UseServerCertificateValidation := false;
        Observer.Observe('after false literal', Format(Client.UseServerCertificateValidation(false)));
        Client.UseServerCertificateValidation := true;
        Observer.Observe('after true literal', Format(Client.UseServerCertificateValidation(true)));
        Flag := false;
        Client.UseServerCertificateValidation := Flag;
        Observer.Observe('after variable', 'no error');
        Client.UseServerCertificateValidation := not Flag;
        Observer.Observe('after negated variable', 'no error');
        Client.UseServerCertificateValidation := false;
        asserterror Ok := Client.Get('https://example.invalid/', Resp);
        Observer.ObserveError('get after assign');
        Observer.Expect('after false literal', 'No');
        Observer.Expect('after true literal', 'Yes');
        Observer.Expect('after variable', 'no error');
        Observer.Expect('after negated variable', 'no error');
        Observer.Expect('get after assign|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('get after assign|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Verify();
    end;

    [Test]
    procedure UseResponseCookies_PropertyAssign()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Client.UseResponseCookies := false;
        Observer.Observe('false', 'no error');
        Client.UseResponseCookies := true;
        Observer.Observe('true', 'no error');
        Client.UseResponseCookies(false);
        Observer.Observe('call form', 'no error');
        Observer.Expect('false', 'no error');
        Observer.Expect('true', 'no error');
        Observer.Expect('call form', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure PropertyAssign_ValueFromTableField()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Setup: Record "Company Information";
    begin
        Setup.Init();
        Client.UseServerCertificateValidation := not Setup."Allow Blank Payment Info.";
        Observer.Observe('from field', 'no error');
        Client.Timeout := 5000;
        Client.UseServerCertificateValidation := false;
        Observer.Observe('timeout kept', Format(Client.Timeout()));
        Observer.Expect('from field', 'no error');
        Observer.Expect('timeout kept', '1 minute 40 seconds');
        Observer.Verify();
    end;
}
