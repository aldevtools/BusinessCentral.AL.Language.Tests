// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httprequestmessage/httprequestmessage-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// HttpRequestMessage: Method, SetRequestUri/GetRequestUri, Content, GetHeaders, invalid URIs.
// Fixtures used: Probe Observer (codeunit 69160)
// BC versions: 29 (27 and 28 by CI)

codeunit 72024 "LT HtT Request"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        BmContent: HttpContent;
        BmRequest: HttpRequestMessage;
        BmClient: HttpClient;

    [Test]
    procedure FreshRequest()
    var
        Req: HttpRequestMessage;
        Headers: HttpHeaders;
    begin
        Observer.Observe('method', Req.Method());
        Observer.Observe('uri', Req.GetRequestUri());
        Req.GetHeaders(Headers);
        Observer.Observe('headerKeys', Format(Headers.Keys().Count()));
        Observer.Expect('method', 'GET');
        Observer.Expect('uri', '');
        Observer.Expect('headerKeys', '0');
        Observer.Verify();
    end;

    [Test]
    procedure MethodValues()
    var
        Req: HttpRequestMessage;
    begin
        Req.Method := 'POST';
        Observer.Observe('post', Req.Method());
        Req.Method := 'post';
        Observer.Observe('lowerPost', Req.Method());
        Req.Method('Delete');
        Observer.Observe('delete', Req.Method());
        Req.Method := 'PATCH';
        Observer.Observe('patch', Req.Method());
        Req.Method := 'CUSTOM';
        Observer.Observe('custom', Req.Method());
        Req.Method := 'HEAD';
        Observer.Observe('head', Req.Method());
        Req.Method := 'OPTIONS';
        Observer.Observe('options', Req.Method());
        Observer.Observe('empty', '[' + Req.Method() + ']');
        Observer.Expect('post', 'POST');
        Observer.Expect('lowerPost', 'post');
        Observer.Expect('delete', 'Delete');
        Observer.Expect('patch', 'PATCH');
        Observer.Expect('custom', 'CUSTOM');
        Observer.Expect('head', 'HEAD');
        Observer.Expect('options', 'OPTIONS');
        Observer.Expect('empty', '[OPTIONS]');
        Observer.Verify();
    end;

    [Test]
    procedure InvalidMethods()
    var
        Req: HttpRequestMessage;
    begin
        asserterror Req.Method := 'GE T';
        Observer.ObserveError('space');
        asserterror Req.Method := 'G:T';
        Observer.ObserveError('colon');
        Observer.Observe('method', '[' + Req.Method() + ']');
        Observer.Expect('space|text', 'The format of the HTTP method is invalid.');
        Observer.Expect('space|code', 'AL:Format');
        Observer.Expect('colon|text', 'The format of the HTTP method is invalid.');
        Observer.Expect('colon|code', 'AL:Format');
        Observer.Expect('method', '[GET]');
        Observer.Verify();
    end;

    [Test]
    procedure SetRequestUriValid()
    var
        Req: HttpRequestMessage;
    begin
        Observer.Observe('set', Format(Req.SetRequestUri('https://example.invalid/path?q=1')));
        Observer.Observe('get', Req.GetRequestUri());
        Req.SetRequestUri('http://example.invalid');
        Observer.Observe('noPath', Req.GetRequestUri());
        Req.SetRequestUri('HTTPS://EXAMPLE.invalid/A/B');
        Observer.Observe('upper', Req.GetRequestUri());
        Req.SetRequestUri('https://example.invalid:8443/x');
        Observer.Observe('port', Req.GetRequestUri());
        Req.SetRequestUri('https://example.invalid:443/x');
        Observer.Observe('defaultPort', Req.GetRequestUri());
        Req.SetRequestUri('https://example.invalid/a b');
        Observer.Observe('space', Req.GetRequestUri());
        Req.SetRequestUri('https://example.invalid/x#frag');
        Observer.Observe('fragment', Req.GetRequestUri());
        Req.SetRequestUri('https://user@example.invalid/x');
        Observer.Observe('userinfo', Req.GetRequestUri());
        Observer.Expect('set', 'Yes');
        Observer.Expect('get', 'https://example.invalid/path?q=1');
        Observer.Expect('noPath', 'http://example.invalid/');
        Observer.Expect('upper', 'https://example.invalid/A/B');
        Observer.Expect('port', 'https://example.invalid:8443/x');
        Observer.Expect('defaultPort', 'https://example.invalid/x');
        Observer.Expect('space', 'https://example.invalid/a%20b');
        Observer.Expect('fragment', 'https://example.invalid/x#frag');
        Observer.Expect('userinfo', 'https://user@example.invalid/x');
        Observer.Verify();
    end;

    [Test]
    procedure SetRequestUriRelativeAndInvalid()
    var
        Req: HttpRequestMessage;
    begin
        asserterror Req.SetRequestUri('/relative/path');
        Observer.ObserveError('relative');
        asserterror Req.SetRequestUri('');
        Observer.ObserveError('empty');
        asserterror Req.SetRequestUri('http://');
        Observer.ObserveError('noHost');
        asserterror Req.SetRequestUri('ht!tp://x');
        Observer.ObserveError('badScheme');
        asserterror Req.SetRequestUri('https://exa mple.invalid/');
        Observer.ObserveError('spaceInHost');
        asserterror Req.SetRequestUri('https://example.invalid:99999/');
        Observer.ObserveError('portRange');
        Observer.Observe('uriAfterErrors', Req.GetRequestUri());
        Observer.Expect('relative|text', 'Failed to create the URL for the request. Please, make sure to set a valid URL.');
        Observer.Expect('relative|code', 'CreateUrl:UriFormat');
        Observer.Expect('empty|text', 'Failed to create the URL for the request. Please, make sure to set a valid URL.');
        Observer.Expect('empty|code', 'CreateUrl:UriFormat');
        Observer.Expect('noHost|text', 'Failed to create the URL for the request. Please, make sure to set a valid URL.');
        Observer.Expect('noHost|code', 'CreateUrl:UriFormat');
        Observer.Expect('badScheme|text', 'Failed to create the URL for the request. Please, make sure to set a valid URL.');
        Observer.Expect('badScheme|code', 'CreateUrl:UriFormat');
        Observer.Expect('spaceInHost|text', 'Failed to create the URL for the request. Please, make sure to set a valid URL.');
        Observer.Expect('spaceInHost|code', 'CreateUrl:UriFormat');
        Observer.Expect('portRange|text', 'Failed to create the URL for the request. Please, make sure to set a valid URL.');
        Observer.Expect('portRange|code', 'CreateUrl:UriFormat');
        Observer.Expect('uriAfterErrors', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetRequestUriOtherSchemes()
    var
        Req: HttpRequestMessage;
    begin
        Req.SetRequestUri('ftp://example.invalid/x');
        Observer.Observe('ftp', 'no error');
        Req.SetRequestUri('file:///c:/x');
        Observer.Observe('file', 'no error');
        Req.SetRequestUri('mailto:a@b.c');
        Observer.Observe('mailto', 'no error');
        Req.SetRequestUri('javascript:alert(1)');
        Observer.Observe('javascript', 'no error');
        Observer.Observe('uri', Req.GetRequestUri());
        Observer.Expect('ftp', 'no error');
        Observer.Expect('file', 'no error');
        Observer.Expect('mailto', 'no error');
        Observer.Expect('javascript', 'no error');
        Observer.Expect('uri', 'javascript:alert(1)');
        Observer.Verify();
    end;

    [Test]
    procedure SetRequestUriLongAndUnicode()
    var
        Req: HttpRequestMessage;
        Path: Text;
        i: Integer;
    begin
        for i := 1 to 3000 do
            Path += 'a';
        Req.SetRequestUri('https://example.invalid/' + Path);
        Observer.Observe('longLen', Format(StrLen(Req.GetRequestUri())));
        Req.SetRequestUri('https://example.invalid/ä');
        Observer.Observe('umlaut', Req.GetRequestUri());
        Req.SetRequestUri('https://example.invalid/?a=1&b=2');
        Observer.Observe('query', Req.GetRequestUri());
        Observer.Expect('longLen', '3024');
        Observer.Expect('umlaut', 'https://example.invalid/%C3%A4');
        Observer.Expect('query', 'https://example.invalid/?a=1&b=2');
        Observer.Verify();
    end;

    [Test]
    procedure RequestContentRoundTrip()
    var
        Req: HttpRequestMessage;
        Content: HttpContent;
        Content2: HttpContent;
        Txt: Text;
    begin
        Content.WriteFrom('body text');
        Req.Content := Content;
        Req.Content.ReadAs(Txt);
        Observer.Observe('read', Txt);
        Content2 := Req.Content;
        Content2.ReadAs(Txt);
        Observer.Observe('read2', Txt);
        Observer.Expect('read', 'body text');
        Observer.Expect('read2', 'body text');
        Observer.Verify();
    end;

    [Test]
    procedure FreshRequestContent()
    var
        Req: HttpRequestMessage;
        Txt: Text;
        Headers: HttpHeaders;
        Content: HttpContent;
    begin
        Txt := 'preset';
        Observer.Observe('ok', Format(Req.Content.ReadAs(Txt)));
        Observer.Observe('text', Txt);
        Content := Req.Content;
        asserterror Content.GetHeaders(Headers);
        Observer.ObserveError('af177');
        Observer.Observe('keys', Format(Headers.Keys().Count()));
        Observer.Expect('ok', 'No');
        Observer.Expect('text', 'preset');
        Observer.Expect('af177|text', 'Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.');
        Observer.Expect('af177|code', 'NotInitialized');
        Observer.Expect('keys', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ContentHeadersViaRequest()
    var
        Req: HttpRequestMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        ReqHeaders: HttpHeaders;
        Vals: array[5] of Text;
    begin
        Content.WriteFrom('x');
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'text/plain');
        Req.Content := Content;
        Req.Content.GetHeaders(ContentHeaders);
        Observer.Observe('type', Format(ContentHeaders.GetValues('Content-Type', Vals)));
        Observer.Observe('v1', Vals[1]);
        Req.GetHeaders(ReqHeaders);
        asserterror Observer.Observe('reqHasType', Format(ReqHeaders.Contains('Content-Type')));
        Observer.ObserveError('af201');
        Observer.Expect('type', 'Yes');
        Observer.Expect('v1', 'text/plain');
        Observer.Expect('af201|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('af201|code', 'InvalidHeader:InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure RequestHeadersAreLive()
    var
        Req: HttpRequestMessage;
        H1: HttpHeaders;
        H2: HttpHeaders;
    begin
        Req.GetHeaders(H1);
        H1.Add('X-Live', 'v');
        Req.GetHeaders(H2);
        Observer.Observe('second', Format(H2.Contains('X-Live')));
        H2.Remove('X-Live');
        Observer.Observe('firstAfter', Format(H1.Contains('X-Live')));
        Observer.Expect('second', 'Yes');
        Observer.Expect('firstAfter', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsBlockedByEnvironmentOnRequestSide()
    var
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
    begin
        Observer.Observe('freshResp', Format(Resp.IsBlockedByEnvironment()));
        Observer.Expect('freshResp', 'No');
        Observer.Verify();
    end;

    // Corpus #664 item 36: HttpContent, HttpClient, HttpRequestMessage, HttpHeaders and HttpResponseMessage compile as return types
    // (AL 30 beta). This records whether the returned value is the holder's instance or a copy (no network call is made).
    [Test]
    procedure BM_HttpTypes_AsReturnValues()
    var
        Obs: Codeunit "Probe Observer";
        C: HttpContent;
        R: HttpRequestMessage;
        H: HttpHeaders;
        H2: HttpHeaders;
        Cl: HttpClient;
        Resp: HttpResponseMessage;
        T: Text;
    begin
        BmContent.WriteFrom('holder');
        C := BmGetContent();
        C.ReadAs(T);
        Obs.Observe('content_read', T);
        C.WriteFrom('changed');
        BmContent.ReadAs(T);
        Obs.Observe('content_holder_after_write', T);
        BmRequest.Method := 'GET';
        R := BmGetRequest();
        Obs.Observe('request_method', R.Method());
        R.Method := 'PUT';
        Obs.Observe('request_holder_method_after_set', BmRequest.Method());
        H := BmGetRequestHeaders();
        H.Add('X-BM', '1');
        BmRequest.GetHeaders(H2);
        Obs.Observe('headers_holder_contains_added', Format(H2.Contains('X-BM')));
        Cl := BmGetClient();
        Cl.Timeout := 5000;
        Obs.Observe('client_holder_timeout', Format(BmClient.Timeout()));
        Resp := BmGetResponse();
        Obs.Observe('response_status', Format(Resp.HttpStatusCode()));
        Obs.Observe('response_success', Format(Resp.IsSuccessStatusCode()));
        Obs.Expect('content_read', 'holder');
        Obs.Expect('content_holder_after_write', 'holder');
        Obs.Expect('request_method', 'GET');
        Obs.Expect('request_holder_method_after_set', 'PUT');
        Obs.Expect('headers_holder_contains_added', 'Yes');
        Obs.Expect('client_holder_timeout', '5 seconds');
        Obs.Expect('response_status', '200');
        Obs.Expect('response_success', 'Yes');
        Obs.Verify();
    end;

    local procedure BmGetContent(): HttpContent
    begin
        exit(BmContent);
    end;

    local procedure BmGetRequest(): HttpRequestMessage
    begin
        exit(BmRequest);
    end;

    local procedure BmGetRequestHeaders(): HttpHeaders
    var
        H: HttpHeaders;
    begin
        BmRequest.GetHeaders(H);
        exit(H);
    end;

    local procedure BmGetClient(): HttpClient
    begin
        exit(BmClient);
    end;

    local procedure BmGetResponse(): HttpResponseMessage
    var
        Resp: HttpResponseMessage;
    begin
        exit(Resp);
    end;
}

