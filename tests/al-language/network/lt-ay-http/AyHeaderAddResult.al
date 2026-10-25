// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-add-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80507
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: HttpHeaders.Add(Name, Value) used as an expression (the Boolean it returns, or the error it raises: first 60 characters and the code) for
// bad values of the typed headers Accept, Authorization, Date and Content-Type, for bad header names, and for valid and invalid values of the other
// typed headers (Range, If-Match, If-None-Match, If-Modified-Since, If-Range, Max-Forwards, Referer, Expect, Content-Disposition, Content-Encoding,
// Content-Language, Content-Range, Content-MD5, Content-Location, Expires, Last-Modified, Allow, Age, ETag, Location, Retry-After, Vary, WWW-Authenticate,
// Accept-Ranges) on request, content and response headers; the values read back with GetValues afterwards. P87Matrix.al pins the valid values per
// collection with a statement call; the lt-http-header-names-cache-control folder pins Cache-Control.
// Writer PY (2026-10-20, tests PY_*): GetValues of a missing, bad or content name as a statement and as an expression on request, response,
// client and content headers; the last error after an Add that answered false.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 80507 "LT AY Header Add Result"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAdd(var H: HttpHeaders; N: Text; V: Text; var Ret: Boolean)
    begin
        Ret := H.Add(N, V);
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

    [TryFunction]
    local procedure TryGetValues(var H: HttpHeaders; N: Text; var Vals: List of [Text])
    begin
        H.GetValues(N, Vals);
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

    [Test]
    procedure Add_AsExpression_BadTypedValues_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'accept_ok', 'Accept', 'application/json');
        Req(Observer, 'accept_noslash', 'Accept', 'json');
        Req(Observer, 'accept_semis', 'Accept', ';;;');
        Observer.Expect('accept_ok', 'ret=Yes n=1[application/json]');
        Observer.Expect('accept_noslash', 'ret=No get=E');
        Observer.Expect('accept_semis', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_AsExpression_BadTypedValues_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'accept_quote', 'Accept', 'a/b; q="');
        Req(Observer, 'auth_ok', 'Authorization', 'Bearer abc');
        Req(Observer, 'auth_three', 'Authorization', 'a b c');
        Observer.Expect('accept_quote', 'ret=No get=E');
        Observer.Expect('auth_ok', 'ret=Yes n=1[Bearer abc]');
        Observer.Expect('auth_three', 'ret=Yes n=1[a b c]');
        Observer.Verify();
    end;

    [Test]
    procedure Add_AsExpression_BadTypedValues_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'auth_comma', 'Authorization', ',');
        Req(Observer, 'auth_empty', 'Authorization', '');
        Req(Observer, 'date_ok', 'Date', 'Tue, 15 Nov 1994 08:12:31 GMT');
        Observer.Expect('auth_comma', 'ret=No get=E');
        Observer.Expect('auth_empty', 'ret=No get=E');
        Observer.Expect('date_ok', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Verify();
    end;

    [Test]
    procedure Add_AsExpression_BadTypedValues_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'date_bad', 'Date', 'not a date');
        Req(Observer, 'date_iso', 'Date', '1994-11-15T08:12:31Z');
        Cnt(Observer, 'ctype_ok', 'Content-Type', 'text/plain');
        Observer.Expect('date_bad', 'ret=No get=E');
        Observer.Expect('date_iso', 'ret=No get=E');
        Observer.Expect('ctype_ok', 'ret=No n=1[text/plain; charset=utf-8]');
        Observer.Verify();
    end;

    [Test]
    procedure Add_AsExpression_BadTypedValues_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cnt(Observer, 'ctype_noslash', 'Content-Type', 'text');
        Cnt(Observer, 'ctype_two', 'Content-Type', 'text/plain, text/html');
        Cnt(Observer, 'ctype_badparam', 'Content-Type', 'text/plain; =x');
        Observer.Expect('ctype_noslash', 'ret=No n=1[text/plain; charset=utf-8]');
        Observer.Expect('ctype_two', 'ret=No n=1[text/plain; charset=utf-8]');
        Observer.Expect('ctype_badparam', 'ret=No n=1[text/plain; charset=utf-8]');
        Observer.Verify();
    end;

    [Test]
    procedure Add_AsExpression_BadNames_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'name_space', 'Bad Name', 'v');
        Req(Observer, 'name_colon', 'X:Y', 'v');
        Req(Observer, 'name_empty', '', 'v');
        Observer.Expect('name_space', 'ret=No get=E');
        Observer.Expect('name_colon', 'ret=No get=E');
        Observer.Expect('name_empty', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_AsExpression_BadNames_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'name_paren', 'X(Y)', 'v');
        Req(Observer, 'name_unicode', 'X-Ä', 'v');
        Cnt(Observer, 'content_name_space', 'Bad Name', 'v');
        Observer.Expect('name_paren', 'ret=No get=E');
        Observer.Expect('name_unicode', 'ret=No get=E');
        Observer.Expect('content_name_space', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_AsExpression_BadNames_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Resp(Observer, 'response_name_space', 'Bad Name', 'v');
        Req(Observer, 'name_content_on_request', 'Content-Type', 'text/plain');
        Cnt(Observer, 'name_request_on_content', 'Accept', 'text/plain');
        Observer.Expect('response_name_space', 'ret=No get=E');
        Observer.Expect('name_content_on_request', 'ret=No get=E');
        Observer.Expect('name_request_on_content', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedRequestHeaders_ValidAndInvalid_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'range_ok', 'Range', 'bytes=0-9');
        Req(Observer, 'range_bad', 'Range', 'abc');
        Req(Observer, 'range_noeq', 'Range', 'bytes 0-9');
        Observer.Expect('range_ok', 'ret=Yes n=1[bytes=0-9]');
        Observer.Expect('range_bad', 'ret=No get=E');
        Observer.Expect('range_noeq', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedRequestHeaders_ValidAndInvalid_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'ifmatch_ok', 'If-Match', '"abc"');
        Req(Observer, 'ifmatch_star', 'If-Match', '*');
        Req(Observer, 'ifmatch_bad', 'If-Match', 'abc');
        Observer.Expect('ifmatch_ok', 'ret=Yes n=1["abc"]');
        Observer.Expect('ifmatch_star', 'ret=Yes n=1[*]');
        Observer.Expect('ifmatch_bad', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedRequestHeaders_ValidAndInvalid_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'ifnonematch_bad', 'If-None-Match', 'abc');
        Req(Observer, 'ifmodsince_ok', 'If-Modified-Since', 'Tue, 15 Nov 1994 08:12:31 GMT');
        Req(Observer, 'ifmodsince_bad', 'If-Modified-Since', 'yesterday');
        Observer.Expect('ifnonematch_bad', 'ret=No get=E');
        Observer.Expect('ifmodsince_ok', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Expect('ifmodsince_bad', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedRequestHeaders_ValidAndInvalid_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'ifrange_bad', 'If-Range', 'abc');
        Req(Observer, 'maxfwd_ok', 'Max-Forwards', '5');
        Req(Observer, 'maxfwd_bad', 'Max-Forwards', 'five');
        Observer.Expect('ifrange_bad', 'ret=No get=E');
        Observer.Expect('maxfwd_ok', 'ret=Yes n=1[5]');
        Observer.Expect('maxfwd_bad', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedRequestHeaders_ValidAndInvalid_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Req(Observer, 'referer_ok', 'Referer', 'https://a.example/x');
        Req(Observer, 'referer_bad', 'Referer', 'a b');
        Req(Observer, 'expect_bad', 'Expect', '=');
        Observer.Expect('referer_ok', 'ret=Yes n=1[https://a.example/x]');
        Observer.Expect('referer_bad', 'ret=Yes n=1[a%20b]');
        Observer.Expect('expect_bad', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedContentHeaders_ValidAndInvalid_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cnt(Observer, 'disp_ok', 'Content-Disposition', 'attachment; filename="a.txt"');
        Cnt(Observer, 'disp_bad', 'Content-Disposition', ';;;');
        Cnt(Observer, 'enc_ok', 'Content-Encoding', 'gzip');
        Observer.Expect('disp_ok', 'ret=Yes n=1[attachment; filename="a.txt"]');
        Observer.Expect('disp_bad', 'ret=No get=E');
        Observer.Expect('enc_ok', 'ret=Yes n=1[gzip]');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedContentHeaders_ValidAndInvalid_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cnt(Observer, 'enc_bad', 'Content-Encoding', 'g z');
        Cnt(Observer, 'lang_bad', 'Content-Language', 'e n');
        Cnt(Observer, 'crange_ok', 'Content-Range', 'bytes 0-9/10');
        Observer.Expect('enc_bad', 'ret=No get=E');
        Observer.Expect('lang_bad', 'ret=No get=E');
        Observer.Expect('crange_ok', 'ret=Yes n=1[bytes 0-9/10]');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedContentHeaders_ValidAndInvalid_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cnt(Observer, 'crange_bad', 'Content-Range', 'abc');
        Cnt(Observer, 'md5_ok', 'Content-MD5', 'AAECAwQFBgcICQoLDA0ODw==');
        Cnt(Observer, 'md5_bad', 'Content-MD5', 'not base64!');
        Observer.Expect('crange_bad', 'ret=No get=E');
        Observer.Expect('md5_ok', 'ret=Yes n=1[AAECAwQFBgcICQoLDA0ODw==]');
        Observer.Expect('md5_bad', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedContentHeaders_ValidAndInvalid_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cnt(Observer, 'cloc_bad', 'Content-Location', 'a b');
        Cnt(Observer, 'expires_ok', 'Expires', 'Tue, 15 Nov 1994 08:12:31 GMT');
        Cnt(Observer, 'expires_bad', 'Expires', 'soon');
        Observer.Expect('cloc_bad', 'ret=Yes n=1[a%20b]');
        Observer.Expect('expires_ok', 'ret=Yes n=1[Tue, 15 Nov 1994 08:12:31 GMT]');
        Observer.Expect('expires_bad', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedContentHeaders_ValidAndInvalid_5()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cnt(Observer, 'expires_zero', 'Expires', '0');
        Cnt(Observer, 'lastmod_bad', 'Last-Modified', 'soon');
        Cnt(Observer, 'allow_bad', 'Allow', 'G E T');
        Observer.Expect('expires_zero', 'ret=No get=E');
        Observer.Expect('lastmod_bad', 'ret=No get=E');
        Observer.Expect('allow_bad', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedResponseHeaders_ValidAndInvalid_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Resp(Observer, 'age_ok', 'Age', '12');
        Resp(Observer, 'age_bad', 'Age', 'old');
        Resp(Observer, 'etag_ok', 'ETag', '"abc"');
        Observer.Expect('age_ok', 'ret=Yes n=1[12]');
        Observer.Expect('age_bad', 'ret=No get=E');
        Observer.Expect('etag_ok', 'ret=Yes n=1["abc"]');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedResponseHeaders_ValidAndInvalid_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Resp(Observer, 'etag_bad', 'ETag', 'abc');
        Resp(Observer, 'location_ok', 'Location', 'https://a.example/x');
        Resp(Observer, 'location_bad', 'Location', 'a b');
        Observer.Expect('etag_bad', 'ret=No get=E');
        Observer.Expect('location_ok', 'ret=Yes n=1[https://a.example/x]');
        Observer.Expect('location_bad', 'ret=Yes n=1[a%20b]');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedResponseHeaders_ValidAndInvalid_3()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Resp(Observer, 'retry_ok', 'Retry-After', '120');
        Resp(Observer, 'retry_bad', 'Retry-After', 'later');
        Resp(Observer, 'vary_bad', 'Vary', 'a b');
        Observer.Expect('retry_ok', 'ret=Yes n=1[120]');
        Observer.Expect('retry_bad', 'ret=No get=E');
        Observer.Expect('vary_bad', 'ret=No get=E');
        Observer.Verify();
    end;

    [Test]
    procedure Add_TypedResponseHeaders_ValidAndInvalid_4()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Resp(Observer, 'wwwauth_bad', 'WWW-Authenticate', ',');
        Resp(Observer, 'ranges_bad', 'Accept-Ranges', 'a b');
        Resp(Observer, 'ctype_on_response', 'Content-Type', 'text/plain');
        Observer.Expect('wwwauth_bad', 'ret=Yes get=E');
        Observer.Expect('ranges_bad', 'ret=No get=E');
        Observer.Expect('ctype_on_response', 'ret=No get=E');
        Observer.Verify();
    end;

    // Writer PY (2026-10-20): probes-needed "HTTP" row http-get-values-missing-error (the text and code of the error HttpHeaders.GetValues raises
    // as a statement on request, response and client headers) and row http-headers-add-used-result (the last error after an Add that answered false).
    local procedure GetStatement(var Observer: Codeunit "Probe Observer"; var H: HttpHeaders; ObsKey: Text; N: Text)
    var
        Vals: List of [Text];
        Ret: Boolean;
    begin
        ClearLastError();
        if TryGetValues(H, N, Vals) then
            Observer.Observe(ObsKey, 'ok n=' + Format(Vals.Count()))
        else
            Observer.Observe(ObsKey, 'E[' + GetLastErrorText() + '|' + GetLastErrorCode() + ']');
        ClearLastError();
        Ret := H.GetValues(N, Vals);
        Observer.Observe(ObsKey + '_expr', Format(Ret) + ' n=' + Format(Vals.Count()) + ' last=[' + GetLastErrorText() + '|' + GetLastErrorCode() + ']');
    end;

    [Test]
    procedure PY_GetValues_Statement_RequestHeaders()
    var
        Observer: Codeunit "Probe Observer";
        R: HttpRequestMessage;
        H: HttpHeaders;
    begin
        R.GetHeaders(H);
        GetStatement(Observer, H, 'missing', 'X-None');
        GetStatement(Observer, H, 'bad_name', 'Bad Name');
        GetStatement(Observer, H, 'content_name', 'Content-Type');
        Observer.Expect('missing', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('missing_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('bad_name', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('bad_name_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('content_name', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('content_name_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Verify();
    end;

    [Test]
    procedure PY_GetValues_Statement_ResponseHeaders()
    var
        Observer: Codeunit "Probe Observer";
        R: HttpResponseMessage;
        H: HttpHeaders;
    begin
        H := R.Headers();
        GetStatement(Observer, H, 'missing', 'X-None');
        GetStatement(Observer, H, 'bad_name', 'Bad Name');
        GetStatement(Observer, H, 'content_name', 'Content-Type');
        Observer.Expect('missing', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('missing_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('bad_name', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('bad_name_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('content_name', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('content_name_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Verify();
    end;

    [Test]
    procedure PY_GetValues_Statement_ClientHeaders()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        H: HttpHeaders;
    begin
        H := Client.DefaultRequestHeaders();
        GetStatement(Observer, H, 'missing', 'X-None');
        GetStatement(Observer, H, 'bad_name', 'Bad Name');
        GetStatement(Observer, H, 'content_name', 'Content-Type');
        Observer.Expect('missing', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('missing_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('bad_name', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('bad_name_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('content_name', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('content_name_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Verify();
    end;

    [Test]
    procedure PY_GetValues_Statement_ContentHeaders_EmptyName()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
    begin
        C.GetHeaders(H);
        GetStatement(Observer, H, 'empty', '');
        GetStatement(Observer, H, 'request_name', 'Accept');
        Observer.Expect('empty', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('empty_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('request_name', 'E[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Expect('request_name_expr', 'No n=0 last=[Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.|InvalidHeader]');
        Observer.Verify();
    end;

    local procedure AddLastError(var Observer: Codeunit "Probe Observer"; var H: HttpHeaders; ObsKey: Text; N: Text; V: Text)
    var
        Ret: Boolean;
    begin
        asserterror Error('prior error');
        Ret := H.Add(N, V);
        Observer.Observe(ObsKey + '_after_prior', Format(Ret) + ' [' + GetLastErrorText() + '|' + GetLastErrorCode() + ']');
        ClearLastError();
        Ret := H.Add(N, V);
        Observer.Observe(ObsKey + '_after_clear', Format(Ret) + ' [' + GetLastErrorText() + '|' + GetLastErrorCode() + ']');
    end;

    [Test]
    procedure PY_AddFalse_LastError_Request()
    var
        Observer: Codeunit "Probe Observer";
        R: HttpRequestMessage;
        H: HttpHeaders;
    begin
        R.GetHeaders(H);
        AddLastError(Observer, H, 'bad_name', 'Bad Name', 'x');
        AddLastError(Observer, H, 'content_name', 'Content-Type', 'text/plain');
        AddLastError(Observer, H, 'bad_value', 'Accept', 'json');
        AddLastError(Observer, H, 'ok', 'X-Ok', 'v');
        Observer.Expect('bad_name_after_prior', 'No [Invalid HTTP header. Please, make sure the format of the header is correct.|InvalidHeader:Format]');
        Observer.Expect('bad_name_after_clear', 'No [Invalid HTTP header. Please, make sure the format of the header is correct.|InvalidHeader:Format]');
        Observer.Expect('content_name_after_prior', 'No [The requested operation cannot be performed in this context.|InvalidOperation]');
        Observer.Expect('content_name_after_clear', 'No [The requested operation cannot be performed in this context.|InvalidOperation]');
        Observer.Expect('bad_value_after_prior', 'No [Invalid HTTP header. Please, make sure the format of the header is correct.|InvalidHeader:Format]');
        Observer.Expect('bad_value_after_clear', 'No [Invalid HTTP header. Please, make sure the format of the header is correct.|InvalidHeader:Format]');
        Observer.Expect('ok_after_prior', 'Yes [prior error|Dialog]');
        Observer.Expect('ok_after_clear', 'Yes [|]');
        Observer.Verify();
    end;

    [Test]
    procedure PY_AddFalse_LastError_ContentAndResponse()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        R: HttpResponseMessage;
        H: HttpHeaders;
        H2: HttpHeaders;
        Lf: Char;
    begin
        Lf := 10;
        C.GetHeaders(H);
        AddLastError(Observer, H, 'content_request_name', 'Accept', 'a/b');
        AddLastError(Observer, H, 'content_bad_value', 'Content-Type', 'bad');
        H2 := R.Headers();
        AddLastError(Observer, H2, 'response_content_name', 'Content-Type', 'text/plain');
        AddLastError(Observer, H2, 'response_line_break', 'X-A', 'a' + Format(Lf) + 'b');
        Observer.Expect('content_request_name_after_prior', 'No [The requested operation cannot be performed in this context.|InvalidOperation]');
        Observer.Expect('content_request_name_after_clear', 'No [The requested operation cannot be performed in this context.|InvalidOperation]');
        Observer.Expect('content_bad_value_after_prior', 'No [Invalid HTTP header. Please, make sure the format of the header is correct.|InvalidHeader:Format]');
        Observer.Expect('content_bad_value_after_clear', 'No [Invalid HTTP header. Please, make sure the format of the header is correct.|InvalidHeader:Format]');
        Observer.Expect('response_content_name_after_prior', 'No [The requested operation cannot be performed in this context.|InvalidOperation]');
        Observer.Expect('response_content_name_after_clear', 'No [The requested operation cannot be performed in this context.|InvalidOperation]');
        Observer.Expect('response_line_break_after_prior', 'No [Invalid HTTP header. Please, make sure the format of the header is correct.|InvalidHeader:Format]');
        Observer.Expect('response_line_break_after_clear', 'No [Invalid HTTP header. Please, make sure the format of the header is correct.|InvalidHeader:Format]');
        Observer.Verify();
    end;

    // Writer SE (2026-10-25, tests SE_*): al-runtime-rs assumption http-headers-add-used-result: the last error after an Add that answered false,
    // for an empty name, on client headers, and in the "if not H.Add(..) then" form.
    [Test]
    procedure SE_AddFalse_LastError_EmptyName()
    var
        Observer: Codeunit "Probe Observer";
        R: HttpRequestMessage;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
    begin
        R.GetHeaders(H);
        AddLastError(Observer, H, 'request_empty', '', 'x');
        C.GetHeaders(H2);
        AddLastError(Observer, H2, 'content_empty', '', 'x');
        Observer.Finish();
    end;

    [Test]
    procedure SE_AddFalse_LastError_ClientHeaders()
    var
        Observer: Codeunit "Probe Observer";
        Client: HttpClient;
        H: HttpHeaders;
    begin
        H := Client.DefaultRequestHeaders();
        AddLastError(Observer, H, 'client_bad_value', 'Accept', 'json');
        AddLastError(Observer, H, 'client_content_name', 'Content-Type', 'text/plain');
        AddLastError(Observer, H, 'client_empty', '', 'x');
        Observer.Finish();
    end;

    [Test]
    procedure SE_AddFalse_LastError_IfNotForm()
    var
        Observer: Codeunit "Probe Observer";
        R: HttpRequestMessage;
        H: HttpHeaders;
        Branch: Text;
    begin
        R.GetHeaders(H);
        ClearLastError();
        Branch := 'then-not-taken';
        if not H.Add('Accept', 'json') then
            Branch := 'then-taken [' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        Observer.Observe('bad_value', Branch);
        ClearLastError();
        Branch := 'then-not-taken';
        if not H.Add('Content-Type', 'text/plain') then
            Branch := 'then-taken [' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        Observer.Observe('content_name', Branch);
        ClearLastError();
        Branch := 'then-not-taken';
        if not H.Add('', 'x') then
            Branch := 'then-taken [' + GetLastErrorText() + '|' + GetLastErrorCode() + ']';
        Observer.Observe('empty_name', Branch);
        Observer.Observe('keys', Format(H.Keys().Count()));
        Observer.Finish();
    end;
}
