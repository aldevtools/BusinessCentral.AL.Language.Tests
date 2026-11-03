// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient-mock-outbound-calls
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute is Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160), from the AL Language Coverage Tests app; self-contained codeunit 98940
// Probe: corpus issue #671 (odd AL behavior leads, part F) items 16, 17, 18, 19, 20, 21. Measured on the corpus CI service tiers. No request leaves the machine.
// Facts: what HttpClient answers when an [HttpClientHandler] marks the response unsuccessful, blocked by the environment, raises an error,
//        or sets 2xx/4xx/5xx status codes; Get with a base address, an absolute URL and an Authorization Bearer default header; which
//        RequestType a handler sees for custom and lower-case methods.
// BC versions: 29.0. On 27.5 and 28.5 a request is not given to the handler (PZHttpHandler.al, PZHttpBlock.al), so every test is BC29PLUS.
#if BC29PLUS
codeunit 98940 "LT DA Http Handler Odd"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowOutboundFromHandler;

    var
        StatusToSet: Integer;
        Seen: Text;

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

    [TryFunction]
    local procedure TryGet(Url: Text; var Resp: HttpResponseMessage; var Ok: Boolean)
    var
        Client: HttpClient;
    begin
        Ok := Client.Get(Url, Resp);
    end;

    [TryFunction]
    local procedure TryGetStatement(Url: Text; var Resp: HttpResponseMessage)
    var
        Client: HttpClient;
    begin
        Client.Get(Url, Resp);
    end;

    local procedure GetDescribed(Url: Text): Text
    var
        Resp: HttpResponseMessage;
        Ok: Boolean;
    begin
        ClearLastError();
        if TryGet(Url, Resp, Ok) then
            exit(Describe(Format(Ok), Resp));
        exit('E[' + GetLastErrorText() + '|' + GetLastErrorCode() + '] ' + Describe('-', Resp));
    end;

    local procedure GetStatementDescribed(Url: Text): Text
    var
        Resp: HttpResponseMessage;
    begin
        ClearLastError();
        if TryGetStatement(Url, Resp) then
            exit('no error ' + Describe('-', Resp));
        exit('E[' + GetLastErrorText() + '|' + GetLastErrorCode() + '] ' + Describe('-', Resp));
    end;

    [HttpClientHandler]
    procedure UnsuccessfulHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.IsSuccessfulRequest := false;
        Response.Content.WriteFrom('unsuccessful body');
        exit(false);
    end;

    [HttpClientHandler]
    procedure BlockedHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.IsBlockedByEnvironment := true;
        exit(false);
    end;

    [HttpClientHandler]
    procedure BlockedUnsuccessfulHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.IsBlockedByEnvironment := true;
        Response.IsSuccessfulRequest := false;
        exit(false);
    end;

    [HttpClientHandler]
    procedure ErrorHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Error('LT DA handler failed');
    end;

    [HttpClientHandler]
    procedure StatusHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Seen += Format(Request.RequestType) + ' [' + Request.Path + '];';
        Response.HttpStatusCode := StatusToSet;
        exit(false);
    end;

    [Test]
    [HandlerFunctions('UnsuccessfulHandler')]
    procedure Handler_UnsuccessfulRequest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get', GetDescribed('https://example.invalid/unsuccessful'));
        Observer.Observe('statement', GetStatementDescribed('https://example.invalid/unsuccessful'));
        Observer.Expect('get', 'ok=No status=200 reason=[OK] success=Yes blocked=No read=Yes body=[unsuccessful body] keys=0');
        Observer.Expect('statement', 'no error ok=- status=200 reason=[OK] success=Yes blocked=No read=Yes body=[unsuccessful body] keys=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BlockedHandler')]
    procedure Handler_BlockedByEnvironment()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get', GetDescribed('https://example.invalid/blocked'));
        Observer.Observe('statement', GetStatementDescribed('https://example.invalid/blocked'));
        Observer.Expect('get', 'ok=Yes status=200 reason=[OK] success=Yes blocked=Yes read=Yes body=[] keys=0');
        Observer.Expect('statement', 'no error ok=- status=200 reason=[OK] success=Yes blocked=Yes read=Yes body=[] keys=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BlockedUnsuccessfulHandler')]
    procedure Handler_BlockedAndUnsuccessful()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get', GetDescribed('https://example.invalid/blocked2'));
        Observer.Observe('statement', GetStatementDescribed('https://example.invalid/blocked2'));
        Observer.Expect('get', 'ok=No status=200 reason=[OK] success=Yes blocked=Yes read=Yes body=[] keys=0');
        Observer.Expect('statement', 'no error ok=- status=200 reason=[OK] success=Yes blocked=Yes read=Yes body=[] keys=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ErrorHandler')]
    procedure Handler_RaisesError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('get', GetDescribed('https://example.invalid/error'));
        Observer.Expect('get', 'E[LT DA handler failed|Dialog] ok=- status=200 reason=[OK] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('StatusHandler')]
    procedure Handler_StatusCodes()
    var
        Observer: Codeunit "Probe Observer";
        Codes: List of [Integer];
        Code: Integer;
    begin
        Codes.Add(200);
        Codes.Add(201);
        Codes.Add(204);
        Codes.Add(299);
        Codes.Add(301);
        Codes.Add(304);
        Codes.Add(400);
        Codes.Add(404);
        Codes.Add(500);
        Codes.Add(99);
        Codes.Add(600);
        foreach Code in Codes do begin
            StatusToSet := Code;
            Observer.Observe(Format(Code), GetDescribed('https://example.invalid/status'));
        end;
        Observer.Expect('200', 'ok=Yes status=200 reason=[OK] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Expect('201', 'ok=Yes status=201 reason=[Created] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Expect('204', 'ok=Yes status=204 reason=[No Content] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Expect('299', 'E[The value ''299'' is not a valid HTTP status code.|InvalidValue] ok=- status=200 reason=[OK] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Expect('301', 'E[The value ''301'' is outside the allowed range for mocked HTTP status codes. Redirect (3**) status codes are not permitted.|InvalidValue] ok=- status=200 reason=[OK] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Expect('304', 'E[The value ''304'' is outside the allowed range for mocked HTTP status codes. Redirect (3**) status codes are not permitted.|InvalidValue] ok=- status=200 reason=[OK] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Expect('400', 'ok=Yes status=400 reason=[Bad Request] success=No blocked=No read=Yes body=[] keys=0');
        Observer.Expect('404', 'ok=Yes status=404 reason=[Not Found] success=No blocked=No read=Yes body=[] keys=0');
        Observer.Expect('500', 'ok=Yes status=500 reason=[Internal Server Error] success=No blocked=No read=Yes body=[] keys=0');
        Observer.Expect('99', 'E[The value ''99'' is not a valid HTTP status code.|InvalidValue] ok=- status=200 reason=[OK] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Expect('600', 'E[The value ''600'' is not a valid HTTP status code.|InvalidValue] ok=- status=200 reason=[OK] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('StatusHandler')]
    procedure Handler_BaseAddressAbsoluteUrlBearer()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Ok: Boolean;
    begin
        StatusToSet := 200;
        Seen := '';
        Client.SetBaseAddress('https://example.invalid/api/');
        Client.DefaultRequestHeaders.Add('Authorization', 'Bearer eyJhbGciOiJIUzI1NiJ9.e30.abc');
        Ok := Client.Get('https://example.invalid/api/items', Resp);
        Observer.Observe('absolute', Describe(Format(Ok), Resp));
        Ok := Client.Get('items?x=1', Resp);
        Observer.Observe('relative', Describe(Format(Ok), Resp));
        Observer.Observe('seen', Seen);
        Observer.Expect('absolute', 'ok=Yes status=200 reason=[OK] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Expect('relative', 'ok=Yes status=200 reason=[OK] success=Yes blocked=No read=Yes body=[] keys=0');
        Observer.Expect('seen', 'Get [https://example.invalid/api/items];Get [https://example.invalid/api/items];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('StatusHandler')]
    procedure Handler_CustomMethods()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
        Methods: List of [Text];
        M: Text;
        Ok: Boolean;
    begin
        StatusToSet := 200;
        Methods.Add('FOO');
        Methods.Add('TRACE');
        Methods.Add('OPTIONS');
        Methods.Add('HEAD');
        Methods.Add('get');
        Methods.Add('Post');
        foreach M in Methods do begin
            Clear(Req);
            Seen := '';
            Req.Method := M;
            Req.SetRequestUri('https://example.invalid/method');
            ClearLastError();
            if TrySend(Client, Req, Resp, Ok) then
                Observer.Observe(M, 'ok=' + Format(Ok) + ' seen=' + Seen)
            else
                Observer.Observe(M, 'E[' + GetLastErrorText() + '|' + GetLastErrorCode() + '] seen=' + Seen);
        end;
        Observer.Expect('FOO', 'ok=Yes seen=Unknown [https://example.invalid/method];');
        Observer.Expect('TRACE', 'ok=Yes seen=Trace [https://example.invalid/method];');
        Observer.Expect('OPTIONS', 'ok=Yes seen=Options [https://example.invalid/method];');
        Observer.Expect('HEAD', 'ok=Yes seen=Head [https://example.invalid/method];');
        Observer.Expect('get', 'ok=Yes seen=Get [https://example.invalid/method];');
        Observer.Expect('Post', 'ok=Yes seen=Post [https://example.invalid/method];');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySend(var Client: HttpClient; var Req: HttpRequestMessage; var Resp: HttpResponseMessage; var Ok: Boolean)
    begin
        Ok := Client.Send(Req, Resp);
    end;
}
#endif
