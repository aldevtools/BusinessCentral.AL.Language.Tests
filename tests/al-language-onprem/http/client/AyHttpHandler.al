// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient-mock-outbound-calls
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute and TestHttpRequestMessage / TestHttpResponseMessage are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; own codeunit 98550
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: the Request.Path an [HttpClientHandler] sees for HttpClient.SetBaseAddress('https://example.invalid/api/v1/') followed by Get of 'orders',
// '/orders', '../x' and '?q=1', and for Get without a base address of 'a/b', 'a.b' and '?q=1'; a handler that sets only status 404 (reason phrase,
// IsSuccessStatusCode, the Boolean of Get); a handler that raises an error (what the caller sees); a handler that answers true (fall through to the
// real network) for a host that resolves but refuses the connection (http://localhost:1): the Boolean, the status code and GetLastErrorText.
// On the Linux images of BC 27 and 28 a request is not given to the handler; Windows 27.5 and 28.5 give it to the handler, the same as BC 29
// (Windows check 2026-10-22; Linux suspect, bc-linux issue 192). So the tests that reach a handler assert on BC 29 only.
// Writer PY (2026-10-20, tests PY_*): a handler answering true with a StrMenuHandler bound (Allow Once, Block Once, cancel), a failed call whose
// result is not used, a failed call into a filled response, ReasonPhrase of mocked statuses, more base-address joins and paths without one.
// BC versions: 27, 28, 29 (corpus CI); handler values asserted on 29 only (see above).
// No outbound-request approval prompt (StrMenu Allow Always/Allow Once/Block Always/Block Once) appears (bc-linux bcc60c1c; a Windows container
// never shows it, bc-linux 05752c9 #165). So no test binds a StrMenuHandler: a prompt would surface as 'Unhandled UI' in last_error, and
// menu=0 in 'calls' records that none was answered. The *_StrMenuAllowOnce/_StrMenuBlockOnce/_StrMenuCancel tests keep their names and the
// choice they would give; they now pin that the request runs the same as without a menu. Values: corpus CI on bc-linux bcc60c1c (27.5, 28.5,
// 29.0); earlier images showed the prompt and the old values (status 200 OK / Unhandled UI / Block Once = status 400) were Linux-only.

codeunit 98550 "LT AY Http Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowOutboundFromHandler;

    var
        Seen: Text;
        Calls: Integer;
        Mode: Text;
        NextStatus: Integer;
        MenuChoice: Integer;
        MenuCalls: Integer;
        MenuSeen: Text;

    [HttpClientHandler]
    procedure PathHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Params: Dictionary of [Text, Text];
        ParamName: Text;
    begin
        Calls += 1;
        Seen += '[' + Request.Path + ']';
        Params := Request.QueryParameters;
        foreach ParamName in Params.Keys() do
            Seen += ParamName + '=' + Params.Get(ParamName) + '&';
        Response.HttpStatusCode := 200;
        exit(false);
    end;

    [HttpClientHandler]
    procedure NotFoundHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        Response.HttpStatusCode := 404;
        exit(false);
    end;

    [HttpClientHandler]
    procedure ErrorHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        Error('handler failed');
    end;

    [HttpClientHandler]
    procedure FallThroughHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        Response.HttpStatusCode := 202;
        exit(true);
    end;

    [TryFunction]
    local procedure TryGet(var Client: HttpClient; Url: Text; var Resp: HttpResponseMessage; var Ret: Boolean)
    begin
        Ret := Client.Get(Url, Resp);
    end;

    local procedure Path(var Observer: Codeunit "Probe Observer"; var Client: HttpClient; ObsKey: Text; Url: Text)
    var
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Seen := '';
        ClearLastError();
        if TryGet(Client, Url, Resp, Ret) then
            Observer.Observe(ObsKey, Format(Ret) + ' ' + Seen)
        else
            Observer.Observe(ObsKey, 'E[' + CopyStr(GetLastErrorText(), 1, 70) + '|' + GetLastErrorCode() + '] ' + Seen);
    end;

    local procedure Outcome(var Observer: Codeunit "Probe Observer"; Url: Text)
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Calls := 0;
        ClearLastError();
        if TryGet(Client, Url, Resp, Ret) then
            Observer.Observe('result', 'ret=' + Format(Ret) + ' status=' + Format(Resp.HttpStatusCode) + ' reason=[' + Resp.ReasonPhrase + '] success=' + Format(Resp.IsSuccessStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment))
        else
            Observer.Observe('result', 'error status=' + Format(Resp.HttpStatusCode));
        Observer.Observe('last_error', GetLastErrorText());
        Observer.Observe('last_code', GetLastErrorCode());
        Observer.Observe('calls', Format(Calls));
    end;

    [Test]
    [HandlerFunctions('PathHandler')]
    procedure BaseAddress_RelativePaths_1()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Client.SetBaseAddress('https://example.invalid/api/v1/');
        Path(Observer, Client, 'plain', 'orders');
        Path(Observer, Client, 'rooted', '/orders');
#if BC29PLUS
        Observer.Expect('plain', 'Yes [https://example.invalid/api/v1/orders]');
        Observer.Expect('rooted', 'Yes [https://example.invalid/orders]');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('PathHandler')]
    procedure BaseAddress_RelativePaths_2()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Client.SetBaseAddress('https://example.invalid/api/v1/');
        Path(Observer, Client, 'parent', '../x');
        Path(Observer, Client, 'query', '?q=1');
#if BC29PLUS
        Observer.Expect('parent', 'Yes [https://example.invalid/api/x]');
        Observer.Expect('query', 'Yes [https://example.invalid/api/v1/]q=1&');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('PathHandler')]
    procedure NoBaseAddress_RelativePaths_1()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Path(Observer, Client, 'a_slash_b', 'a/b');
        Path(Observer, Client, 'a_dot_b', 'a.b');
#if BC29PLUS
        Observer.Expect('a_slash_b', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Expect('a_dot_b', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('PathHandler')]
    procedure NoBaseAddress_RelativePaths_2()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
    begin
        Path(Observer, Client, 'query', '?q=1');
#if BC29PLUS
        Observer.Expect('query', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('NotFoundHandler')]
    procedure Handler_OnlyStatus404()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'https://example.invalid/missing');
#if BC29PLUS
        Observer.Expect('result', 'ret=Yes status=404 reason=[Not Found] success=No blocked=No');
        Observer.Expect('last_error', '');
        Observer.Expect('last_code', '');
        Observer.Expect('calls', '1');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ErrorHandler')]
    procedure Handler_RaisesError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'https://example.invalid/boom');
        Observer.Expect('result', 'error status=200');
#if BC29PLUS
        Observer.Expect('last_error', 'handler failed');
        Observer.Expect('last_code', 'Dialog');
        Observer.Expect('calls', '1');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('FallThroughHandler')]
    procedure Handler_FallThrough_ConnectionRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Outcome(Observer, 'http://localhost:1/x');
#if BC29PLUS
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
        Observer.Expect('calls', '1');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    // Writer PY (2026-10-20): probes-needed "HTTP" rows (al-runtime-rs PR 342): a handler answering true while a StrMenuHandler is bound,
    // a failed call whose result is not used, a failed call into a response variable that already holds a response, ReasonPhrase for statuses
    // other than 200 and 404, more relative paths with and without a base address.
    [HttpClientHandler]
    procedure ModeHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        Seen += '[' + Request.Path + ']';
        case Mode of
            'status':
                begin
                    Response.HttpStatusCode := NextStatus;
                    exit(false);
                end;
            'true':
                exit(true);
            'error':
                Error('mode handler failed');
        end;
        exit(false);
    end;

    [TryFunction]
    local procedure TryGetStatement(var Client: HttpClient; Url: Text; var Resp: HttpResponseMessage)
    begin
        Client.Get(Url, Resp);
    end;

    local procedure Describe(var Resp: HttpResponseMessage): Text
    begin
        exit('status=' + Format(Resp.HttpStatusCode) + ' reason=[' + Resp.ReasonPhrase + '] success=' + Format(Resp.IsSuccessStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment));
    end;

    local procedure Menu(var Observer: Codeunit "Probe Observer"; Choice: Integer; Url: Text)
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Mode := 'true';
        MenuChoice := Choice;
        Calls := 0;
        MenuCalls := 0;
        MenuSeen := '';
        ClearLastError();
        if TryGet(Client, Url, Resp, Ret) then
            Observer.Observe('result', 'ret=' + Format(Ret) + ' ' + Describe(Resp))
        else
            Observer.Observe('result', 'error ' + Describe(Resp));
        Observer.Observe('last_error', GetLastErrorText());
        Observer.Observe('last_code', GetLastErrorCode());
        Observer.Observe('calls', Format(Calls) + ' menu=' + Format(MenuCalls) + ' ' + MenuSeen);
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_HandlerTrue_StrMenuAllowOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Menu(Observer, 2, 'http://localhost:1/x');
#if BC29PLUS
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_HandlerTrue_StrMenuBlockOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Menu(Observer, 4, 'http://localhost:1/x');
#if BC29PLUS
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_HandlerTrue_StrMenuCancel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Menu(Observer, 0, 'http://localhost:1/x');
#if BC29PLUS
        Observer.Expect('result', 'ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('last_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('last_code', 'HttpRequest:Security');
        Observer.Expect('calls', '1 menu=0 ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    local procedure Unused(var Observer: Codeunit "Probe Observer"; ObsKey: Text; NewMode: Text; Url: Text)
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
    begin
        Mode := NewMode;
        NextStatus := 404;
        Calls := 0;
        MenuCalls := 0;
        ClearLastError();
        if TryGetStatement(Client, Url, Resp) then
            Observer.Observe(ObsKey, 'ok ' + Describe(Resp) + ' calls=' + Format(Calls) + ' menu=' + Format(MenuCalls))
        else
            Observer.Observe(ObsKey, 'E[' + GetLastErrorText() + '|' + GetLastErrorCode() + '] ' + Describe(Resp) + ' calls=' + Format(Calls) + ' menu=' + Format(MenuCalls));
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_UnusedResult_BlockOnce()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MenuChoice := 4;
        Unused(Observer, 'block_once', 'true', 'http://localhost:1/x');
#if BC29PLUS
        Observer.Expect('block_once', 'E[There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.|HttpRequest:Security] status=0 reason=[NavHttpClient Request Failed] success=No blocked=No calls=1 menu=0');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_UnusedResult_AllowOnceRefused()
    var
        Observer: Codeunit "Probe Observer";
    begin
        MenuChoice := 2;
        Unused(Observer, 'allow_once', 'true', 'http://localhost:1/x');
#if BC29PLUS
        Observer.Expect('allow_once', 'E[There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.|HttpRequest:Security] status=0 reason=[NavHttpClient Request Failed] success=No blocked=No calls=1 menu=0');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_UnusedResult_MockedAndErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Unused(Observer, 'mocked_404', 'status', 'https://example.invalid/x');
        Unused(Observer, 'handler_error', 'error', 'https://example.invalid/x');
        Unused(Observer, 'no_base_a_b', 'status', 'a/b');
#if BC29PLUS
        Observer.Expect('mocked_404', 'ok status=404 reason=[Not Found] success=No blocked=No calls=1 menu=0');
        Observer.Expect('handler_error', 'E[mode handler failed|Dialog] status=200 reason=[OK] success=Yes blocked=No calls=1 menu=0');
        Observer.Expect('no_base_a_b', 'E[Invalid URI: The URI is empty.|AL:UriFormat] status=200 reason=[OK] success=Yes blocked=No calls=0 menu=0');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_FailedCall_IntoFilledResponse()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Mode := 'status';
        NextStatus := 201;
        Observer.Observe('first', Format(TryGet(Client, 'https://example.invalid/one', Resp, Ret)) + ' ret=' + Format(Ret) + ' ' + Describe(Resp));
        Mode := 'true';
        MenuChoice := 4;
        ClearLastError();
        Observer.Observe('second', Format(TryGet(Client, 'http://localhost:1/two', Resp, Ret)) + ' ret=' + Format(Ret) + ' ' + Describe(Resp));
        Observer.Observe('second_error', GetLastErrorText() + '|' + GetLastErrorCode());
        Mode := 'error';
        ClearLastError();
        Observer.Observe('third', Format(TryGet(Client, 'https://example.invalid/three', Resp, Ret)) + ' ret=' + Format(Ret) + ' ' + Describe(Resp));
#if BC29PLUS
        Observer.Expect('first', 'Yes ret=Yes status=201 reason=[Created] success=Yes blocked=No');
        Observer.Expect('second', 'Yes ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Expect('second_error', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.|HttpRequest:Security');
        Observer.Expect('third', 'No ret=No status=0 reason=[NavHttpClient Request Failed] success=No blocked=No');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    local procedure Reason(var Observer: Codeunit "Probe Observer"; Status: Integer)
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Ret: Boolean;
    begin
        Mode := 'status';
        NextStatus := Status;
        ClearLastError();
        if TryGet(Client, 'https://example.invalid/s', Resp, Ret) then
            Observer.Observe(Format(Status), 'ret=' + Format(Ret) + ' ' + Describe(Resp))
        else
            Observer.Observe(Format(Status), 'E[' + CopyStr(GetLastErrorText(), 1, 60) + '|' + GetLastErrorCode() + ']');
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_ReasonPhrase_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reason(Observer, 201);
        Reason(Observer, 202);
        Reason(Observer, 204);
        Reason(Observer, 301);
        Reason(Observer, 302);
        Reason(Observer, 304);
        Reason(Observer, 400);
        Reason(Observer, 401);
#if BC29PLUS
        Observer.Expect('201', 'ret=Yes status=201 reason=[Created] success=Yes blocked=No');
        Observer.Expect('202', 'ret=Yes status=202 reason=[Accepted] success=Yes blocked=No');
        Observer.Expect('204', 'ret=Yes status=204 reason=[No Content] success=Yes blocked=No');
        Observer.Expect('301', 'E[The value ''301'' is outside the allowed range for mocked HTTP|InvalidValue]');
        Observer.Expect('302', 'E[The value ''302'' is outside the allowed range for mocked HTTP|InvalidValue]');
        Observer.Expect('304', 'E[The value ''304'' is outside the allowed range for mocked HTTP|InvalidValue]');
        Observer.Expect('400', 'ret=Yes status=400 reason=[Bad Request] success=No blocked=No');
        Observer.Expect('401', 'ret=Yes status=401 reason=[Unauthorized] success=No blocked=No');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_ReasonPhrase_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reason(Observer, 403);
        Reason(Observer, 405);
        Reason(Observer, 409);
        Reason(Observer, 418);
        Reason(Observer, 422);
        Reason(Observer, 429);
        Reason(Observer, 500);
        Reason(Observer, 503);
#if BC29PLUS
        Observer.Expect('403', 'ret=Yes status=403 reason=[Forbidden] success=No blocked=No');
        Observer.Expect('405', 'ret=Yes status=405 reason=[Method Not Allowed] success=No blocked=No');
        Observer.Expect('409', 'ret=Yes status=409 reason=[Conflict] success=No blocked=No');
        Observer.Expect('418', 'E[The value ''418'' is not a valid HTTP status code.|InvalidValue]');
        Observer.Expect('422', 'ret=Yes status=422 reason=[Unprocessable Entity] success=No blocked=No');
        Observer.Expect('429', 'ret=Yes status=429 reason=[Too Many Requests] success=No blocked=No');
        Observer.Expect('500', 'ret=Yes status=500 reason=[Internal Server Error] success=No blocked=No');
        Observer.Expect('503', 'ret=Yes status=503 reason=[Service Unavailable] success=No blocked=No');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_ReasonPhrase_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Reason(Observer, 100);
        Reason(Observer, 299);
        Reason(Observer, 451);
        Reason(Observer, 599);
        Reason(Observer, 0);
        Reason(Observer, 999);
        Reason(Observer, 1000);
        Reason(Observer, -1);
#if BC29PLUS
        Observer.Expect('100', 'ret=Yes status=100 reason=[Continue] success=No blocked=No');
        Observer.Expect('299', 'E[The value ''299'' is not a valid HTTP status code.|InvalidValue]');
        Observer.Expect('451', 'ret=Yes status=451 reason=[Unavailable For Legal Reasons] success=No blocked=No');
        Observer.Expect('599', 'E[The value ''599'' is not a valid HTTP status code.|InvalidValue]');
        Observer.Expect('0', 'E[The value ''0'' is not a valid HTTP status code.|InvalidValue]');
        Observer.Expect('999', 'E[The value ''999'' is not a valid HTTP status code.|InvalidValue]');
        Observer.Expect('1000', 'E[The value ''1000'' is not a valid HTTP status code.|InvalidValue]');
        Observer.Expect('-1', 'E[The value ''-1'' is not a valid HTTP status code.|InvalidValue]');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    local procedure Join(var Observer: Codeunit "Probe Observer"; ObsKey: Text; Base: Text; Url: Text)
    var
        Client: HttpClient;
    begin
        Mode := 'status';
        NextStatus := 200;
        if Base <> '' then
            Client.SetBaseAddress(Base);
        Path(Observer, Client, ObsKey, Url);
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_BaseAddress_Joins_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Join(Observer, 'noslash_plain', 'https://example.invalid/api/v1', 'orders');
        Join(Observer, 'noslash_rooted', 'https://example.invalid/api/v1', '/orders');
        Join(Observer, 'host_only_plain', 'https://example.invalid', 'orders');
        Join(Observer, 'dot_slash', 'https://example.invalid/api/v1/', './x');
        Join(Observer, 'empty', 'https://example.invalid/api/v1/', '');
#if BC29PLUS
        Observer.Expect('noslash_plain', 'Yes [https://example.invalid/api/orders]');
        Observer.Expect('noslash_rooted', 'Yes [https://example.invalid/orders]');
        Observer.Expect('host_only_plain', 'Yes [https://example.invalid/orders]');
        Observer.Expect('dot_slash', 'Yes [https://example.invalid/api/v1/x]');
        Observer.Expect('empty', 'Yes [https://example.invalid/api/v1/]');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_BaseAddress_Joins_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Join(Observer, 'absolute', 'https://example.invalid/api/v1/', 'https://other.invalid/abs');
        Join(Observer, 'scheme_relative', 'https://example.invalid/api/v1/', '//other.invalid/x');
        Join(Observer, 'dot_dot_middle', 'https://example.invalid/api/v1/', 'a/../b');
        Join(Observer, 'two_up', 'https://example.invalid/api/v1/', '../../../x');
        Join(Observer, 'fragment', 'https://example.invalid/api/v1/', 'orders?x=1#f');
#if BC29PLUS
        Observer.Expect('absolute', 'Yes [https://other.invalid/abs]');
        Observer.Expect('scheme_relative', 'Yes [https://other.invalid/x]');
        Observer.Expect('dot_dot_middle', 'Yes [https://example.invalid/api/v1/b]');
        Observer.Expect('two_up', 'Yes [https://example.invalid/x]');
        Observer.Expect('fragment', 'Yes [https://example.invalid/api/v1/orders]');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_BaseAddress_Joins_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Join(Observer, 'base_query', 'https://example.invalid/api/v1/?k=1', 'orders');
        Join(Observer, 'space', 'https://example.invalid/api/v1/', 'a b');
        Join(Observer, 'trailing_slash', 'https://example.invalid/api/v1/', 'orders/');
        Join(Observer, 'query_on_noslash', 'https://example.invalid/api/v1', '?q=1');
#if BC29PLUS
        Observer.Expect('base_query', 'Yes [https://example.invalid/api/v1/orders]');
        Observer.Expect('space', 'Yes [https://example.invalid/api/v1/a%20b]');
        Observer.Expect('trailing_slash', 'Yes [https://example.invalid/api/v1/orders/]');
        Observer.Expect('query_on_noslash', 'Yes [https://example.invalid/api/v1]');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_NoBaseAddress_Paths_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Join(Observer, 'orders', '', 'orders');
        Join(Observer, 'rooted', '', '/orders');
        Join(Observer, 'x_y', '', 'x/y');
        Join(Observer, 'a_b_c', '', 'a/b/c');
#if BC29PLUS
        Observer.Expect('orders', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Expect('rooted', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Expect('x_y', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Expect('a_b_c', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure PY_NoBaseAddress_Paths_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Join(Observer, 'ab_cd', '', 'ab.cd');
        Join(Observer, 'query_x', '', '?x=2');
        Join(Observer, 'empty', '', '');
        Join(Observer, 'host_no_scheme', '', 'example.invalid/x');
#if BC29PLUS
        Observer.Expect('ab_cd', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Expect('query_x', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Expect('empty', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Expect('host_no_scheme', 'E[Invalid URI: The URI is empty.|AL:UriFormat] ');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, with the BC 29 values (Windows check 2026-10-22). The Linux images of 27 and 28
        // do not call it (Linux suspect, bc-linux issue 192), so nothing is asserted there.
        Observer.Discard();
#endif
    end;
}
