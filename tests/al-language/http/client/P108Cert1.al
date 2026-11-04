// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Fixtures used: Probe Observer (codeunit 69160)
// BC versions: 29 (27 and 28 by CI)

codeunit 72817 "LT P108 Http Cert Text"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    procedure P108_AddCertificateText()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Cert: Text;
        Pwd: Text;
    begin
        Cert := 'not a certificate';
        Pwd := 'pw';
        asserterror Client.AddCertificate(Cert, Pwd);
        Observer.ObserveError('garbage_with_password');
        asserterror Client.AddCertificate(Cert);
        Observer.ObserveError('garbage_no_password');
        Cert := '';
        asserterror Client.AddCertificate(Cert, Pwd);
        Observer.ObserveError('empty');
        Cert := 'MIIB';
        asserterror Client.AddCertificate(Cert, '');
        Observer.ObserveError('base64_stub');
        Observer.Expect('garbage_with_password|text', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('garbage_with_password|code', 'HttpRequest:Format');
        Observer.Expect('garbage_no_password|text', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('garbage_no_password|code', 'HttpRequest:Format');
        Observer.Expect('empty|text', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('empty|code', 'HttpRequest:Argument');
        Observer.Expect('base64_stub|text', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('base64_stub|code', 'HttpRequest:Cryptographic');
        Observer.Verify();
    end;
}
