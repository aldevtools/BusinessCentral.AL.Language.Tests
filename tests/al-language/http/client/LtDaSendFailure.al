// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpclient/httpclient-send-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunits 85660 and 85661
// Probe: corpus issue #671 (odd AL behavior leads, part F) items 16, 18, 21, 22. Measured on the corpus CI service tiers.
// Facts: a real request to a name that never resolves (lt-da.invalid): the Boolean of Get and Send, the state of the HttpResponseMessage after it,
//        the error when the Boolean is not used, a custom method on Send, and TestHttpRequestPolicy = AllowAllOutboundRequests.
// BC versions: 28, 29. On 27.5 the CI service tier asks the outbound-request approval prompt (StrMenu 'Allow Always,Allow Once,Block Always,Block Once')
//   before the request: with the Boolean used Get answers false with a default response (status 200), as a statement it raises
//   'Unhandled UI: StrMenu ...'. That is a setting of the tier (Allow HttpClient Requests), not the HttpClient behavior asked here, so the tests are BC28PLUS.
// The asserted values match Windows BC 28.5 and 29.0 (Windows runs 2026-10-20, all six tests passed). They were held on Linux under
//   bc-linux #165 (LT_HELD_BCLINUX_165) while the image showed the approval StrMenu or returned status 200 OK for the .invalid host
//   (PR run 39475237141); the hold is lifted with the bc-linux pin bcc60c1c (corpus bump 42), which answers that prompt.
#if BC28PLUS
codeunit 85660 "LT DA Send Failure"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(OkText: Text; var Resp: HttpResponseMessage): Text
    var
        Body: Text;
        ReadOk: Boolean;
    begin
        Body := 'preset';
        ReadOk := TryRead(Resp, Body);
        exit('ok=' + OkText + ' status=' + Format(Resp.HttpStatusCode) + ' reason=[' + Resp.ReasonPhrase + '] success=' + Format(Resp.IsSuccessStatusCode) +
          ' blocked=' + Format(Resp.IsBlockedByEnvironment) + ' read=' + Format(ReadOk) + ' body=[' + Body + '] keys=' + Format(Resp.Headers.Keys().Count()));
    end;

    [TryFunction]
    local procedure TryRead(var Resp: HttpResponseMessage; var Body: Text)
    begin
        Resp.Content.ReadAs(Body);
    end;

    [Test]
    procedure Get_UnresolvableHost_ReturnsFalse()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Client.Get('https://lt-da.invalid/get', Resp);
        Observer.Observe('get', Describe(Format(Ok), Resp));
        Observer.Observe('lastError', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('get', 'ok=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No read=Yes body=[] keys=0');
        Observer.Expect('lastError', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.|HttpRequest:Socket');
        Observer.Verify();
    end;

    [Test]
    procedure Send_UnresolvableHost_ReturnsFalse()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
        Ok: Boolean;
    begin
        ClearLastError();
        Req.SetRequestUri('https://lt-da.invalid/send');
        Req.Method := 'POST';
        Req.Content.WriteFrom('body');
        Ok := Client.Send(Req, Resp);
        Observer.Observe('send', Describe(Format(Ok), Resp));
        Observer.Observe('lastError', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('send', 'ok=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No read=Yes body=[] keys=0');
        Observer.Expect('lastError', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.|HttpRequest:Socket');
        Observer.Verify();
    end;

    [Test]
    procedure Get_UnusedReturnValue_RaisesError()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Resp: HttpResponseMessage;
    begin
        asserterror Client.Get('https://lt-da.invalid/statement', Resp);
        Observer.ObserveError('get');
        Observer.Observe('after', Describe('-', Resp));
        Observer.Expect('get|text', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('get|code', 'HttpRequest:Socket');
        Observer.Expect('after', 'ok=- status=0 reason=[NavHttpClient Request Failed] success=No blocked=No read=Yes body=[] keys=0');
        Observer.Verify();
    end;

    [Test]
    procedure Send_UnusedReturnValue_RaisesError()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
    begin
        Req.SetRequestUri('https://lt-da.invalid/statement');
        asserterror Client.Send(Req, Resp);
        Observer.ObserveError('send');
        Observer.Observe('after', Describe('-', Resp));
        Observer.Expect('send|text', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('send|code', 'HttpRequest:Socket');
        Observer.Expect('after', 'ok=- status=0 reason=[NavHttpClient Request Failed] success=No blocked=No read=Yes body=[] keys=0');
        Observer.Verify();
    end;

    [Test]
    procedure Send_CustomMethods_UnresolvableHost()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
        Methods: List of [Text];
        M: Text;
        Ok: Boolean;
    begin
        Methods.Add('FOO');
        Methods.Add('TRACE');
        Methods.Add('OPTIONS');
        Methods.Add('HEAD');
        Methods.Add('get');
        foreach M in Methods do begin
            Clear(Req);
            Clear(Resp);
            ClearLastError();
            Req.Method := M;
            Req.SetRequestUri('https://lt-da.invalid/method');
            Ok := Client.Send(Req, Resp);
            Observer.Observe(M, Describe(Format(Ok), Resp) + ' method=' + Req.Method + ' err=' + GetLastErrorText());
        end;
        Observer.Expect('FOO', 'ok=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No read=Yes body=[] keys=0 method=FOO err=There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('TRACE', 'ok=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No read=Yes body=[] keys=0 method=TRACE err=There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('OPTIONS', 'ok=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No read=Yes body=[] keys=0 method=OPTIONS err=There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('HEAD', 'ok=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No read=Yes body=[] keys=0 method=HEAD err=There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('get', 'ok=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No read=Yes body=[] keys=0 method=get err=There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Verify();
    end;
}
#endif

#if BC28PLUS
codeunit 85661 "LT DA Policy AllowAll"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowAllOutboundRequests;

    [Test]
    procedure AllowAll_UnresolvableHost_IsSentForReal()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Client.Get('https://lt-da.invalid/allow-all', Resp);
        Observer.Observe('get', 'ok=' + Format(Ok) + ' status=' + Format(Resp.HttpStatusCode) + ' success=' + Format(Resp.IsSuccessStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment));
        Observer.Observe('lastError', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('get', 'ok=No status=0 success=No blocked=No');
        Observer.Expect('lastError', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.|HttpRequest:Socket');
        Observer.Verify();
    end;
}
#endif
