// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpheaders/httpheaders-contains-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: measured on BC 27.5, 28.5 and 29.0 service tiers (local observation, then the PR CI run); every literal asserted below is what they produced.
// HttpHeaders.Contains('') on every state a header collection can be in, inside a TryFunction: whether the call raises, the error text and code, the value
// it leaves in the Boolean, then the Content-Type, whether a Content-Length is in the bag and the body (content cells only).
// The cells: a plain Add; TryAddWithoutValidation; SetCookie; a client setting that rebuilds the client (Timeout, UseServerCertificateValidation,
// UseResponseCookies, AddCertificate) on a handle taken before and after; Add then Remove; Add then Clear; Content-Type removed and re-added;
// a standalone content after one WriteFrom(Text), after two, after WriteFrom(InStream), after WriteFrom then Clear, a copy of a written content;
// a secret content; a content after ReadAs; Request.Content := C; the response of a failed call; a text write on Request.Content after the request was sent.
// Handler-written responses are in tests/al-language-onprem/http/HttpHandlerResponseShapes.al.
// BC versions: 27, 28, 29 (the failed-call cells are BC28PLUS: on 27.5 the tier asks the outbound-request approval prompt, see LtDaSendFailure.al).

codeunit 70886 "LT HtT Contains Empty Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryContainsEmpty(var Headers: HttpHeaders; var Found: Boolean)
    begin
        Found := Headers.Contains('');
    end;

    [TryFunction]
    local procedure TryAddHeader(var Headers: HttpHeaders; Name: Text; Value: Text)
    begin
        Headers.Add(Name, Value);
    end;

    [TryFunction]
    local procedure TryAddNoValidation(var Headers: HttpHeaders; Name: Text; Value: Text; var Added: Boolean)
    begin
        Added := Headers.TryAddWithoutValidation(Name, Value);
    end;

    [TryFunction]
    local procedure TryClient(var Client: HttpClient; Setting: Integer)
    begin
        case Setting of
            1:
                Client.Timeout := 5000;
            2:
                Client.UseServerCertificateValidation(false);
            3:
                Client.UseServerCertificateValidation(true);
            4:
                Client.UseResponseCookies(false);
            5:
                Client.AddCertificate('MIIB', '');
        end;
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

    local procedure ContentCell(Name: Text; var Content: HttpContent)
    var
        Headers: HttpHeaders;
        Body: Text;
    begin
        Content.GetHeaders(Headers);
        Cell(Name, Headers);
        Observer.Observe(Name + '|type', ContentType(Headers));
        Observer.Observe(Name + '|length', Format(Headers.Contains('Content-Length')));
        Content.ReadAs(Body);
        Observer.Observe(Name + '|body', Body);
    end;

    local procedure RequestContentCell(Name: Text; var Request: HttpRequestMessage)
    var
        Headers: HttpHeaders;
        Body: Text;
    begin
        Request.Content.GetHeaders(Headers);
        Cell(Name, Headers);
        Observer.Observe(Name + '|type', ContentType(Headers));
        Observer.Observe(Name + '|length', Format(Headers.Contains('Content-Length')));
        Request.Content.ReadAs(Body);
        Observer.Observe(Name + '|body', Body);
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

    local procedure Stream(var Blob: Codeunit "Temp Blob"; var InS: InStream; Value: Text)
    var
        OutS: OutStream;
    begin
        Blob.CreateOutStream(OutS);
        OutS.WriteText(Value);
        Blob.CreateInStream(InS);
    end;

    // ---- cells 1 to 3 ----

    [Test]
    procedure Cell1_RequestAddThenRemove()
    var
        Request: HttpRequestMessage;
        Headers: HttpHeaders;
    begin
        Request.GetHeaders(Headers);
        Observer.Observe('add|ok', Format(TryAddHeader(Headers, 'X-A', 'v')));
        Headers.Remove('X-A');
        Cell('afterRemove', Headers);
        Observer.Observe('afterRemove|keys', Format(Headers.Keys().Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Cell2_ClientAddThenClear()
    var
        Client: HttpClient;
        Headers: HttpHeaders;
    begin
        Headers := Client.DefaultRequestHeaders();
        Observer.Observe('add|ok', Format(TryAddHeader(Headers, 'X-A', 'v')));
        Headers.Clear();
        Cell('afterClear', Headers);
        Headers := Client.DefaultRequestHeaders();
        Cell('newHandle', Headers);
        Observer.Finish();
    end;

    [Test]
    procedure Cell3_ContentTypeRemovedAndReadded()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
    begin
        Content.WriteFrom('body');
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Cell('removed', Headers);
        Observer.Observe('readd|ok', Format(TryAddHeader(Headers, 'Content-Type', 'text/plain; charset=utf-8')));
        Cell('readded', Headers);
        ContentCell('content', Content);
        Observer.Finish();
    end;

    // ---- cells 4 to 8 ----

    [Test]
    procedure Cell4_StandaloneContentAfterOneWrite()
    var
        Content: HttpContent;
    begin
        Content.WriteFrom('body');
        ContentCell('written', Content);
        Observer.Finish();
    end;

    [Test]
    procedure Cell5_ContentAfterTwoTextWrites()
    var
        Content: HttpContent;
    begin
        Content.WriteFrom('one');
        Content.WriteFrom('two');
        ContentCell('twice', Content);
        Observer.Finish();
    end;

    [Test]
    procedure Cell6_ContentAfterStreamWrite()
    var
        Content: HttpContent;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Stream(Blob, InS, 'from stream');
        Content.WriteFrom(InS);
        ContentCell('stream', Content);
        Observer.Finish();
    end;

    [Test]
    procedure Cell7_ContentAfterWriteThenClear()
    var
        Content: HttpContent;
    begin
        Content.WriteFrom('one');
        Content.Clear();
        ContentCell('cleared', Content);
        Observer.Finish();
    end;

    [Test]
    procedure Cell8_CopyOfWrittenContent()
    var
        Content: HttpContent;
        Copy: HttpContent;
    begin
        Content.WriteFrom('one');
        Copy := Content;
        ContentCell('copy', Copy);
        ContentCell('source', Content);
        Observer.Finish();
    end;

    // ---- cell b: a response never sent ----

    [Test]
    procedure CellB_ResponseContentWrittenNeverSent()
    var
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
    begin
        Response.Content.WriteFrom('x');
        ResponseContentCell('responseContent', Response);
        Headers := Response.Headers();
        Cell('responseHeaders', Headers);
        Observer.Finish();
    end;

    // ---- A1: a plain Add on the four receivers ----

    [Test]
    procedure A1_PlainAdd_FourReceivers()
    var
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
    begin
        Request.GetHeaders(Headers);
        Observer.Observe('request|add', Format(TryAddHeader(Headers, 'X-A', 'v')));
        Cell('request', Headers);
        Headers := Response.Headers();
        Observer.Observe('response|add', Format(TryAddHeader(Headers, 'X-A', 'v')));
        Cell('response', Headers);
        Headers := Client.DefaultRequestHeaders();
        Observer.Observe('client|add', Format(TryAddHeader(Headers, 'X-A', 'v')));
        Cell('client', Headers);
        Content.GetHeaders(Headers);
        Observer.Observe('content|add', Format(TryAddHeader(Headers, 'X-A', 'v')));
        Cell('content', Headers);
        Observer.Finish();
    end;

    [Test]
    procedure A1_PlainAdd_ContentOwnHeader()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
    begin
        Content.WriteFrom('x');
        Content.GetHeaders(Headers);
        Observer.Observe('content|add', Format(TryAddHeader(Headers, 'Content-Language', 'en')));
        Cell('content', Headers);
        Observer.Finish();
    end;

    // ---- A2: TryAddWithoutValidation ----

    [Test]
    procedure A2_TryAddWithoutValidation_Receivers()
    var
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Client: HttpClient;
        Headers: HttpHeaders;
        Added: Boolean;
    begin
        Request.GetHeaders(Headers);
        Observer.Observe('request|call', Format(TryAddNoValidation(Headers, 'X-A', 'v', Added)));
        Observer.Observe('request|added', Format(Added));
        Cell('request', Headers);
        Headers := Response.Headers();
        Observer.Observe('response|call', Format(TryAddNoValidation(Headers, 'X-A', 'v', Added)));
        Observer.Observe('response|added', Format(Added));
        Cell('response', Headers);
        Headers := Client.DefaultRequestHeaders();
        Observer.Observe('client|call', Format(TryAddNoValidation(Headers, 'X-A', 'v', Added)));
        Observer.Observe('client|added', Format(Added));
        Cell('client', Headers);
        Observer.Finish();
    end;

    [Test]
    procedure A2_TryAddWithoutValidation_Refused()
    var
        Request: HttpRequestMessage;
        Headers: HttpHeaders;
        Added: Boolean;
    begin
        Request.GetHeaders(Headers);
        Observer.Observe('bad|call', Format(TryAddNoValidation(Headers, 'X A', 'v', Added)));
        Observer.Observe('bad|added', Format(Added));
        Observer.ObserveError('bad|err');
        Cell('afterBad', Headers);
        Observer.Finish();
    end;

    // ---- A3: SetCookie ----

    [Test]
    procedure A3_SetCookie_RequestHeaders()
    var
        Request: HttpRequestMessage;
        Headers: HttpHeaders;
    begin
        Observer.Observe('set', Format(Request.SetCookie('n', 'v')));
        Request.GetHeaders(Headers);
        Cell('request', Headers);
        Observer.Observe('request|cookie', Format(Headers.Contains('Cookie')));
        Observer.Finish();
    end;

    // ---- A4: a client setting that rebuilds the client ----

    [Test]
    procedure A4_ClientSettings_OldAndNewHandle()
    var
        Client: HttpClient;
        Old: HttpHeaders;
        Fresh: HttpHeaders;
        Setting: Integer;
    begin
        for Setting := 1 to 5 do begin
            Clear(Client);
            Old := Client.DefaultRequestHeaders();
            Old.Add('X-A', 'v');
            Observer.Observe('set' + Format(Setting), Format(TryClient(Client, Setting)));
            Observer.ObserveError('set' + Format(Setting) + '|err');
            Cell('old' + Format(Setting), Old);
            Fresh := Client.DefaultRequestHeaders();
            Cell('new' + Format(Setting), Fresh);
            Observer.Observe('new' + Format(Setting) + '|x-a', Format(Fresh.Contains('X-A')));
        end;
        Observer.Finish();
    end;

    // ---- A5: a secret content ----

    [Test]
    procedure A5_SecretContent()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Secret: SecretText;
        Body: SecretText;
    begin
        Secret := SecretStrSubstNo('body');
        Content.WriteFrom(Secret);
        Content.GetHeaders(Headers);
        Cell('secret', Headers);
        Observer.Observe('secret|type', ContentType(Headers));
        Observer.Observe('secret|length', Format(Headers.Contains('Content-Length')));
        Observer.Observe('secret|isSecret', Format(Content.IsSecretContent()));
        Observer.Observe('secret|read', Format(Content.ReadAs(Body)));
        Observer.Observe('secret|isEmpty', Format(Body.IsEmpty()));
        Cell('afterRead', Headers);
        Observer.Finish();
    end;

    // ---- A6: a content after ReadAs ----

    [Test]
    procedure A6_ContentAfterReadAsText()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Txt: Text;
    begin
        Content.WriteFrom('x');
        Observer.Observe('read', Format(Content.ReadAs(Txt)));
        Content.GetHeaders(Headers);
        Cell('afterRead', Headers);
        Observer.Observe('afterRead|type', ContentType(Headers));
        Observer.Observe('afterRead|length', Format(Headers.Contains('Content-Length')));
        Observer.Observe('afterRead|body', Txt);
        Observer.Finish();
    end;

    [Test]
    procedure A6_ContentAfterReadAsStream()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        InS: InStream;
    begin
        Content.WriteFrom('x');
        Observer.Observe('read', Format(Content.ReadAs(InS)));
        Content.GetHeaders(Headers);
        Cell('afterRead', Headers);
        Observer.Observe('afterRead|length', Format(Headers.Contains('Content-Length')));
        Observer.Finish();
    end;

    // ---- A7: Request.Content := C ----

    [Test]
    procedure A7_RequestContentAssignedFromWrittenContent()
    var
        Request: HttpRequestMessage;
        Content: HttpContent;
    begin
        Content.WriteFrom('x');
        Request.Content := Content;
        RequestContentCell('assigned', Request);
        ContentCell('source', Content);
        Observer.Finish();
    end;

    [Test]
    procedure A7_RequestContentAssignedFromFreshContent()
    var
        Request: HttpRequestMessage;
        Content: HttpContent;
    begin
        Request.Content := Content;
        RequestContentCell('assigned', Request);
        Observer.Finish();
    end;

    [Test]
    procedure A7_RequestContentAssignedThenWritten()
    var
        Request: HttpRequestMessage;
        Content: HttpContent;
    begin
        Content.WriteFrom('x');
        Request.Content := Content;
        Request.Content.WriteFrom('y');
        RequestContentCell('assigned', Request);
        Observer.Finish();
    end;

#if BC28PLUS
    // ---- e: the response of a failed call ----

    [Test]
    procedure CellE_FailedCallResponse()
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Client.Get('https://lt-hcs.invalid/', Response);
        Observer.Observe('get', Format(Ok));
        Observer.ObserveError('get|err');
        Headers := Response.Headers();
        Cell('headers', Headers);
        ResponseContentCell('content', Response);
        Observer.Finish();
    end;

    [Test]
    procedure CellE_FailedCallResponse_ContentHandle()
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Client.Get('https://lt-hcs.invalid/', Response);
        Observer.Observe('get', Format(Ok));
        ClearLastError();
        Response.Content.GetHeaders(Headers);
        Cell('contentHeaders', Headers);
        Headers := Response.Headers();
        Observer.Observe('headers|x-a', Format(Headers.Contains('X-A')));
        Observer.Finish();
    end;

    [Test]
    procedure CellE_FailedSend_RequestHeadersAndContent()
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Ok: Boolean;
    begin
        Request.SetRequestUri('https://lt-hcs.invalid/');
        Request.Method := 'POST';
        Request.Content.WriteFrom('first');
        ClearLastError();
        Ok := Client.Send(Request, Response);
        Observer.Observe('send', Format(Ok));
        ClearLastError();
        Request.GetHeaders(Headers);
        Cell('requestHeaders', Headers);
        Headers := Response.Headers();
        Cell('responseHeaders', Headers);
        ResponseContentCell('responseContent', Response);
        Observer.Finish();
    end;

    // ---- a text write on Request.Content after the request was sent ----

    [Test]
    procedure AfterSend_TextWriteOnWrittenRequestContent()
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Ok: Boolean;
    begin
        Request.SetRequestUri('https://lt-hcs.invalid/');
        Request.Method := 'POST';
        Request.Content.WriteFrom('first');
        ClearLastError();
        Ok := Client.Send(Request, Response);
        Observer.Observe('send', Format(Ok));
        ClearLastError();
        Request.Content.WriteFrom('late');
        RequestContentCell('afterSend', Request);
        Observer.Finish();
    end;

    [Test]
    procedure AfterSend_TextWriteOnRequestWithoutContent()
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Ok: Boolean;
    begin
        Request.SetRequestUri('https://lt-hcs.invalid/');
        Request.Method := 'GET';
        ClearLastError();
        Ok := Client.Send(Request, Response);
        Observer.Observe('send', Format(Ok));
        ClearLastError();
        Request.Content.WriteFrom('late');
        RequestContentCell('afterSend', Request);
        Observer.Finish();
    end;

    [Test]
    procedure AfterSend_TextWriteAfterPostOfStandaloneContent()
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
        Ok: Boolean;
    begin
        Content.WriteFrom('first');
        ClearLastError();
        Ok := Client.Post('https://lt-hcs.invalid/', Content, Response);
        Observer.Observe('post', Format(Ok));
        ClearLastError();
        Content.WriteFrom('late');
        ContentCell('afterPost', Content);
        Observer.Finish();
    end;
#endif
}
