// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-add-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 89030
// Probe: observe probe; every literal asserted below is what the BC service tiers produced (Windows BC 28.5 container, then corpus CI 27.5, 28.5, 29.0).
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
