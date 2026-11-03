// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Fixtures used: Probe Observer (codeunit 69160)
// BC versions: 29 (27 and 28 by CI)

codeunit 72818 "LT P108 Http Cert Secret"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    procedure P108_AddCertificateSecret()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Cert: SecretText;
        Pwd: SecretText;
    begin
        Cert := SecretStrSubstNo('not a certificate');
        Pwd := SecretStrSubstNo('pw');
        asserterror Client.AddCertificate(Cert, Pwd);
        Observer.ObserveError('garbage_with_password');
        asserterror Client.AddCertificate(Cert);
        Observer.ObserveError('garbage_no_password');
        Clear(Cert);
        asserterror Client.AddCertificate(Cert, Pwd);
        Observer.ObserveError('empty');
        Observer.Expect('garbage_with_password|text', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('garbage_with_password|code', 'HttpRequest:Format');
        Observer.Expect('garbage_no_password|text', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('garbage_no_password|code', 'HttpRequest:Format');
        Observer.Expect('empty|text', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('empty|code', 'HttpRequest:Argument');
        Observer.Verify();
    end;
}
