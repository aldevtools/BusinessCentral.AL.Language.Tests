// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient-mock-outbound-calls
// Scope: in-scope (OnPrem app: [HttpClientHandler] and TestHttpRequestMessage / TestHttpResponseMessage are Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; own codeunit 98064
// Probe: measured on the BC 27.5, 28.5 and 29.0 service tiers (local observation, then the PR CI run).
// HttpHeaders.Contains('') on what a test handler leaves behind: the response a handler wrote content into, the response a handler touched nothing of,
// the response whose handler added a header, the response of a handler that answers true to an address that refuses the connection (a failed call), and
// the request headers and request content headers the handler is given. Each cell: ok, found, error text and code, then the Content-Type and the body.
// On the Linux images of BC 27 and 28 a request is not given to the handler (bc-linux issue 192): handler values are asserted on BC 29 only, as AyHttpHandler.al does.
// BC versions: 27, 28, 29 (corpus CI); handler values asserted on 29 only.

codeunit 98064 "LT HtT Handler Response Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = AllowOutboundFromHandler;

    var
        Observer: Codeunit "Probe Observer";
        Mode: Integer;
        Calls: Integer;

    [TryFunction]
    local procedure TryContainsEmpty(var Headers: HttpHeaders; var Found: Boolean)
    begin
        Found := Headers.Contains('');
    end;

    local procedure Cell(Name: Text; var Headers: HttpHeaders)
    var
        Found: Boolean;
        Ok: Boolean;
    begin
        Found := true;
        ClearLastError();
        Ok := TryContainsEmpty(Headers, Found);
        Observer.Observe(Name + '|ok', Format(Ok));
        Observer.Observe(Name + '|found', Format(Found));
        Observer.ObserveError(Name);
    end;

    local procedure ContentType(var Headers: HttpHeaders): Text
    var
        Values: List of [Text];
    begin
        if Headers.GetValues('Content-Type', Values) then
            exit(Values.Get(1));
        exit('<absent>');
    end;

    local procedure ResponseContentCell(Name: Text; var Response: HttpResponseMessage)
    var
        Headers: HttpHeaders;
        Body: Text;
    begin
        Response.Content.GetHeaders(Headers);
        Cell(Name, Headers);
        Observer.Observe(Name + '|type', ContentType(Headers));
        Observer.Observe(Name + '|length', Format(Headers.Contains('Content-Length')));
        Response.Content.ReadAs(Body);
        Observer.Observe(Name + '|body', Body);
    end;

    [HttpClientHandler]
    procedure ModeHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        Headers: HttpHeaders;
        Body: Text;
    begin
        Calls += 1;
        Response.HttpStatusCode := 200;
        case Mode of
            1:
                Response.Content.WriteFrom('x');
            2:
                ;
            3:
                Response.Headers.Add('X-A', 'v');
            4:
                exit(true);
            5:
                begin
                    Response.Content.WriteFrom('x');
                    Response.Headers.Add('X-A', 'v');
                    exit(true);
                end;
            6:
                begin
                    Observer.Observe('handler|requestType', Format(Request.RequestType));
                    Observer.Observe('handler|requestPath', Request.Path);
                end;
            7:
                begin
                    Response.Content.WriteFrom('x');
                    Response.Content.GetHeaders(Headers);
                    Cell('handler|ownResponseContent', Headers);
                    Headers := Response.Headers;
                    Cell('handler|ownResponseHeaders', Headers);
                end;
        end;
        exit(false);
    end;

    local procedure Get(NewMode: Integer; Url: Text; var Response: HttpResponseMessage)
    var
        Client: HttpClient;
        Ok: Boolean;
    begin
        Mode := NewMode;
        Calls := 0;
        ClearLastError();
        Ok := Client.Get(Url, Response);
        Observer.Observe('get', Format(Ok));
        Observer.Observe('calls', Format(Calls));
        Observer.ObserveError('get|err');
    end;

    local procedure ResponseCells(var Response: HttpResponseMessage)
    var
        Headers: HttpHeaders;
    begin
        Headers := Response.Headers();
        Cell('headers', Headers);
        Observer.Observe('headers|x-a', Format(Headers.Contains('X-A')));
        ResponseContentCell('content', Response);
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure Cell9_HandlerWrote_Content()
    var
        Response: HttpResponseMessage;
    begin
        ClearLastError();
        Get(1, 'https://lt-hhr.invalid/', Response);
        ResponseCells(Response);
#if BC29PLUS
        Observer.Expect('get', 'Yes');
        Observer.Expect('calls', '1');
        Observer.Expect('get|err|text', '');
        Observer.Expect('get|err|code', '');
        Observer.Expect('headers|ok', 'No');
        Observer.Expect('headers|found', 'Yes');
        Observer.Expect('headers|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('headers|code', 'InvalidHeader:Argument');
        Observer.Expect('headers|x-a', 'No');
        Observer.Expect('content|ok', 'No');
        Observer.Expect('content|found', 'Yes');
        Observer.Expect('content|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('content|code', 'InvalidHeader:Argument');
        Observer.Expect('content|type', 'text/plain; charset=utf-8');
        Observer.Expect('content|length', 'No');
        Observer.Expect('content|body', 'x');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too (local observation of this probe); the Linux images of 27 and 28 do not call it (bc-linux issue 192).
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure CellD_HandlerSetNothing()
    var
        Response: HttpResponseMessage;
    begin
        ClearLastError();
        Get(2, 'https://lt-hhr.invalid/', Response);
        ResponseCells(Response);
#if BC29PLUS
        Observer.Expect('get', 'Yes');
        Observer.Expect('calls', '1');
        Observer.Expect('get|err|text', '');
        Observer.Expect('get|err|code', '');
        Observer.Expect('headers|ok', 'No');
        Observer.Expect('headers|found', 'Yes');
        Observer.Expect('headers|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('headers|code', 'InvalidHeader:Argument');
        Observer.Expect('headers|x-a', 'No');
        Observer.Expect('content|ok', 'No');
        Observer.Expect('content|found', 'Yes');
        Observer.Expect('content|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('content|code', 'InvalidHeader:Argument');
        Observer.Expect('content|type', '<absent>');
        Observer.Expect('content|length', 'No');
        Observer.Expect('content|body', '');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too (local observation of this probe); the Linux images of 27 and 28 do not call it (bc-linux issue 192).
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure HandlerAddedResponseHeader()
    var
        Response: HttpResponseMessage;
    begin
        ClearLastError();
        Get(3, 'https://lt-hhr.invalid/', Response);
        ResponseCells(Response);
#if BC29PLUS
        Observer.Expect('get', 'Yes');
        Observer.Expect('calls', '1');
        Observer.Expect('get|err|text', '');
        Observer.Expect('get|err|code', '');
        Observer.Expect('headers|ok', 'No');
        Observer.Expect('headers|found', 'Yes');
        Observer.Expect('headers|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('headers|code', 'InvalidHeader:Argument');
        Observer.Expect('headers|x-a', 'Yes');
        Observer.Expect('content|ok', 'No');
        Observer.Expect('content|found', 'Yes');
        Observer.Expect('content|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('content|code', 'InvalidHeader:Argument');
        Observer.Expect('content|type', '<absent>');
        Observer.Expect('content|length', 'No');
        Observer.Expect('content|body', '');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too (local observation of this probe); the Linux images of 27 and 28 do not call it (bc-linux issue 192).
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure CellE_HandlerFallsThrough_FailedCall()
    var
        Response: HttpResponseMessage;
    begin
        ClearLastError();
        Get(4, 'http://localhost:1/x', Response);
        ResponseCells(Response);
#if BC29PLUS
        Observer.Expect('get', 'No');
        Observer.Expect('calls', '1');
        Observer.Expect('get|err|text', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('get|err|code', 'HttpRequest:Security');
        Observer.Expect('headers|ok', 'No');
        Observer.Expect('headers|found', 'Yes');
        Observer.Expect('headers|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('headers|code', 'InvalidHeader:Argument');
        Observer.Expect('headers|x-a', 'No');
        Observer.Expect('content|ok', 'No');
        Observer.Expect('content|found', 'Yes');
        Observer.Expect('content|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('content|code', 'InvalidHeader:Argument');
        Observer.Expect('content|type', '<absent>');
        Observer.Expect('content|length', 'No');
        Observer.Expect('content|body', '');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too (local observation of this probe); the Linux images of 27 and 28 do not call it (bc-linux issue 192).
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure CellE_HandlerWroteThenFallsThrough_FailedCall()
    var
        Response: HttpResponseMessage;
    begin
        ClearLastError();
        Get(5, 'http://localhost:1/x', Response);
        ResponseCells(Response);
#if BC29PLUS
        Observer.Expect('get', 'No');
        Observer.Expect('calls', '1');
        Observer.Expect('get|err|text', 'There was an error while executing the HTTP request, the connecting endpoint violates security requirements. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('get|err|code', 'HttpRequest:Security');
        Observer.Expect('headers|ok', 'No');
        Observer.Expect('headers|found', 'Yes');
        Observer.Expect('headers|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('headers|code', 'InvalidHeader:Argument');
        Observer.Expect('headers|x-a', 'No');
        Observer.Expect('content|ok', 'No');
        Observer.Expect('content|found', 'Yes');
        Observer.Expect('content|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('content|code', 'InvalidHeader:Argument');
        Observer.Expect('content|type', '<absent>');
        Observer.Expect('content|length', 'No');
        Observer.Expect('content|body', '');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too (local observation of this probe); the Linux images of 27 and 28 do not call it (bc-linux issue 192).
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure HandlerSeesRequestHeadersAndContent()
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Ok: Boolean;
    begin
        ClearLastError();
        Mode := 6;
        Request.SetRequestUri('https://lt-hhr.invalid/');
        Request.Method := 'POST';
        Request.Content.WriteFrom('request body');
        Ok := Client.Send(Request, Response);
        Observer.Observe('send', Format(Ok));
#if BC29PLUS
        Observer.Expect('handler|requestType', 'Post');
        Observer.Expect('handler|requestPath', 'https://lt-hhr.invalid/');
        Observer.Expect('send', 'Yes');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too (local observation of this probe); the Linux images of 27 and 28 do not call it (bc-linux issue 192).
        Observer.Discard();
#endif
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure HandlerReadsItsOwnResponse()
    var
        Response: HttpResponseMessage;
    begin
        ClearLastError();
        Get(7, 'https://lt-hhr.invalid/', Response);
#if BC29PLUS
        Observer.Expect('handler|ownResponseContent|ok', 'No');
        Observer.Expect('handler|ownResponseContent|found', 'Yes');
        Observer.Expect('handler|ownResponseContent|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('handler|ownResponseContent|code', 'InvalidHeader:Argument');
        Observer.Expect('handler|ownResponseHeaders|ok', 'No');
        Observer.Expect('handler|ownResponseHeaders|found', 'Yes');
        Observer.Expect('handler|ownResponseHeaders|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('handler|ownResponseHeaders|code', 'InvalidHeader:Argument');
        Observer.Expect('get', 'Yes');
        Observer.Expect('calls', '1');
        Observer.Expect('get|err|text', '');
        Observer.Expect('get|err|code', '');
        Observer.Verify();
#else
        // BC 27.5 and 28.5 on Windows call the handler too (local observation of this probe); the Linux images of 27 and 28 do not call it (bc-linux issue 192).
        Observer.Discard();
#endif
    end;
}
