// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 90341
// Probe (outside issues 6170, 6171): Clear of an HttpRequestMessage, an HttpContent, an HttpResponseMessage and an HttpClient that were filled the way a chunked upload fills them
//   (method, URI, headers, Content assigned to the request, then Clear and fill again). After Clear: method, URI, header count, the content of a request and of a copied content,
//   the headers of the content, and whether the variable can be filled and read again. The basic Clear of an empty-ish request and content is in platform/lt-system-database-members/ClearHttpXml.al.
// BC versions: 27-29

codeunit 90341 "LT UF Http Clear"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ClearRequest_AfterFilling()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        Req2: HttpRequestMessage;
        Cnt: HttpContent;
        Headers: HttpHeaders;
        Txt: Text;
    begin
        Cnt.WriteFrom('first body');
        Req.Method := 'PUT';
        Req.SetRequestUri('http://localhost/uf/chunk');
        Req.GetHeaders(Headers);
        Headers.Add('X-Chunk', '1');
        Req.Content := Cnt;
        Req.Content.ReadAs(Txt);
        Observer.Observe('before content', Txt);
        Observer.Observe('before header count', Format(Headers.Keys().Count()));
        Clear(Req);
        Observer.Observe('method', Req.Method);
        Observer.Observe('uri', '[' + Req.GetRequestUri() + ']');
        ClearLastError();
        asserterror Req.Content.ReadAs(Txt);
        Observer.ObserveError('content of cleared request');
        Clear(Req2);
        asserterror Req2.Content.ReadAs(Txt);
        Observer.ObserveError('content of fresh request');
        Clear(Headers);
        Req.GetHeaders(Headers);
        Observer.Observe('header count', Format(Headers.Keys().Count()));
        Observer.Observe('has header', Format(Headers.Contains('X-Chunk')));
        Observer.Observe('original content kept', Format(ReadContent(Cnt)));
        Req.Method := 'POST';
        Req.SetRequestUri('http://localhost/uf/next');
        Observer.Observe('refill method', Req.Method);
        Observer.Observe('refill uri', Req.GetRequestUri());
        Observer.Finish();
    end;

    [Test]
    procedure ClearContent_AfterFilling()
    var
        Observer: Codeunit "Probe Observer";
        Cnt: HttpContent;
        Req: HttpRequestMessage;
        Headers: HttpHeaders;
        Txt: Text;
        Values: List of [Text];
    begin
        Cnt.WriteFrom('first body');
        Cnt.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        Headers.Add('X-Part', 'one');
        Req.Content := Cnt;
        Observer.Observe('before header count', Format(Headers.Keys().Count()));
        Clear(Cnt);
        Cnt.ReadAs(Txt);
        Observer.Observe('read after clear', '[' + Txt + ']');
        Clear(Headers);
        Cnt.GetHeaders(Headers);
        Observer.Observe('header count after clear', Format(Headers.Keys().Count()));
        Observer.Observe('has Content-Type', Format(Headers.Contains('Content-Type')));
        Observer.Observe('has X-Part', Format(Headers.Contains('X-Part')));
        Observer.Observe('request content unchanged', ReadContent(Req.Content));
        Cnt.WriteFrom('second body');
        Clear(Txt);
        Cnt.ReadAs(Txt);
        Observer.Observe('refilled', Txt);
        Clear(Headers);
        Cnt.GetHeaders(Headers);
        Headers.GetValues('Content-Type', Values);
        Observer.Observe('refilled content type', Values.Get(1));
        Observer.Observe('refilled has X-Part', Format(Headers.Contains('X-Part')));
        Observer.Observe('is secret', Format(Cnt.IsSecretContent()));
        Observer.Finish();
    end;

    [Test]
    procedure ClearResponse_AndClient()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        Client: HttpClient;
        Headers: HttpHeaders;
        Txt: Text;
    begin
        Client.DefaultRequestHeaders().Add('X-Default', 'yes');
        Client.Timeout(1234);
        Observer.Observe('client default header', Format(Client.DefaultRequestHeaders().Contains('X-Default')));
        Clear(Client);
        Observer.Observe('client header after clear', Format(Client.DefaultRequestHeaders().Contains('X-Default')));
        Observer.Observe('client timeout after clear', Format(Client.Timeout()));
        Observer.Observe('response status', Format(Resp.HttpStatusCode()));
        Observer.Observe('response success', Format(Resp.IsSuccessStatusCode()));
        Clear(Resp);
        Observer.Observe('response status after clear', Format(Resp.HttpStatusCode()));
        Resp.Content.ReadAs(Txt);
        Observer.Observe('response content after clear', '[' + Txt + ']');
        Observer.Observe('response reason after clear', '[' + Resp.ReasonPhrase() + ']');
        Observer.Finish();
    end;

    local procedure ReadContent(Cnt: HttpContent): Text
    var
        Txt: Text;
    begin
        Cnt.ReadAs(Txt);
        exit('[' + Txt + ']');
    end;
}
