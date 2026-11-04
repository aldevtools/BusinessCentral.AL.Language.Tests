// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-useservercertificatevalidation-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 68580
// Probe: written against BC 29 (runtime 16); the values are measured on the corpus CI service tiers.
// Facts: HttpClient.UseServerCertificateValidation(Boolean): return value and no error for true and false, repeated and on a fresh client
// BC versions: 27, 28, 29
codeunit 68580 "LT S Http Server Cert"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    procedure UseServerCertificateValidation_TrueAndFalse()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Other: HttpClient;
        Ok: Boolean;
    begin
        Ok := Client.UseServerCertificateValidation(true);
        Observer.Observe('true', Format(Ok));
        Ok := Client.UseServerCertificateValidation(false);
        Observer.Observe('false', Format(Ok));
        Ok := Client.UseServerCertificateValidation(true);
        Observer.Observe('true_again', Format(Ok));
        Ok := Client.UseServerCertificateValidation(false);
        Ok := Client.UseServerCertificateValidation(false);
        Observer.Observe('false_twice', Format(Ok));
        Ok := Other.UseServerCertificateValidation(false);
        Observer.Observe('second_client', Format(Ok));
        Observer.Expect('true', 'Yes');
        Observer.Expect('false', 'No');
        Observer.Expect('true_again', 'Yes');
        Observer.Expect('false_twice', 'No');
        Observer.Expect('second_client', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure UseServerCertificateValidation_RequestIsStillBlocked()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Ok: Boolean;
    begin
        Ok := Client.UseServerCertificateValidation(false);
        asserterror Ok := Client.Get('https://example.invalid/', Resp);
        Observer.ObserveError('get_after_validation_off');
        Observer.Expect('get_after_validation_off|text', 'Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.');
        Observer.Expect('get_after_validation_off|code', 'TestCodeunitUnhandledHttpRequest');
        Observer.Verify();
    end;
}
