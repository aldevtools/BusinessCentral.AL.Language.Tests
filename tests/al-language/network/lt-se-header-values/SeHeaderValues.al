// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-add-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 89030
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced (27.5, 28.5 and 29.0 gave the same values).
// Facts: HttpHeaders.Add(Name, Value) used as an expression (the Boolean or the error: first 60 characters and code) and GetValues afterwards, for
// the typed headers that network/lt-ay-http/AyHeaderAddResult.al and lt-http-header-rules/P87*.al did not measure (Accept-Charset, Accept-Language,
// From, Pragma, TE, Trailer, Upgrade, Via, Warning, Server, Proxy-Authenticate, Transfer-Encoding), request headers added to response headers and
// response headers added to request headers, client default headers, and further value shapes of the measured typed headers (lists, parameters,
// spacing, case, other date forms, weak entity tags, numbers with leading zeros, uris).
// Asked by al-runtime-rs assumption http-header-rules (writer SE, 2026-10-25).
// BC versions: 27, 28, 29 (corpus CI)

codeunit 89030 "LT SE Header Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAdd(var H: HttpHeaders; N: Text; V: Text; var Ret: Boolean)
    begin
        Ret := H.Add(N, V);
    end;

    [TryFunction]
    local procedure TryGetValues(var H: HttpHeaders; N: Text; var Vals: List of [Text])
    begin
        H.GetValues(N, Vals);
    end;

    local procedure ReadBack(var H: HttpHeaders; N: Text): Text
    var
        Vals: List of [Text];
        V: Text;
        Out: Text;
    begin
        if not TryGetValues(H, N, Vals) then
            exit('get=E');
        Out := 'n=' + Format(Vals.Count());
        foreach V in Vals do
            Out += '[' + V + ']';
        exit(Out);
    end;

    local procedure AddTo(var Observer: Codeunit "Probe Observer"; var H: HttpHeaders; ObsKey: Text; N: Text; V: Text)
    var
        Ret: Boolean;
    begin
        ClearLastError();
        if TryAdd(H, N, V, Ret) then
            Observer.Observe(ObsKey, 'ret=' + Format(Ret) + ' ' + ReadBack(H, N))
        else
            Observer.Observe(ObsKey, 'E[' + CopyStr(GetLastErrorText(), 1, 60) + '|' + GetLastErrorCode() + '] ' + ReadBack(H, N));
    end;

    local procedure Req(var Observer: Codeunit "Probe Observer"; ObsKey: Text; N: Text; V: Text)
    var
        R: HttpRequestMessage;
        H: HttpHeaders;
    begin
        R.GetHeaders(H);
        AddTo(Observer, H, ObsKey, N, V);
    end;

    local procedure Cnt(var Observer: Codeunit "Probe Observer"; ObsKey: Text; N: Text; V: Text)
    var
        C: HttpContent;
        H: HttpHeaders;
    begin
        C.GetHeaders(H);
        AddTo(Observer, H, ObsKey, N, V);
    end;

    local procedure Resp(var Observer: Codeunit "Probe Observer"; ObsKey: Text; N: Text; V: Text)
    var
        R: HttpResponseMessage;
        H: HttpHeaders;
    begin
        H := R.Headers();
        AddTo(Observer, H, ObsKey, N, V);
    end;

    local procedure Cli(var Observer: Codeunit "Probe Observer"; ObsKey: Text; N: Text; V: Text)
    var
        Client: HttpClient;
        H: HttpHeaders;
    begin
        H := Client.DefaultRequestHeaders();
        AddTo(Observer, H, ObsKey, N, V);
    end;


    [Test]
    procedure SE_Untyped_Request_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'acceptcharset_0', 'Accept-Charset', 'utf-8');
        Req(Observer, 'acceptcharset_1', 'Accept-Charset', 'utf-8 ; q=0.5');
        Req(Observer, 'acceptcharset_2', 'Accept-Charset', 'a b');
        Req(Observer, 'acceptcharset_3', 'Accept-Charset', ';');
        Req(Observer, 'acceptlanguage_4', 'Accept-Language', 'en-US,de;q=0.8');
        Req(Observer, 'acceptlanguage_5', 'Accept-Language', 'e n');
        Req(Observer, 'from_6', 'From', 'a@b.example');
        Req(Observer, 'from_7', 'From', 'not an email');
        Observer.Expect('acceptcharset_0', 'ret=Yes n=1[utf-8]');
        Observer.Expect('acceptcharset_1', 'ret=Yes n=1[utf-8; q=0.5]');
        Observer.Expect('acceptcharset_2', 'ret=No get=E');
        Observer.Expect('acceptcharset_3', 'ret=No get=E');
        Observer.Expect('acceptlanguage_4', 'ret=Yes n=2[en-US][de; q=0.8]');
        Observer.Expect('acceptlanguage_5', 'ret=No get=E');
        Observer.Expect('from_6', 'ret=Yes n=1[a@b.example]');
        Observer.Expect('from_7', 'ret=Yes n=1[not an email]');
        Observer.Verify();
    end;

    [Test]
    procedure SE_Untyped_Request_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'pragma_0', 'Pragma', 'no-cache');
        Req(Observer, 'pragma_1', 'Pragma', 'a=b');
        Req(Observer, 'pragma_2', 'Pragma', 'a b');
        Req(Observer, 'te_3', 'TE', 'trailers');
        Req(Observer, 'te_4', 'TE', 'deflate;q=0.5');
        Req(Observer, 'te_5', 'TE', 'a b');
        Req(Observer, 'trailer_6', 'Trailer', 'X-A');
        Req(Observer, 'trailer_7', 'Trailer', 'a b');
        Observer.Expect('pragma_0', 'ret=Yes n=1[no-cache]');
        Observer.Expect('pragma_1', 'ret=Yes n=1[a=b]');
        Observer.Expect('pragma_2', 'ret=No get=E');
        Observer.Expect('te_3', 'ret=Yes n=1[trailers]');
        Observer.Expect('te_4', 'ret=Yes n=1[deflate; q=0.5]');
        Observer.Expect('te_5', 'ret=No get=E');
        Observer.Expect('trailer_6', 'ret=Yes n=1[X-A]');
        Observer.Expect('trailer_7', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure SE_Untyped_Request_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'upgrade_0', 'Upgrade', 'websocket');
        Req(Observer, 'upgrade_1', 'Upgrade', 'HTTP/2.0');
        Req(Observer, 'upgrade_2', 'Upgrade', 'a b');
        Req(Observer, 'via_3', 'Via', '1.1 proxy');
        Req(Observer, 'via_4', 'Via', '1.0 fred, 1.1 p.example');
        Req(Observer, 'via_5', 'Via', 'bad');
        Req(Observer, 'warning_6', 'Warning', '199 - "msg"');
        Req(Observer, 'warning_7', 'Warning', 'bad');
        Observer.Expect('upgrade_0', 'ret=Yes n=1[websocket]');
        Observer.Expect('upgrade_1', 'ret=Yes n=1[HTTP/2.0]');
        Observer.Expect('upgrade_2', 'ret=No get=E');
        Observer.Expect('via_3', 'ret=Yes n=1[1.1 proxy]');
        Observer.Expect('via_4', 'ret=Yes n=2[1.0 fred][1.1 p.example]');
        Observer.Expect('via_5', 'ret=No get=E');
        Observer.Expect('warning_6', 'ret=Yes n=1[199 - "msg"]');
        Observer.Expect('warning_7', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure SE_Untyped_Response()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Resp(Observer, 'server_0', 'Server', 'a/1.0 (x)');
        Resp(Observer, 'server_1', 'Server', 'a b');
        Resp(Observer, 'server_2', 'Server', '(');
        Resp(Observer, 'proxyauthenticate_3', 'Proxy-Authenticate', 'Basic realm="x"');
        Resp(Observer, 'proxyauthenticate_4', 'Proxy-Authenticate', ',');
        Resp(Observer, 'transferencoding_5', 'Transfer-Encoding', 'chunked');
        Resp(Observer, 'transferencoding_6', 'Transfer-Encoding', 'a b');
        Resp(Observer, 'via_7', 'Via', 'bad');
        Resp(Observer, 'pragma_8', 'Pragma', 'a b');
        Observer.Expect('server_0', 'ret=Yes n=2[a/1.0][(x)]');
        Observer.Expect('server_1', 'ret=Yes n=2[a][b]');
        Observer.Expect('server_2', 'ret=No get=E');
        Observer.Expect('proxyauthenticate_3', 'ret=Yes n=1[Basic realm="x"]');
        Observer.Expect('proxyauthenticate_4', 'ret=Yes get=E');
        Observer.Expect('transferencoding_5', 'ret=Yes n=1[chunked]');
        Observer.Expect('transferencoding_6', 'ret=No get=E');
        Observer.Expect('via_7', 'ret=No get=E');
        Observer.Expect('pragma_8', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure SE_RequestHeaders_OnResponse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Resp(Observer, 'range_0', 'Range', 'abc');
        Resp(Observer, 'ifmatch_1', 'If-Match', 'abc');
        Resp(Observer, 'accept_2', 'Accept', 'json');
        Resp(Observer, 'authorization_3', 'Authorization', 'a b c');
        Resp(Observer, 'useragent_4', 'User-Agent', '(');
        Resp(Observer, 'host_5', 'Host', 'a b');
        Resp(Observer, 'referer_6', 'Referer', 'a b');
        Resp(Observer, 'maxforwards_7', 'Max-Forwards', 'five');
        Resp(Observer, 'expect_8', 'Expect', '=');
        Observer.Expect('range_0', 'ret=Yes n=1[abc]');
        Observer.Expect('ifmatch_1', 'ret=Yes n=1[abc]');
        Observer.Expect('accept_2', 'ret=Yes n=1[json]');
        Observer.Expect('authorization_3', 'ret=Yes n=1[a b c]');
        Observer.Expect('useragent_4', 'ret=Yes n=1[(]');
        Observer.Expect('host_5', 'ret=Yes n=1[a b]');
        Observer.Expect('referer_6', 'ret=Yes n=1[a b]');
        Observer.Expect('maxforwards_7', 'ret=Yes n=1[five]');
        Observer.Expect('expect_8', 'ret=Yes n=1[=]');
        Observer.Verify();
    end;

    [Test]
    procedure SE_ResponseHeaders_OnRequest()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'etag_0', 'ETag', 'abc');
        Req(Observer, 'age_1', 'Age', 'old');
        Req(Observer, 'location_2', 'Location', 'a b');
        Req(Observer, 'retryafter_3', 'Retry-After', 'later');
        Req(Observer, 'vary_4', 'Vary', 'a b');
        Req(Observer, 'acceptranges_5', 'Accept-Ranges', 'a b');
        Req(Observer, 'wwwauthenticate_6', 'WWW-Authenticate', ',');
        Req(Observer, 'server_7', 'Server', '(');
        Req(Observer, 'proxyauthenticate_8', 'Proxy-Authenticate', ',');
        Observer.Expect('etag_0', 'ret=Yes n=1[abc]');
        Observer.Expect('age_1', 'ret=Yes n=1[old]');
        Observer.Expect('location_2', 'ret=Yes n=1[a b]');
        Observer.Expect('retryafter_3', 'ret=Yes n=1[later]');
        Observer.Expect('vary_4', 'ret=Yes n=1[a b]');
        Observer.Expect('acceptranges_5', 'ret=Yes n=1[a b]');
        Observer.Expect('wwwauthenticate_6', 'ret=Yes n=1[,]');
        Observer.Expect('server_7', 'ret=Yes n=1[(]');
        Observer.Expect('proxyauthenticate_8', 'ret=Yes n=1[,]');
        Observer.Verify();
    end;

    [Test]
    procedure SE_ClientHeaders()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cli(Observer, 'range_0', 'Range', 'abc');
        Cli(Observer, 'accept_1', 'Accept', 'json');
        Cli(Observer, 'ifmatch_2', 'If-Match', 'abc');
        Cli(Observer, 'etag_3', 'ETag', 'abc');
        Cli(Observer, 'age_4', 'Age', 'old');
        Cli(Observer, 'maxforwards_5', 'Max-Forwards', 'five');
        Cli(Observer, 'referer_6', 'Referer', 'a b');
        Cli(Observer, 'via_7', 'Via', 'bad');
        Cli(Observer, 'date_8', 'Date', 'yesterday');
        Observer.Expect('range_0', 'ret=No get=E');
        Observer.Expect('accept_1', 'ret=No get=E');
        Observer.Expect('ifmatch_2', 'ret=No get=E');
        Observer.Expect('etag_3', 'ret=Yes n=1[abc]');
        Observer.Expect('age_4', 'ret=Yes n=1[old]');
        Observer.Expect('maxforwards_5', 'ret=No get=E');
        Observer.Expect('referer_6', 'ret=Yes n=1[a%20b]');
        Observer.Expect('via_7', 'ret=No get=E');
        Observer.Expect('date_8', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure SE_Shapes_Accept()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'accept_0', 'Accept', 'text/html, application/json;q=0.9');
        Req(Observer, 'accept_1', 'Accept', 'text/html;q=0.9 ; level=1');
        Req(Observer, 'accept_2', 'Accept', '*/*');
        Req(Observer, 'accept_3', 'Accept', 'text/*');
        Req(Observer, 'accept_4', 'Accept', '*');
        Req(Observer, 'acceptencoding_5', 'Accept-Encoding', 'gzip, deflate;q=0.5');
        Req(Observer, 'acceptencoding_6', 'Accept-Encoding', 'gzip;q=1.0');
        Req(Observer, 'connection_7', 'Connection', ' close ');
        Req(Observer, 'connection_8', 'Connection', 'keep-alive, Upgrade');
        Observer.Expect('accept_0', 'ret=Yes n=2[text/html][application/json; q=0.9]');
        Observer.Expect('accept_1', 'ret=Yes n=1[text/html; q=0.9; level=1]');
        Observer.Expect('accept_2', 'ret=Yes n=1[*/*]');
        Observer.Expect('accept_3', 'ret=Yes n=1[text/*]');
        Observer.Expect('accept_4', 'ret=No get=E');
        Observer.Expect('acceptencoding_5', 'ret=Yes n=2[gzip][deflate; q=0.5]');
        Observer.Expect('acceptencoding_6', 'ret=Yes n=1[gzip; q=1.0]');
        Observer.Expect('connection_7', 'ret=Yes n=1[close]');
        Observer.Expect('connection_8', 'ret=Yes n=2[keep-alive][Upgrade]');
        Observer.Verify();
    end;

    [Test]
    procedure SE_Shapes_Authorization_UserAgent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'authorization_0', 'Authorization', 'Bearer  abc');
        Req(Observer, 'authorization_1', 'Authorization', 'Basic');
        Req(Observer, 'authorization_2', 'Authorization', 'Bearer a b');
        Req(Observer, 'useragent_3', 'User-Agent', 'Mozilla/5.0 (X11; Linux) Foo/1');
        Req(Observer, 'useragent_4', 'User-Agent', 'a b');
        Req(Observer, 'useragent_5', 'User-Agent', 'a/1 b/2');
        Req(Observer, 'proxyauthorization_6', 'Proxy-Authorization', 'Basic  x');
        Observer.Expect('authorization_0', 'ret=Yes n=1[Bearer abc]');
        Observer.Expect('authorization_1', 'ret=Yes n=1[Basic]');
        Observer.Expect('authorization_2', 'ret=Yes n=1[Bearer a b]');
        Observer.Expect('useragent_3', 'ret=Yes n=3[Mozilla/5.0][(X11; Linux)][Foo/1]');
        Observer.Expect('useragent_4', 'ret=Yes n=2[a][b]');
        Observer.Expect('useragent_5', 'ret=Yes n=2[a/1][b/2]');
        Observer.Expect('proxyauthorization_6', 'ret=Yes n=1[Basic x]');
        Observer.Verify();
    end;

    [Test]
    procedure SE_Shapes_Range_Host()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'range_0', 'Range', 'bytes=0-9, 20-29');
        Req(Observer, 'range_1', 'Range', 'bytes=-5');
        Req(Observer, 'range_2', 'Range', 'bytes=x');
        Req(Observer, 'range_3', 'Range', 'items=1-2');
        Req(Observer, 'host_4', 'Host', 'a.example:80');
        Req(Observer, 'host_5', 'Host', 'a.example:');
        Req(Observer, 'host_6', 'Host', '[::1]:8080');
        Req(Observer, 'host_7', 'Host', 'A.Example');
        Observer.Expect('range_0', 'ret=Yes n=1[bytes=0-9, 20-29]');
        Observer.Expect('range_1', 'ret=Yes n=1[bytes=-5]');
        Observer.Expect('range_2', 'ret=No get=E');
        Observer.Expect('range_3', 'ret=Yes n=1[items=1-2]');
        Observer.Expect('host_4', 'ret=Yes n=1[a.example:80]');
        Observer.Expect('host_5', 'ret=Yes n=1[a.example:]');
        Observer.Expect('host_6', 'ret=Yes n=1[[::1]:8080]');
        Observer.Expect('host_7', 'ret=Yes n=1[A.Example]');
        Observer.Verify();
    end;

    [Test]
    procedure SE_Shapes_Dates()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'date_0', 'Date', 'Tue, 15 Nov 1994 08:12:31 GMT');
        Req(Observer, 'date_1', 'Date', 'Tuesday, 15-Nov-94 08:12:31 GMT');
        Req(Observer, 'date_2', 'Date', 'Tue Nov 15 08:12:31 1994');
        Req(Observer, 'date_3', 'Date', '15 Nov 1994 08:12:31 +0100');
        Req(Observer, 'ifunmodifiedsince_4', 'If-Unmodified-Since', 'tue, 15 nov 1994 08:12:31 gmt');
        Cnt(Observer, 'lastmodified_5', 'Last-Modified', 'Tue, 15 Nov 1994 08:12:31 GMT');
        Cnt(Observer, 'expires_6', 'Expires', 'Tue, 15 Nov 1994 08:12:31 UTC');
        Observer.Expect('date_0', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Expect('date_1', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Expect('date_2', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Expect('date_3', 'ret=Yes n=1[Tue, 15 Nov 1994 07:12:31 GMT]');
        Observer.Expect('ifunmodifiedsince_4', 'ret=No get=E');
        Observer.Expect('lastmodified_5', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Expect('expires_6', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Verify();
    end;

    [Test]
    procedure SE_Shapes_EntityTags()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'ifmatch_0', 'If-Match', '"a", "b"');
        Req(Observer, 'ifmatch_1', 'If-Match', 'W/"a"');
        Req(Observer, 'ifnonematch_2', 'If-None-Match', '*');
        Req(Observer, 'ifnonematch_3', 'If-None-Match', '"a",W/"b"');
        Req(Observer, 'ifrange_4', 'If-Range', '"a"');
        Req(Observer, 'ifrange_5', 'If-Range', 'Tue, 15 Nov 1994 08:12:31 GMT');
        Resp(Observer, 'etag_6', 'ETag', 'W/"a"');
        Resp(Observer, 'etag_7', 'ETag', '*');
        Observer.Expect('ifmatch_0', 'ret=Yes n=2["a"]["b"]');
        Observer.Expect('ifmatch_1', 'ret=Yes n=1[W/"a"]');
        Observer.Expect('ifnonematch_2', 'ret=Yes n=1[*]');
        Observer.Expect('ifnonematch_3', 'ret=Yes n=2["a"][W/"b"]');
        Observer.Expect('ifrange_4', 'ret=Yes n=1["a"]');
        Observer.Expect('ifrange_5', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Expect('etag_6', 'ret=Yes n=1[W/"a"]');
        Observer.Expect('etag_7', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure SE_Shapes_Content()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cnt(Observer, 'contentdisposition_0', 'Content-Disposition', 'inline');
        Cnt(Observer, 'contentdisposition_1', 'Content-Disposition', 'attachment;filename=a.txt');
        Cnt(Observer, 'contentdisposition_2', 'Content-Disposition', 'form-data; name="f"; filename="a b.txt"');
        Cnt(Observer, 'contenttype_3', 'Content-Type', 'text/plain; charset="utf-8"');
        Cnt(Observer, 'contenttype_4', 'Content-Type', 'text/plain ; charset=utf-8');
        Cnt(Observer, 'contenttype_5', 'Content-Type', 'text/');
        Cnt(Observer, 'contentlength_6', 'Content-Length', ' 5');
        Cnt(Observer, 'contentlength_7', 'Content-Length', '05');
        Cnt(Observer, 'contentlength_8', 'Content-Length', '-1');
        Cnt(Observer, 'contentlanguage_9', 'Content-Language', 'en, de');
        Observer.Expect('contentdisposition_0', 'ret=Yes n=1[inline]');
        Observer.Expect('contentdisposition_1', 'ret=Yes n=1[attachment; filename=a.txt]');
        Observer.Expect('contentdisposition_2', 'ret=Yes n=1[form-data; name="f"; filename="a b.txt"]');
        Observer.Expect('contenttype_3', 'ret=No n=1[text/plain; charset=utf-8]');
        Observer.Expect('contenttype_4', 'ret=No n=1[text/plain; charset=utf-8]');
        Observer.Expect('contenttype_5', 'ret=No n=1[text/plain; charset=utf-8]');
        Observer.Expect('contentlength_6', 'ret=Yes n=1[5]');
        Observer.Expect('contentlength_7', 'ret=Yes n=1[5]');
        Observer.Expect('contentlength_8', 'ret=No get=E');
        Observer.Expect('contentlanguage_9', 'ret=Yes n=2[en][de]');
        Observer.Verify();
    end;

    [Test]
    procedure SE_Shapes_Numbers_Uris()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'maxforwards_0', 'Max-Forwards', '007');
        Resp(Observer, 'age_1', 'Age', '0');
        Resp(Observer, 'retryafter_2', 'Retry-After', 'Tue, 15 Nov 1994 08:12:31 GMT');
        Resp(Observer, 'location_3', 'Location', '/a b?x=1');
        Resp(Observer, 'location_4', 'Location', 'HTTPS://A.example/x');
        Req(Observer, 'referer_5', 'Referer', 'https://a.example');
        Cnt(Observer, 'contentrange_6', 'Content-Range', 'bytes */10');
        Req(Observer, 'expect_7', 'Expect', '100-continue; a=b');
        Observer.Expect('maxforwards_0', 'ret=Yes n=1[7]');
        Observer.Expect('age_1', 'ret=Yes n=1[0]');
        Observer.Expect('retryafter_2', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Expect('location_3', 'ret=Yes n=1[/a%20b?x=1]');
        Observer.Expect('location_4', 'ret=Yes n=1[https://a.example/x]');
        Observer.Expect('referer_5', 'ret=Yes n=1[https://a.example/]');
        Observer.Expect('contentrange_6', 'ret=Yes n=1[bytes */10]');
        Observer.Expect('expect_7', 'ret=Yes n=1[100-continue; a=b]');
        Observer.Verify();
    end;

    // Writer Y2 (al-runtime-rs assumption http-typed-header-value-shapes): the request-only names on response, response content and
    // client default headers, and more value shapes (two-digit years, offsets, case, spacing, empty list members). Measured: response headers
    // store request-only names as written; response content headers refuse them (Add answers false); client headers parse them as on a request.

    local procedure RespCnt(var Observer: Codeunit "Probe Observer"; ObsKey: Text; N: Text; V: Text)
    var
        R: HttpResponseMessage;
        C: HttpContent;
        H: HttpHeaders;
    begin
        C := R.Content();
        C.GetHeaders(H);
        AddTo(Observer, H, ObsKey, N, V);
    end;

    [Test]
    procedure Y2_RequestOnlyNames_OnResponse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Resp(Observer, 'acceptcharset_0', 'Accept-Charset', 'utf-8, iso-8859-1;q=0.5');
        Resp(Observer, 'acceptencoding_1', 'Accept-Encoding', 'gzip, ;');
        Resp(Observer, 'acceptlanguage_2', 'Accept-Language', 'de-DE, en;q=0.8');
        Resp(Observer, 'from_3', 'From', 'not an address');
        Resp(Observer, 'ifmodifiedsince_4', 'If-Modified-Since', 'yesterday');
        Resp(Observer, 'ifnonematch_5', 'If-None-Match', 'abc');
        Resp(Observer, 'ifrange_6', 'If-Range', 'abc');
        Resp(Observer, 'ifunmodifiedsince_7', 'If-Unmodified-Since', 'yesterday');
        Resp(Observer, 'proxyauthorization_8', 'Proxy-Authorization', 'a b c');
        Resp(Observer, 'te_9', 'TE', 'trailers, deflate;q=0.5');
        Observer.Expect('acceptcharset_0', 'ret=Yes n=1[utf-8, iso-8859-1;q=0.5]');
        Observer.Expect('acceptencoding_1', 'ret=Yes n=1[gzip, ;]');
        Observer.Expect('acceptlanguage_2', 'ret=Yes n=1[de-DE, en;q=0.8]');
        Observer.Expect('from_3', 'ret=Yes n=1[not an address]');
        Observer.Expect('ifmodifiedsince_4', 'ret=Yes n=1[yesterday]');
        Observer.Expect('ifnonematch_5', 'ret=Yes n=1[abc]');
        Observer.Expect('ifrange_6', 'ret=Yes n=1[abc]');
        Observer.Expect('ifunmodifiedsince_7', 'ret=Yes n=1[yesterday]');
        Observer.Expect('proxyauthorization_8', 'ret=Yes n=1[a b c]');
        Observer.Expect('te_9', 'ret=Yes n=1[trailers, deflate;q=0.5]');
        Observer.Verify();
    end;

    [Test]
    procedure Y2_RequestOnlyNames_OnResponseContent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RespCnt(Observer, 'acceptcharset_0', 'Accept-Charset', 'utf-8');
        RespCnt(Observer, 'acceptlanguage_1', 'Accept-Language', 'de-DE');
        RespCnt(Observer, 'from_2', 'From', 'x');
        RespCnt(Observer, 'ifmodifiedsince_3', 'If-Modified-Since', 'yesterday');
        RespCnt(Observer, 'te_4', 'TE', 'trailers');
        Observer.Expect('acceptcharset_0', 'ret=No get=E');
        Observer.Expect('acceptlanguage_1', 'ret=No get=E');
        Observer.Expect('from_2', 'ret=No get=E');
        Observer.Expect('ifmodifiedsince_3', 'ret=No get=E');
        Observer.Expect('te_4', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Y2_RequestOnlyNames_OnClient()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cli(Observer, 'acceptcharset_0', 'Accept-Charset', 'utf-8');
        Cli(Observer, 'acceptencoding_1', 'Accept-Encoding', 'gzip');
        Cli(Observer, 'acceptlanguage_2', 'Accept-Language', 'de-DE');
        Cli(Observer, 'from_3', 'From', 'a@b.c');
        Cli(Observer, 'ifmodifiedsince_4', 'If-Modified-Since', 'Tue, 15 Nov 1994 08:12:31 GMT');
        Cli(Observer, 'ifnonematch_5', 'If-None-Match', '"a"');
        Cli(Observer, 'ifrange_6', 'If-Range', '"a"');
        Cli(Observer, 'ifunmodifiedsince_7', 'If-Unmodified-Since', 'yesterday');
        Cli(Observer, 'proxyauthorization_8', 'Proxy-Authorization', 'Basic x');
        Cli(Observer, 'te_9', 'TE', 'trailers');
        Observer.Expect('acceptcharset_0', 'ret=Yes n=1[utf-8]');
        Observer.Expect('acceptencoding_1', 'ret=Yes n=1[gzip]');
        Observer.Expect('acceptlanguage_2', 'ret=Yes n=1[de-DE]');
        Observer.Expect('from_3', 'ret=Yes n=1[a@b.c]');
        Observer.Expect('ifmodifiedsince_4', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Expect('ifnonematch_5', 'ret=Yes n=1["a"]');
        Observer.Expect('ifrange_6', 'ret=Yes n=1["a"]');
        Observer.Expect('ifunmodifiedsince_7', 'ret=No get=E');
        Observer.Expect('proxyauthorization_8', 'ret=Yes n=1[Basic x]');
        Observer.Expect('te_9', 'ret=Yes n=1[trailers]');
        Observer.Verify();
    end;

    [Test]
    procedure Y2_Shapes_RequestOnlyValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'acceptcharset_0', 'Accept-Charset', 'utf-8, iso-8859-1;q=0.5');
        Req(Observer, 'acceptcharset_1', 'Accept-Charset', '*');
        Req(Observer, 'acceptcharset_2', 'Accept-Charset', 'utf-8;q=x');
        Req(Observer, 'acceptlanguage_3', 'Accept-Language', 'de-DE, en;q=0.8');
        Req(Observer, 'acceptlanguage_4', 'Accept-Language', 'de DE');
        Req(Observer, 'from_5', 'From', 'a@b.c');
        Req(Observer, 'from_6', 'From', 'not an address');
        Req(Observer, 'te_7', 'TE', 'trailers, deflate;q=0.5');
        Req(Observer, 'te_8', 'TE', 'a b');
        Req(Observer, 'ifmodifiedsince_9', 'If-Modified-Since', 'yesterday');
        Observer.Expect('acceptcharset_0', 'ret=Yes n=2[utf-8][iso-8859-1; q=0.5]');
        Observer.Expect('acceptcharset_1', 'ret=Yes n=1[*]');
        Observer.Expect('acceptcharset_2', 'ret=No get=E');
        Observer.Expect('acceptlanguage_3', 'ret=Yes n=2[de-DE][en; q=0.8]');
        Observer.Expect('acceptlanguage_4', 'ret=No get=E');
        Observer.Expect('from_5', 'ret=Yes n=1[a@b.c]');
        Observer.Expect('from_6', 'ret=Yes n=1[not an address]');
        Observer.Expect('te_7', 'ret=Yes n=2[trailers][deflate; q=0.5]');
        Observer.Expect('te_8', 'ret=No get=E');
        Observer.Expect('ifmodifiedsince_9', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Y2_Shapes_DatesTwoDigitYearsOffsets()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'ifmodifiedsince_0', 'If-Modified-Since', 'Sunday, 06-Nov-94 08:49:37 GMT');
        Req(Observer, 'ifmodifiedsince_1', 'If-Modified-Since', 'Sun, 06 Nov 49 08:49:37 GMT');
        Req(Observer, 'ifmodifiedsince_2', 'If-Modified-Since', 'Sun, 06 Nov 50 08:49:37 GMT');
        Req(Observer, 'ifmodifiedsince_3', 'If-Modified-Since', 'Sun, 06 Nov 1994 08:49:37 -0500');
        Req(Observer, 'ifmodifiedsince_4', 'If-Modified-Since', 'Sun, 06 Nov 1994 08:49:37 +0000');
        Req(Observer, 'ifmodifiedsince_5', 'If-Modified-Since', 'sun, 06 nov 1994 08:49:37 GMT');
        Req(Observer, 'ifmodifiedsince_6', 'If-Modified-Since', 'Sun,06 Nov 1994 08:49:37 GMT');
        Req(Observer, 'ifmodifiedsince_7', 'If-Modified-Since', '06 Nov 1994');
        Req(Observer, 'ifmodifiedsince_8', 'If-Modified-Since', 'Sun, 6 Nov 1994 8:49:37 GMT');
        Cnt(Observer, 'expires_9', 'Expires', '0');
        Cnt(Observer, 'expires_10', 'Expires', '-1');
        Observer.Expect('ifmodifiedsince_0', 'ret=Yes n=1[Sun, 06 Nov 1994 08:49:37 GMT]');
        Observer.Expect('ifmodifiedsince_1', 'ret=No get=E');
        Observer.Expect('ifmodifiedsince_2', 'ret=No get=E');
        Observer.Expect('ifmodifiedsince_3', 'ret=Yes n=1[Sun, 06 Nov 1994 13:49:37 GMT]');
        Observer.Expect('ifmodifiedsince_4', 'ret=Yes n=1[Sun, 06 Nov 1994 08:49:37 GMT]');
        Observer.Expect('ifmodifiedsince_5', 'ret=Yes n=1[Sun, 06 Nov 1994 08:49:37 GMT]');
        Observer.Expect('ifmodifiedsince_6', 'ret=Yes n=1[Sun, 06 Nov 1994 08:49:37 GMT]');
        Observer.Expect('ifmodifiedsince_7', 'ret=No get=E');
        Observer.Expect('ifmodifiedsince_8', 'ret=Yes n=1[Sun, 06 Nov 1994 08:49:37 GMT]');
        Observer.Expect('expires_9', 'ret=No get=E');
        Observer.Expect('expires_10', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Y2_Shapes_CaseAndSpacing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'authorization_0', 'Authorization', 'bearer abc');
        Req(Observer, 'authorization_1', 'Authorization', 'BEARER');
        Req(Observer, 'accept_2', 'Accept', 'TEXT/HTML');
        Req(Observer, 'accept_3', 'Accept', 'text/html ,application/json');
        Req(Observer, 'accept_4', 'Accept', 'text/html,,application/json');
        Req(Observer, 'acceptencoding_5', 'Accept-Encoding', 'GZIP');
        Req(Observer, 'connection_6', 'Connection', 'CLOSE');
        Cnt(Observer, 'contenttype_7', 'Content-Type', 'TEXT/PLAIN; CHARSET=UTF-8');
        Cnt(Observer, 'contentencoding_8', 'Content-Encoding', 'gzip ,  br');
        Req(Observer, 'range_9', 'Range', 'BYTES=0-9');
        Req(Observer, 'transferencoding_10', 'Transfer-Encoding', 'Chunked');
        Observer.Expect('authorization_0', 'ret=Yes n=1[bearer abc]');
        Observer.Expect('authorization_1', 'ret=Yes n=1[BEARER]');
        Observer.Expect('accept_2', 'ret=Yes n=1[TEXT/HTML]');
        Observer.Expect('accept_3', 'ret=Yes n=2[text/html][application/json]');
        Observer.Expect('accept_4', 'ret=Yes n=2[text/html][application/json]');
        Observer.Expect('acceptencoding_5', 'ret=Yes n=1[GZIP]');
        Observer.Expect('connection_6', 'ret=Yes n=1[CLOSE]');
        Observer.Expect('contenttype_7', 'ret=No n=1[text/plain; charset=utf-8]');
        Observer.Expect('contentencoding_8', 'ret=Yes n=2[gzip][br]');
        Observer.Expect('range_9', 'ret=Yes n=1[BYTES=0-9]');
        Observer.Expect('transferencoding_10', 'ret=Yes n=1[Chunked]');
        Observer.Verify();
    end;
}
