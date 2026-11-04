// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient-mock-outbound-calls
// Scope: in-scope (OnPrem app: the [HttpClientHandler] attribute and TestHttpRequestMessage / TestHttpResponseMessage are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 61297
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816). No request leaves the machine except the one that falls through to a name that never resolves (example.invalid). Other BC versions were not measured.
//
// What an [HttpClientHandler] sees and answers (TestHttpRequestPolicy = AllowOutboundFromHandler):
//  - HttpClient.Get, Post, Put, Delete, Patch and Send each reach the handler once, in call order; RequestType is Get, Post, Put, Delete, Patch and (Send with method HEAD) Head.
//  - Path is scheme, host and path without the query string; QueryParameters holds the decoded query (x=1 and y=two; %20 arrives as a space). HasSecretUri is No for a plain Text URL.
//  - The response the handler fills (status 201, reason, body, a header) is what the caller reads: the call answers true, IsSuccessStatusCode Yes, IsBlockedByEnvironment No. A handler that sets nothing and
//    answers false still intercepts: status 200, reason "OK", empty body. A handler that answers true lets the real request go (which fails for an unresolvable name: the call answers false) and
//    the mocked status is not used.
//  - A request with no handler raises "Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to 'AllowOutboundFromHandler'. Please ensure that an HTTP client
//    handler is configured." (code TestCodeunitUnhandledHttpRequest); PZHttpBlock.al has the same for BlockOutboundRequests.
// BC versions: 29.0. On 27.0 to 28.5 (CI) a request is not given to the handler at all: the tests that need the handler are compiled out there, and PZHttpBlock.al pins the unhandled-request error for a request that has a handler.
codeunit 61297 "PZ Http Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowOutboundFromHandler;

    var
        SeenList: List of [Text];
        Calls: Integer;
        HandlerAnswer: Boolean;

    [HttpClientHandler]
    procedure Handler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Params: Dictionary of [Text, Text];
        ParamName: Text;
        ParamText: Text;
        HeaderValues: List of [Text];
    begin
        Calls += 1;
        Params := Request.QueryParameters;
        foreach ParamName in Params.Keys() do
            ParamText += ParamName + '=' + Params.Get(ParamName) + '&';
        SeenList.Add(Format(Request.RequestType) + ' [' + Request.Path + '] params=[' + ParamText + '] secret=' + Format(Request.HasSecretUri));
        Response.HttpStatusCode := 201;
        Response.ReasonPhrase := 'Made Up';
        Response.Content.WriteFrom('reply ' + Format(Calls));
        Response.Headers.Add('X-Mock', 'yes');
        exit(HandlerAnswer);
    end;

    local procedure Reset()
    begin
        Calls := 0;
        Clear(SeenList);
    end;

    local procedure ObserveSeen(var Observer: Codeunit "Probe Observer")
    var
        i: Integer;
    begin
        Observer.Observe('seen_count', Format(SeenList.Count()));
        for i := 1 to SeenList.Count() do
            Observer.Observe('seen_' + Format(i), SeenList.Get(i));
    end;

    local procedure Describe(Ok: Boolean; var Resp: HttpResponseMessage): Text
    var
        Body: Text;
        Values: array[1] of Text;
        Hdr: Text;
    begin
        Resp.Content.ReadAs(Body);
        if Resp.Headers.GetValues('X-Mock', Values) then
            Hdr := Values[1];
        exit('ok=' + Format(Ok) + ' status=' + Format(Resp.HttpStatusCode) + ' reason=' + Resp.ReasonPhrase + ' body=[' + Body + '] success=' + Format(Resp.IsSuccessStatusCode) + ' blocked=' + Format(Resp.IsBlockedByEnvironment) + ' header=[' + Hdr + ']');
    end;

    [HttpClientHandler]
    procedure EmptyHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
    end;

    [HttpClientHandler]
    procedure FallThroughHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Calls += 1;
        Response.HttpStatusCode := 202;
        exit(true);
    end;

    [TryFunction]
    local procedure TryGet(Url: Text; var Resp: HttpResponseMessage)
    var
        Client: HttpClient;
    begin
        if not Client.Get(Url, Resp) then
            Error('get returned false');
    end;

#if BC29PLUS
    [Test]
    [HandlerFunctions('Handler')]
    procedure EveryMethod_ReachesTheHandler_WithItsRequestMembers()
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Req: HttpRequestMessage;
        Content: HttpContent;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Ok := Client.Get('https://example.invalid/a/b?x=1&y=two', Resp);
        Observer.Observe('get', Describe(Ok, Resp));
        Content.WriteFrom('payload');
        Ok := Client.Post('https://example.invalid/post', Content, Resp);
        Observer.Observe('post', Describe(Ok, Resp));
        Ok := Client.Put('https://example.invalid/put', Content, Resp);
        Ok := Client.Delete('https://example.invalid/del', Resp);
        Ok := Client.Patch('https://example.invalid/patch', Content, Resp);
        Req.Method := 'HEAD';
        Req.SetRequestUri('https://example.invalid/head?q=%20a');
        Ok := Client.Send(Req, Resp);
        Observer.Observe('send', Describe(Ok, Resp));
        Observer.Observe('calls', Format(Calls));
        ObserveSeen(Observer);
        Observer.Expect('get', 'ok=Yes status=201 reason=Made Up body=[reply 1] success=Yes blocked=No header=[yes]');
        Observer.Expect('post', 'ok=Yes status=201 reason=Made Up body=[reply 2] success=Yes blocked=No header=[yes]');
        Observer.Expect('send', 'ok=Yes status=201 reason=Made Up body=[reply 6] success=Yes blocked=No header=[yes]');
        Observer.Expect('calls', '6');
        Observer.Expect('seen_count', '6');
        Observer.Expect('seen_1', 'Get [https://example.invalid/a/b] params=[x=1&y=two&] secret=No');
        Observer.Expect('seen_2', 'Post [https://example.invalid/post] params=[] secret=No');
        Observer.Expect('seen_3', 'Put [https://example.invalid/put] params=[] secret=No');
        Observer.Expect('seen_4', 'Delete [https://example.invalid/del] params=[] secret=No');
        Observer.Expect('seen_5', 'Patch [https://example.invalid/patch] params=[] secret=No');
        Observer.Expect('seen_6', 'Head [https://example.invalid/head] params=[q= a&] secret=No');
        Observer.Verify();
    end;
#endif

#if BC29PLUS
    [Test]
    [HandlerFunctions('EmptyHandler')]
    procedure EmptyHandler_AnswersADefaultResponse()
    var
        Client: HttpClient;
        Resp: HttpResponseMessage;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Ok := Client.Get('https://example.invalid/empty', Resp);
        Observer.Observe('empty_handler', Describe(Ok, Resp));
        Observer.Observe('calls', Format(Calls));
        Observer.Expect('empty_handler', 'ok=Yes status=200 reason=OK body=[] success=Yes blocked=No header=[]');
        Observer.Expect('calls', '1');
        Observer.Verify();
    end;
#endif

#if BC29PLUS
    [Test]
    [HandlerFunctions('FallThroughHandler')]
    procedure HandlerAnsweringTrue_SendsTheRealRequest()
    var
        Resp: HttpResponseMessage;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Ok := TryGet('https://example.invalid/fall-through', Resp);
        Observer.Observe('fall_through_ok', Format(Ok));
        Observer.Observe('calls', Format(Calls));
        Observer.Observe('status_not_the_mocked_one', Format(Resp.HttpStatusCode <> 202));
        Observer.Expect('fall_through_ok', 'No');
        Observer.Expect('calls', '1');
        Observer.Expect('status_not_the_mocked_one', 'Yes');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure NoHandler_UnderAllowOutboundFromHandler()
    var
        Resp: HttpResponseMessage;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Ok := TryGet('https://example.invalid/none', Resp);
        Observer.Observe('no_handler', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('no_handler', 'No Unhandled outbound HTTP requests are not permitted when the TestHttpRequestPolicy property is set to ''AllowOutboundFromHandler''. Please ensure that an HTTP client handler is configured.|TestCodeunitUnhandledHttpRequest');
        Observer.Verify();
    end;
}
