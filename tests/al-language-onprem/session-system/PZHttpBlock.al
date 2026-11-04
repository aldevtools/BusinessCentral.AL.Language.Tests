// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-testhttprequestpolicy-property
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute is Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61298
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816). BC 27.5 and 28.5: Windows service tiers (Windows check 2026-10-22).
//
// TestHttpRequestPolicy = BlockOutboundRequests: a request with no handler raises "Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to
// 'BlockOutboundRequests'. Please ensure that an HTTP client handler is configured." (code TestCodeunitUnhandledHttpRequest); with a handler the request is answered.
// A handler that returns false gives its mock (status, body; it runs once); one that returns true raises "Explicit HTTP client handler fallthrough is not allowed when the
// TestHttpRequestPolicy property is set to 'BlockOutboundRequests'." (code NotAllowedHttpClientHandlerFallThrough).
// BC versions: 29 asserted. BC 27.5 and 28.5 call the handler on Windows (Windows check 2026-10-22); the Linux images of 27 and 28 do not (Linux suspect), so 27/28 assert nothing.
codeunit 61298 "PZ Http Block"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        MockCalls: Integer;

    [TryFunction]
    local procedure TryGet(Url: Text)
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
    begin
        if not Client.Get(Url, Resp) then
            Error('get returned false');
    end;

    [HttpClientHandler]
    procedure Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 202;
    end;

    [Test]
    procedure NoHandler_UnderBlockOutboundRequests()
    var
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Ok := TryGet('https://example.invalid/blocked');
        Observer.Observe('no_handler', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('no_handler', 'No Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''. Please ensure that an HTTP client handler is configured.|TestCodeunitUnhandledHttpRequest');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('Handler')]
    procedure Handler_UnderBlockOutboundRequests_StillAnswers()
    var
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Ok := TryGet('https://example.invalid/handled');
        Observer.Observe('handled', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
#if BC29PLUS
        Observer.Expect('handled', 'Yes |');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too, 'Yes |' (Windows check 2026-10-22, al-runner issue 5777). The Linux images of 27 and 28
        // do not ('No Unhandled outbound HTTP requests are not permitted ...|TestCodeunitUnhandledHttpRequest'): a Linux image bug, so nothing is asserted there.
        Observer.Discard();
#endif
    end;

    // ---- The shape of al-runner issue 5777: a mock handler that counts its calls, answers 200 with a body and returns false (the mock is used),
    // a handler that returns true (the request goes out, which BlockOutboundRequests refuses), and a GET that reads the status and the body.

    [HttpClientHandler]
    procedure MockHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        MockCalls += 1;
        Response.HttpStatusCode(200);
        Response.Content.WriteFrom('{"ok":true}');
        exit(false);
    end;

    [HttpClientHandler]
    procedure PassOnHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        MockCalls += 1;
        exit(true);
    end;

    local procedure GetStatusAndBody(Url: Text; var Status: Integer; var Body: Text): Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        if not Client.Get(Url, Response) then
            exit(false);
        Status := Response.HttpStatusCode();
        Response.Content.ReadAs(Body);
        exit(true);
    end;

    [TryFunction]
    local procedure TryGetStatusAndBody(Url: Text; var Ok: Boolean; var Status: Integer; var Body: Text)
    begin
        Ok := GetStatusAndBody(Url, Status, Body);
    end;

    [Test]
    [HandlerFunctions('MockHandler')]
    procedure RS_MockHandler_ReturnsFalse_GivesTheMock()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        Status: Integer;
        Body: Text;
    begin
        MockCalls := 0;
        ClearLastError();
        Observer.Observe('try', Format(TryGetStatusAndBody('https://api.example.com/v1/items?id=7', Ok, Status, Body)));
        Observer.Observe('result', StrSubstNo('%1|%2|%3|%4', Ok, Status, Body, MockCalls));
        Observer.Observe('error', GetLastErrorText() + '|' + GetLastErrorCode());
#if BC29PLUS
        Observer.Expect('try', 'Yes');
        Observer.Expect('result', 'Yes|200|{"ok":true}|1');
        Observer.Expect('error', '|');
        Observer.Verify();
#else
        // Windows 27.5/28.5 not measured for this test; the Linux images of 27 and 28 do not call the handler (see Handler_UnderBlockOutboundRequests_StillAnswers).
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('PassOnHandler')]
    procedure RS_PassOnHandler_ReturnsTrue_UnderBlockOutboundRequests()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        Status: Integer;
        Body: Text;
    begin
        MockCalls := 0;
        ClearLastError();
        Observer.Observe('try', Format(TryGetStatusAndBody('https://api.example.com/v1/items?id=7', Ok, Status, Body)));
        Observer.Observe('result', StrSubstNo('%1|%2|%3|%4', Ok, Status, Body, MockCalls));
        Observer.Observe('error', GetLastErrorText() + '|' + GetLastErrorCode());
#if BC29PLUS
        Observer.Expect('try', 'No');
        Observer.Expect('result', 'No|0||1');
        Observer.Expect('error', 'Explicit HTTP client handler fallthrough is not allowed when the TestHttpRequestPolicy property is set to ''BlockOutboundRequests''.|NotAllowedHttpClientHandlerFallThrough');
        Observer.Verify();
#else
        // Windows 27.5/28.5 not measured for this test; the Linux images of 27 and 28 do not call the handler (see Handler_UnderBlockOutboundRequests_StillAnswers).
        Observer.Discard();
#endif
    end;
}
