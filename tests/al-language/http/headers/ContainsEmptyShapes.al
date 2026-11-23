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
        ClearLastError();
        Request.GetHeaders(Headers);
        Observer.Observe('add|ok', Format(TryAddHeader(Headers, 'X-A', 'v')));
        Headers.Remove('X-A');
        Cell('afterRemove', Headers);
        Observer.Observe('afterRemove|keys', Format(Headers.Keys().Count()));
        Observer.Expect('add|ok', 'Yes');
        Observer.Expect('afterRemove|ok', 'No');
        Observer.Expect('afterRemove|found', 'Yes');
        Observer.Expect('afterRemove|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('afterRemove|code', 'InvalidHeader:Argument');
        Observer.Expect('afterRemove|keys', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Cell2_ClientAddThenClear()
    var
        Client: HttpClient;
        Headers: HttpHeaders;
    begin
        ClearLastError();
        Headers := Client.DefaultRequestHeaders();
        Observer.Observe('add|ok', Format(TryAddHeader(Headers, 'X-A', 'v')));
        Headers.Clear();
        Cell('afterClear', Headers);
        Headers := Client.DefaultRequestHeaders();
        Cell('newHandle', Headers);
        Observer.Expect('add|ok', 'Yes');
        Observer.Expect('afterClear|ok', 'No');
        Observer.Expect('afterClear|found', 'Yes');
        Observer.Expect('afterClear|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('afterClear|code', 'InvalidHeader:Argument');
        Observer.Expect('newHandle|ok', 'No');
        Observer.Expect('newHandle|found', 'Yes');
        Observer.Expect('newHandle|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('newHandle|code', 'InvalidHeader:Argument');
        Observer.Verify();
    end;

    [Test]
    procedure Cell3_ContentTypeRemovedAndReadded()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
    begin
        ClearLastError();
        Content.WriteFrom('body');
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Cell('removed', Headers);
        Observer.Observe('readd|ok', Format(TryAddHeader(Headers, 'Content-Type', 'text/plain; charset=utf-8')));
        Cell('readded', Headers);
        ContentCell('content', Content);
        Observer.Expect('removed|ok', 'No');
        Observer.Expect('removed|found', 'Yes');
        Observer.Expect('removed|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('removed|code', 'InvalidHeader:Argument');
        Observer.Expect('readd|ok', 'Yes');
        Observer.Expect('readded|ok', 'No');
        Observer.Expect('readded|found', 'Yes');
        Observer.Expect('readded|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('readded|code', 'InvalidHeader:Argument');
        Observer.Expect('content|ok', 'No');
        Observer.Expect('content|found', 'Yes');
        Observer.Expect('content|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('content|code', 'InvalidHeader:Argument');
        Observer.Expect('content|type', 'text/plain; charset=utf-8');
        Observer.Expect('content|length', 'No');
        Observer.Expect('content|body', 'body');
        Observer.Verify();
    end;

    // ---- cells 4 to 8 ----

    [Test]
    procedure Cell4_StandaloneContentAfterOneWrite()
    var
        Content: HttpContent;
    begin
        ClearLastError();
        Content.WriteFrom('body');
        ContentCell('written', Content);
        Observer.Expect('written|ok', 'No');
        Observer.Expect('written|found', 'Yes');
        Observer.Expect('written|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('written|code', 'InvalidHeader:Argument');
        Observer.Expect('written|type', 'text/plain; charset=utf-8');
        Observer.Expect('written|length', 'No');
        Observer.Expect('written|body', 'body');
        Observer.Verify();
    end;

    [Test]
    procedure Cell5_ContentAfterTwoTextWrites()
    var
        Content: HttpContent;
    begin
        ClearLastError();
        Content.WriteFrom('one');
        Content.WriteFrom('two');
        ContentCell('twice', Content);
        Observer.Expect('twice|ok', 'No');
        Observer.Expect('twice|found', 'Yes');
        Observer.Expect('twice|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('twice|code', 'InvalidHeader:Argument');
        Observer.Expect('twice|type', 'text/plain; charset=utf-8');
        Observer.Expect('twice|length', 'No');
        Observer.Expect('twice|body', 'two');
        Observer.Verify();
    end;

    [Test]
    procedure Cell6_ContentAfterStreamWrite()
    var
        Content: HttpContent;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        ClearLastError();
        Stream(Blob, InS, 'from stream');
        Content.WriteFrom(InS);
        ContentCell('stream', Content);
        Observer.Expect('stream|ok', 'No');
        Observer.Expect('stream|found', 'Yes');
        Observer.Expect('stream|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('stream|code', 'InvalidHeader:Argument');
        Observer.Expect('stream|type', 'text/plain; charset=utf-8');
        Observer.Expect('stream|length', 'No');
        Observer.Expect('stream|body', 'from stream');
        Observer.Verify();
    end;

    [Test]
    procedure Cell7_ContentAfterWriteThenClear()
    var
        Content: HttpContent;
    begin
        ClearLastError();
        Content.WriteFrom('one');
        Content.Clear();
        ContentCell('cleared', Content);
        Observer.Expect('cleared|ok', 'No');
        Observer.Expect('cleared|found', 'Yes');
        Observer.Expect('cleared|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('cleared|code', 'InvalidHeader:Argument');
        Observer.Expect('cleared|type', 'text/plain; charset=utf-8');
        Observer.Expect('cleared|length', 'No');
        Observer.Expect('cleared|body', '');
        Observer.Verify();
    end;

    [Test]
    procedure Cell8_CopyOfWrittenContent()
    var
        Content: HttpContent;
        Copy: HttpContent;
    begin
        ClearLastError();
        Content.WriteFrom('one');
        Copy := Content;
        ContentCell('copy', Copy);
        ContentCell('source', Content);
        Observer.Expect('copy|ok', 'No');
        Observer.Expect('copy|found', 'Yes');
        Observer.Expect('copy|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('copy|code', 'InvalidHeader:Argument');
        Observer.Expect('copy|type', 'text/plain; charset=utf-8');
        Observer.Expect('copy|length', 'No');
        Observer.Expect('copy|body', 'one');
        Observer.Expect('source|ok', 'No');
        Observer.Expect('source|found', 'Yes');
        Observer.Expect('source|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('source|code', 'InvalidHeader:Argument');
        Observer.Expect('source|type', 'text/plain; charset=utf-8');
        Observer.Expect('source|length', 'No');
        Observer.Expect('source|body', 'one');
        Observer.Verify();
    end;

    // ---- cell b: a response never sent ----

    [Test]
    procedure CellB_ResponseContentWrittenNeverSent()
    var
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
    begin
        ClearLastError();
        Response.Content.WriteFrom('x');
        ResponseContentCell('responseContent', Response);
        Headers := Response.Headers();
        Cell('responseHeaders', Headers);
        Observer.Expect('responseContent|ok', 'No');
        Observer.Expect('responseContent|found', 'Yes');
        Observer.Expect('responseContent|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('responseContent|code', 'InvalidHeader:Argument');
        Observer.Expect('responseContent|type', 'text/plain; charset=utf-8');
        Observer.Expect('responseContent|length', 'No');
        Observer.Expect('responseContent|body', 'x');
        Observer.Expect('responseHeaders|ok', 'No');
        Observer.Expect('responseHeaders|found', 'Yes');
        Observer.Expect('responseHeaders|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('responseHeaders|code', 'InvalidHeader:Argument');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('request|add', 'Yes');
        Observer.Expect('request|ok', 'No');
        Observer.Expect('request|found', 'Yes');
        Observer.Expect('request|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('request|code', 'InvalidHeader:Argument');
        Observer.Expect('response|add', 'Yes');
        Observer.Expect('response|ok', 'No');
        Observer.Expect('response|found', 'Yes');
        Observer.Expect('response|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('response|code', 'InvalidHeader:Argument');
        Observer.Expect('client|add', 'Yes');
        Observer.Expect('client|ok', 'No');
        Observer.Expect('client|found', 'Yes');
        Observer.Expect('client|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('client|code', 'InvalidHeader:Argument');
        Observer.Expect('content|add', 'Yes');
        Observer.Expect('content|ok', 'No');
        Observer.Expect('content|found', 'Yes');
        Observer.Expect('content|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('content|code', 'InvalidHeader:Argument');
        Observer.Verify();
    end;

    [Test]
    procedure A1_PlainAdd_ContentOwnHeader()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
    begin
        ClearLastError();
        Content.WriteFrom('x');
        Content.GetHeaders(Headers);
        Observer.Observe('content|add', Format(TryAddHeader(Headers, 'Content-Language', 'en')));
        Cell('content', Headers);
        Observer.Expect('content|add', 'Yes');
        Observer.Expect('content|ok', 'No');
        Observer.Expect('content|found', 'Yes');
        Observer.Expect('content|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('content|code', 'InvalidHeader:Argument');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('request|call', 'Yes');
        Observer.Expect('request|added', 'Yes');
        Observer.Expect('request|ok', 'No');
        Observer.Expect('request|found', 'Yes');
        Observer.Expect('request|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('request|code', 'InvalidHeader:Argument');
        Observer.Expect('response|call', 'Yes');
        Observer.Expect('response|added', 'Yes');
        Observer.Expect('response|ok', 'No');
        Observer.Expect('response|found', 'Yes');
        Observer.Expect('response|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('response|code', 'InvalidHeader:Argument');
        Observer.Expect('client|call', 'Yes');
        Observer.Expect('client|added', 'Yes');
        Observer.Expect('client|ok', 'No');
        Observer.Expect('client|found', 'Yes');
        Observer.Expect('client|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('client|code', 'InvalidHeader:Argument');
        Observer.Verify();
    end;

    [Test]
    procedure A2_TryAddWithoutValidation_Refused()
    var
        Request: HttpRequestMessage;
        Headers: HttpHeaders;
        Added: Boolean;
    begin
        ClearLastError();
        Request.GetHeaders(Headers);
        Observer.Observe('bad|call', Format(TryAddNoValidation(Headers, 'X A', 'v', Added)));
        Observer.Observe('bad|added', Format(Added));
        Observer.ObserveError('bad|err');
        Cell('afterBad', Headers);
        Observer.Expect('bad|call', 'Yes');
        Observer.Expect('bad|added', 'No');
        Observer.Expect('bad|err|text', '');
        Observer.Expect('bad|err|code', '');
        Observer.Expect('afterBad|ok', 'No');
        Observer.Expect('afterBad|found', 'Yes');
        Observer.Expect('afterBad|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('afterBad|code', 'InvalidHeader:Argument');
        Observer.Verify();
    end;

    // ---- A3: SetCookie ----

    [Test]
    procedure A3_SetCookie_RequestHeaders()
    var
        Request: HttpRequestMessage;
        Headers: HttpHeaders;
    begin
        ClearLastError();
        Observer.Observe('set', Format(Request.SetCookie('n', 'v')));
        Request.GetHeaders(Headers);
        Cell('request', Headers);
        Observer.Observe('request|cookie', Format(Headers.Contains('Cookie')));
        Observer.Expect('set', 'Yes');
        Observer.Expect('request|ok', 'No');
        Observer.Expect('request|found', 'Yes');
        Observer.Expect('request|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('request|code', 'InvalidHeader:Argument');
        Observer.Expect('request|cookie', 'Yes');
        Observer.Verify();
    end;

    // ---- A4: a client setting that rebuilds the client ----

    local procedure ClientSettingCells(Setting: Integer)
    var
        Client: HttpClient;
        Old: HttpHeaders;
        Fresh: HttpHeaders;
    begin
        Old := Client.DefaultRequestHeaders();
        Old.Add('X-A', 'v');
        Observer.Observe('set' + Format(Setting), Format(TryClient(Client, Setting)));
        Observer.ObserveError('set' + Format(Setting) + '|err');
        Cell('old' + Format(Setting), Old);
        Fresh := Client.DefaultRequestHeaders();
        Cell('new' + Format(Setting), Fresh);
        Observer.Observe('new' + Format(Setting) + '|x-a', Format(Fresh.Contains('X-A')));
    end;

    [Test]
    procedure A4_ClientSettings_OldAndNewHandle()
    var
        Setting: Integer;
    begin
        ClearLastError();
        for Setting := 1 to 4 do
            ClientSettingCells(Setting);
        Observer.Expect('set1', 'Yes');
        Observer.Expect('set1|err|text', '');
        Observer.Expect('set1|err|code', '');
        Observer.Expect('old1|ok', 'No');
        Observer.Expect('old1|found', 'Yes');
        Observer.Expect('old1|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('old1|code', 'InvalidHeader:Argument');
        Observer.Expect('new1|ok', 'No');
        Observer.Expect('new1|found', 'Yes');
        Observer.Expect('new1|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('new1|code', 'InvalidHeader:Argument');
        Observer.Expect('new1|x-a', 'Yes');
        Observer.Expect('set2', 'Yes');
        Observer.Expect('set2|err|text', '');
        Observer.Expect('set2|err|code', '');
        Observer.Expect('old2|ok', 'No');
        Observer.Expect('old2|found', 'Yes');
        Observer.Expect('old2|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('old2|code', 'InvalidHeader:Argument');
        Observer.Expect('new2|ok', 'No');
        Observer.Expect('new2|found', 'Yes');
        Observer.Expect('new2|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('new2|code', 'InvalidHeader:Argument');
        Observer.Expect('new2|x-a', 'No');
        Observer.Expect('set3', 'Yes');
        Observer.Expect('set3|err|text', '');
        Observer.Expect('set3|err|code', '');
        Observer.Expect('old3|ok', 'No');
        Observer.Expect('old3|found', 'Yes');
        Observer.Expect('old3|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('old3|code', 'InvalidHeader:Argument');
        Observer.Expect('new3|ok', 'No');
        Observer.Expect('new3|found', 'Yes');
        Observer.Expect('new3|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('new3|code', 'InvalidHeader:Argument');
        Observer.Expect('new3|x-a', 'Yes');
        Observer.Expect('set4', 'Yes');
        Observer.Expect('set4|err|text', '');
        Observer.Expect('set4|err|code', '');
        Observer.Expect('old4|ok', 'No');
        Observer.Expect('old4|found', 'Yes');
        Observer.Expect('old4|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('old4|code', 'InvalidHeader:Argument');
        Observer.Expect('new4|ok', 'No');
        Observer.Expect('new4|found', 'Yes');
        Observer.Expect('new4|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('new4|code', 'InvalidHeader:Argument');
        Observer.Expect('new4|x-a', 'Yes');
        Observer.Verify();
    end;

    // AddCertificate with a value that is not a certificate (split from the loop above: one observation message holds at most 1800 characters).
    [Test]
    procedure A4_ClientSettings_AddCertificate()
    begin
        ClearLastError();
        ClientSettingCells(5);
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
        ClearLastError();
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
        Observer.Expect('secret|ok', 'No');
        Observer.Expect('secret|found', 'Yes');
        Observer.Expect('secret|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('secret|code', 'InvalidHeader:Argument');
        Observer.Expect('secret|type', '<absent>');
        Observer.Expect('secret|length', 'No');
        Observer.Expect('secret|isSecret', 'Yes');
        Observer.Expect('secret|read', 'Yes');
        Observer.Expect('secret|isEmpty', 'No');
        Observer.Expect('afterRead|ok', 'No');
        Observer.Expect('afterRead|found', 'Yes');
        Observer.Expect('afterRead|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('afterRead|code', 'InvalidHeader:Argument');
        Observer.Verify();
    end;

    // ---- A6: a content after ReadAs ----

    [Test]
    procedure A6_ContentAfterReadAsText()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Txt: Text;
    begin
        ClearLastError();
        Content.WriteFrom('x');
        Observer.Observe('read', Format(Content.ReadAs(Txt)));
        Content.GetHeaders(Headers);
        Cell('afterRead', Headers);
        Observer.Observe('afterRead|type', ContentType(Headers));
        Observer.Observe('afterRead|length', Format(Headers.Contains('Content-Length')));
        Observer.Observe('afterRead|body', Txt);
        Observer.Expect('read', 'Yes');
        Observer.Expect('afterRead|ok', 'No');
        Observer.Expect('afterRead|found', 'Yes');
        Observer.Expect('afterRead|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('afterRead|code', 'InvalidHeader:Argument');
        Observer.Expect('afterRead|type', 'text/plain; charset=utf-8');
        Observer.Expect('afterRead|length', 'Yes');
        Observer.Expect('afterRead|body', 'x');
        Observer.Verify();
    end;

    [Test]
    procedure A6_ContentAfterReadAsStream()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        InS: InStream;
    begin
        ClearLastError();
        Content.WriteFrom('x');
        Observer.Observe('read', Format(Content.ReadAs(InS)));
        Content.GetHeaders(Headers);
        Cell('afterRead', Headers);
        Observer.Observe('afterRead|length', Format(Headers.Contains('Content-Length')));
        Observer.Expect('read', 'Yes');
        Observer.Expect('afterRead|ok', 'No');
        Observer.Expect('afterRead|found', 'Yes');
        Observer.Expect('afterRead|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('afterRead|code', 'InvalidHeader:Argument');
        Observer.Expect('afterRead|length', 'No');
        Observer.Verify();
    end;

    // ---- A7: Request.Content := C ----

    [Test]
    procedure A7_RequestContentAssignedFromWrittenContent()
    var
        Request: HttpRequestMessage;
        Content: HttpContent;
    begin
        ClearLastError();
        Content.WriteFrom('x');
        Request.Content := Content;
        RequestContentCell('assigned', Request);
        ContentCell('source', Content);
        Observer.Expect('assigned|ok', 'No');
        Observer.Expect('assigned|found', 'Yes');
        Observer.Expect('assigned|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('assigned|code', 'InvalidHeader:Argument');
        Observer.Expect('assigned|type', 'text/plain; charset=utf-8');
        Observer.Expect('assigned|length', 'No');
        Observer.Expect('assigned|body', 'x');
        Observer.Expect('source|ok', 'No');
        Observer.Expect('source|found', 'Yes');
        Observer.Expect('source|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('source|code', 'InvalidHeader:Argument');
        Observer.Expect('source|type', 'text/plain; charset=utf-8');
        Observer.Expect('source|length', 'No');
        Observer.Expect('source|body', 'x');
        Observer.Verify();
    end;

    [Test]
    procedure A7_RequestContentAssignedFromFreshContent()
    var
        Request: HttpRequestMessage;
        Content: HttpContent;
    begin
        ClearLastError();
        Request.Content := Content;
        RequestContentCell('assigned', Request);
        Observer.Expect('assigned|ok', 'No');
        Observer.Expect('assigned|found', 'Yes');
        Observer.Expect('assigned|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('assigned|code', 'InvalidHeader:Argument');
        Observer.Expect('assigned|type', 'text/plain; charset=utf-8');
        Observer.Expect('assigned|length', 'No');
        Observer.Expect('assigned|body', '');
        Observer.Verify();
    end;

    [Test]
    procedure A7_RequestContentAssignedThenWritten()
    var
        Request: HttpRequestMessage;
        Content: HttpContent;
    begin
        ClearLastError();
        Content.WriteFrom('x');
        Request.Content := Content;
        Request.Content.WriteFrom('y');
        RequestContentCell('assigned', Request);
        Observer.Expect('assigned|ok', 'No');
        Observer.Expect('assigned|found', 'Yes');
        Observer.Expect('assigned|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('assigned|code', 'InvalidHeader:Argument');
        Observer.Expect('assigned|type', 'text/plain; charset=utf-8');
        Observer.Expect('assigned|length', 'No');
        Observer.Expect('assigned|body', 'y');
        Observer.Verify();
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
        ClearLastError();
        Ok := Client.Get('https://lt-hcs.invalid/', Response);
        Observer.Observe('get', Format(Ok));
        Observer.ObserveError('get|err');
        Headers := Response.Headers();
        Cell('headers', Headers);
        ResponseContentCell('content', Response);
        Observer.Expect('get', 'No');
        Observer.Expect('get|err|text', 'There was an error while executing the HTTP request. Make sure you are connecting to a valid endpoint.');
        Observer.Expect('get|err|code', 'HttpRequest:Socket');
        Observer.Expect('headers|ok', 'No');
        Observer.Expect('headers|found', 'Yes');
        Observer.Expect('headers|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('headers|code', 'InvalidHeader:Argument');
        Observer.Expect('content|ok', 'No');
        Observer.Expect('content|found', 'Yes');
        Observer.Expect('content|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('content|code', 'InvalidHeader:Argument');
        Observer.Expect('content|type', '<absent>');
        Observer.Expect('content|length', 'No');
        Observer.Expect('content|body', '');
        Observer.Verify();
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
        ClearLastError();
        Ok := Client.Get('https://lt-hcs.invalid/', Response);
        Observer.Observe('get', Format(Ok));
        ClearLastError();
        Response.Content.GetHeaders(Headers);
        Cell('contentHeaders', Headers);
        Headers := Response.Headers();
        Observer.Observe('headers|x-a', Format(Headers.Contains('X-A')));
        Observer.Expect('get', 'No');
        Observer.Expect('contentHeaders|ok', 'No');
        Observer.Expect('contentHeaders|found', 'Yes');
        Observer.Expect('contentHeaders|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('contentHeaders|code', 'InvalidHeader:Argument');
        Observer.Expect('headers|x-a', 'No');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('send', 'No');
        Observer.Expect('requestHeaders|ok', 'No');
        Observer.Expect('requestHeaders|found', 'Yes');
        Observer.Expect('requestHeaders|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('requestHeaders|code', 'InvalidHeader:Argument');
        Observer.Expect('responseHeaders|ok', 'No');
        Observer.Expect('responseHeaders|found', 'Yes');
        Observer.Expect('responseHeaders|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('responseHeaders|code', 'InvalidHeader:Argument');
        Observer.Expect('responseContent|ok', 'No');
        Observer.Expect('responseContent|found', 'Yes');
        Observer.Expect('responseContent|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('responseContent|code', 'InvalidHeader:Argument');
        Observer.Expect('responseContent|type', '<absent>');
        Observer.Expect('responseContent|length', 'No');
        Observer.Expect('responseContent|body', '');
        Observer.Verify();
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
        ClearLastError();
        Request.SetRequestUri('https://lt-hcs.invalid/');
        Request.Method := 'POST';
        Request.Content.WriteFrom('first');
        ClearLastError();
        Ok := Client.Send(Request, Response);
        Observer.Observe('send', Format(Ok));
        ClearLastError();
        Request.Content.WriteFrom('late');
        RequestContentCell('afterSend', Request);
        Observer.Expect('send', 'No');
        Observer.Expect('afterSend|ok', 'No');
        Observer.Expect('afterSend|found', 'Yes');
        Observer.Expect('afterSend|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('afterSend|code', 'InvalidHeader:Argument');
        Observer.Expect('afterSend|type', 'text/plain; charset=utf-8');
        Observer.Expect('afterSend|length', 'No');
        Observer.Expect('afterSend|body', 'late');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSend_TextWriteOnRequestWithoutContent()
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Ok: Boolean;
    begin
        ClearLastError();
        Request.SetRequestUri('https://lt-hcs.invalid/');
        Request.Method := 'GET';
        ClearLastError();
        Ok := Client.Send(Request, Response);
        Observer.Observe('send', Format(Ok));
        ClearLastError();
        Request.Content.WriteFrom('late');
        RequestContentCell('afterSend', Request);
        Observer.Expect('send', 'No');
        Observer.Expect('afterSend|ok', 'No');
        Observer.Expect('afterSend|found', 'Yes');
        Observer.Expect('afterSend|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('afterSend|code', 'InvalidHeader:Argument');
        Observer.Expect('afterSend|type', 'text/plain; charset=utf-8');
        Observer.Expect('afterSend|length', 'No');
        Observer.Expect('afterSend|body', 'late');
        Observer.Verify();
    end;

    [Test]
    procedure AfterSend_TextWriteAfterPostOfStandaloneContent()
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
        Ok: Boolean;
    begin
        ClearLastError();
        Content.WriteFrom('first');
        ClearLastError();
        Ok := Client.Post('https://lt-hcs.invalid/', Content, Response);
        Observer.Observe('post', Format(Ok));
        ClearLastError();
        Content.WriteFrom('late');
        ContentCell('afterPost', Content);
        Observer.Expect('post', 'No');
        Observer.Expect('afterPost|ok', 'No');
        Observer.Expect('afterPost|found', 'Yes');
        Observer.Expect('afterPost|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('afterPost|code', 'InvalidHeader:Argument');
        Observer.Expect('afterPost|type', 'text/plain; charset=utf-8');
        Observer.Expect('afterPost|length', 'No');
        Observer.Expect('afterPost|body', 'late');
        Observer.Verify();
    end;
#endif
}
