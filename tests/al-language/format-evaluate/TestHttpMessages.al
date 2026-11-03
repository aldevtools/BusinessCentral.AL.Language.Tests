// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testhttprequestmessage/testhttprequestmessage-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// TestHttpRequestMessage and TestHttpResponseMessage members usable without a handler (compile errors here are expected to be fixed by the lead).
// Fixtures used: Probe Observer (codeunit 69160)
// BC versions: 29 (27 and 28 by CI)

codeunit 72027 "LT HtT Test Messages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure FreshTestRequest()
    var
        Req: TestHttpRequestMessage;
    begin
        Observer.Observe('path', '[' + Req.Path + ']');
        Observer.Observe('queryCount', Format(Req.QueryParameters.Count()));
        Observer.Observe('secretUri', Format(Req.HasSecretUri));
        Observer.Expect('path', '[]');
        Observer.Expect('queryCount', '0');
        Observer.Expect('secretUri', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TestRequestQueryParameters()
    var
        Req: TestHttpRequestMessage;
    begin
        Req.QueryParameters.Add('a', '1');
        Observer.Observe('count', Format(Req.QueryParameters.Count()));
        Observer.Observe('a', Req.QueryParameters.Get('a'));
        Observer.Observe('hasB', Format(Req.QueryParameters.ContainsKey('b')));
        Observer.Expect('count', '1');
        Observer.Expect('a', '1');
        Observer.Expect('hasB', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure FreshTestResponse()
    var
        Resp: TestHttpResponseMessage;
    begin
        Observer.Observe('status', Format(Resp.HttpStatusCode));
        Observer.Observe('reason', '[' + Resp.ReasonPhrase + ']');
        Observer.Observe('success', Format(Resp.IsSuccessfulRequest));
        Observer.Observe('blocked', Format(Resp.IsBlockedByEnvironment));
        Observer.Expect('status', '200');
        Observer.Expect('reason', '[OK]');
        Observer.Expect('success', 'Yes');
        Observer.Expect('blocked', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TestResponseContentAndHeaders()
    var
        Resp: TestHttpResponseMessage;
        Txt: Text;
    begin
        Resp.Content.WriteFrom('body');
        Resp.Content.ReadAs(Txt);
        Observer.Observe('text', Txt);
        Observer.Observe('keys', Format(Resp.Headers.Keys().Count()));
        Resp.Headers.Add('X-R', 'v');
        Observer.Observe('contains', Format(Resp.Headers.Contains('X-R')));
        Observer.Expect('text', 'body');
        Observer.Expect('keys', '0');
        Observer.Expect('contains', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TestResponseSetStatus()
    var
        Resp: TestHttpResponseMessage;
    begin
        Resp.HttpStatusCode := 404;
        Resp.ReasonPhrase := 'Not Found';
        Observer.Observe('status', Format(Resp.HttpStatusCode));
        Observer.Observe('reason', Resp.ReasonPhrase);
        Observer.Observe('success', Format(Resp.IsSuccessfulRequest));
        Resp.HttpStatusCode := 204;
        Observer.Observe('success204', Format(Resp.IsSuccessfulRequest));
        Observer.Expect('status', '404');
        Observer.Expect('reason', 'Not Found');
        Observer.Expect('success', 'Yes');
        Observer.Expect('success204', 'Yes');
        Observer.Verify();
    end;
}
