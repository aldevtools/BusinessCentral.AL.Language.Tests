// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 85720
// Probe: leads of corpus issue 671 (part F, items 31-34), without a request leaving the test: reading the content of a response twice (called on
// Resp.Content() each time against a variable that holds it), Clear on the content of a fresh HttpRequestMessage and its Content-Type header, a
// multi-line multipart body written from the InStream of a Blob field, and reading content written from an InStream more than once.
// The response content is filled with WriteFrom (a fresh HttpResponseMessage has a writable content, see network/lt-http/HttpResponse.al).
// What a send carries after WriteFrom(InStream) and ReadAs (item 34) needs an [HttpClientHandler], which only an OnPrem app can declare: not here.
// Facts: see the Expect lines of each test.
// BC versions: 27, 28, 29

table 85720 "LT DB Http Blob"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 85721 "LT DB Http Content Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Crlf(): Text
    var
        Cr: Char;
        Lf: Char;
    begin
        Cr := 13;
        Lf := 10;
        exit(Format(Cr) + Format(Lf));
    end;

    local procedure ReadAll(var InS: InStream) Result: Text
    var
        Line: Text;
        N: Integer;
    begin
        while not InS.EOS() do begin
            InS.ReadText(Line);
            N += 1;
            Result += '<' + Line + '>';
        end;
        Result := Format(N) + ':' + Result;
    end;

    local procedure FillBlob(var Rec: Record "LT DB Http Blob" temporary; Body: Text; var InS: InStream)
    var
        OutS: OutStream;
    begin
        Rec.Init();
        Rec.Id += 1;
        Rec.Data.CreateOutStream(OutS);
        OutS.WriteText(Body);
        Rec.Insert();
        Rec.Data.CreateInStream(InS);
    end;

    local procedure HeaderText(var H: HttpHeaders; Name: Text): Text
    var
        Values: array[5] of Text;
    begin
        if not H.Contains(Name) then
            exit('absent');
        H.GetValues(Name, Values);
        exit(Values[1]);
    end;

    [TryFunction]
    local procedure TryRequestContentHeaders(var Req: HttpRequestMessage; var H: HttpHeaders)
    begin
        Req.Content.GetHeaders(H);
    end;

    [TryFunction]
    local procedure TryRequestContentClear(var Req: HttpRequestMessage)
    begin
        Req.Content.Clear();
    end;

    [Test]
    procedure ResponseContent_ReadAsStreamTwice_Chained()
    // Issue 671 item 31 (microsoft/AL#7509): Resp.Content().ReadAs(InStream) called twice on the response.
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        InS1: InStream;
        InS2: InStream;
        Txt: Text;
    begin
        Resp.Content().WriteFrom('body');
        Observer.Observe('ok1', Format(Resp.Content().ReadAs(InS1)));
        Observer.Observe('first', ReadAll(InS1));
        Observer.Observe('ok2', Format(Resp.Content().ReadAs(InS2)));
        Observer.Observe('second', ReadAll(InS2));
        Observer.Observe('ok_text', Format(Resp.Content().ReadAs(Txt)));
        Observer.Observe('text_after', Txt);
        Observer.Expect('ok1', 'Yes');
        Observer.Expect('first', '1:<body>');
        Observer.Expect('ok2', 'Yes');
        Observer.Expect('second', '0:');
        Observer.Expect('ok_text', 'Yes');
        Observer.Expect('text_after', 'body');
        Observer.Verify();
    end;

    [Test]
    procedure ResponseContent_ReadAsStreamTwice_Assigned()
    // Issue 671 item 31: the same through Content := Resp.Content().
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        Content: HttpContent;
        InS1: InStream;
        InS2: InStream;
        InS3: InStream;
        Txt: Text;
    begin
        Resp.Content().WriteFrom('body');
        Content := Resp.Content();
        Observer.Observe('ok1', Format(Content.ReadAs(InS1)));
        Observer.Observe('first', ReadAll(InS1));
        Observer.Observe('ok2', Format(Content.ReadAs(InS2)));
        Observer.Observe('second', ReadAll(InS2));
        Observer.Observe('ok_chained', Format(Resp.Content().ReadAs(InS3)));
        Observer.Observe('chained_after', ReadAll(InS3));
        Observer.Observe('ok_text', Format(Content.ReadAs(Txt)));
        Observer.Observe('text_after', Txt);
        Observer.Expect('ok1', 'Yes');
        Observer.Expect('first', '1:<body>');
        Observer.Expect('ok2', 'Yes');
        Observer.Expect('second', '0:');
        Observer.Expect('ok_chained', 'Yes');
        Observer.Expect('chained_after', '1:<body>');
        Observer.Expect('ok_text', 'Yes');
        Observer.Expect('text_after', '');
        Observer.Verify();
    end;

    [Test]
    procedure ResponseContent_ReadAsTextTwice()
    // Issue 671 item 31: ReadAs(Text) twice, chained and through a variable.
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        Content: HttpContent;
        T1: Text;
        T2: Text;
        T3: Text;
    begin
        Resp.Content().WriteFrom('body');
        Resp.Content().ReadAs(T1);
        Resp.Content().ReadAs(T2);
        Content := Resp.Content();
        Content.ReadAs(T3);
        Observer.Observe('chained1', T1);
        Observer.Observe('chained2', T2);
        Observer.Observe('assigned', T3);
        Observer.Expect('chained1', 'body');
        Observer.Expect('chained2', 'body');
        Observer.Expect('assigned', 'body');
        Observer.Verify();
    end;

    [Test]
    procedure RequestContent_ClearOnFreshRequest_ThenContentType()
    // Issue 671 item 32 (microsoft/AL#7606, #7588): Request.Content.GetHeaders(H); Request.Content.Clear(); GetHeaders again; replace Content-Type.
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        H: HttpHeaders;
        Txt: Text;
    begin
        ClearLastError();
        if TryRequestContentHeaders(Req, H) then
            Observer.Observe('getheaders1', 'ok')
        else
            Observer.ObserveError('getheaders1');
        if TryRequestContentClear(Req) then
            Observer.Observe('clear', 'ok')
        else
            Observer.ObserveError('clear');
        if TryRequestContentHeaders(Req, H) then
            Observer.Observe('getheaders2', 'ok')
        else
            Observer.ObserveError('getheaders2');
        Observer.Observe('type_before', HeaderText(H, 'Content-Type'));
        Observer.Observe('remove', Format(H.Remove('Content-Type')));
        Observer.Observe('add', Format(H.Add('Content-Type', 'application/json')));
        Observer.Observe('type_after', HeaderText(H, 'Content-Type'));
        Observer.Observe('read_ok', Format(Req.Content.ReadAs(Txt)));
        Observer.Observe('read', Txt);
        Req.Content.GetHeaders(H);
        Observer.Observe('type_fresh_handle', HeaderText(H, 'Content-Type'));
        Req.Content.WriteFrom('{"a":1}');
        Req.Content.GetHeaders(H);
        Observer.Observe('type_after_write', HeaderText(H, 'Content-Type'));
        Observer.Expect('getheaders1|text', 'Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.');
        Observer.Expect('getheaders1|code', 'NotInitialized');
        Observer.Expect('clear', 'ok');
        Observer.Expect('getheaders2', 'ok');
        Observer.Expect('type_before', 'text/plain; charset=utf-8');
        Observer.Expect('remove', 'Yes');
        Observer.Expect('add', 'Yes');
        Observer.Expect('type_after', 'application/json');
        Observer.Expect('read_ok', 'Yes');
        Observer.Expect('read', '');
        Observer.Expect('type_fresh_handle', 'application/json');
        Observer.Expect('type_after_write', 'text/plain; charset=utf-8');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromBlobStream_MultipartBody()
    // Issue 671 item 33 (microsoft/AL#2339): a multi-line multipart body (CRLF line ends) in a Blob field, WriteFrom(InStream), then ReadAs.
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT DB Http Blob" temporary;
        Content: HttpContent;
        InS: InStream;
        InS2: InStream;
        Body: Text;
        Txt: Text;
    begin
        Body := '--b1' + Crlf() + 'Content-Disposition: form-data; name="a"' + Crlf() + Crlf() + 'value one' + Crlf() + 'value two' + Crlf() + '--b1--' + Crlf();
        FillBlob(Rec, Body, InS);
        Content.WriteFrom(InS);
        Observer.Observe('read_ok', Format(Content.ReadAs(Txt)));
        Observer.Observe('text', Txt);
        Observer.Observe('same_as_body', Format(Txt = Body));
        Observer.Observe('len', Format(StrLen(Txt)));
        FillBlob(Rec, Body, InS);
        Content.WriteFrom(InS);
        Content.ReadAs(InS2);
        Observer.Observe('lines', ReadAll(InS2));
        Observer.Expect('read_ok', 'Yes');
        Observer.Expect('text', '--b1\r\nContent-Disposition: form-data; name="a"\r\n\r\nvalue one\r\nvalue two\r\n--b1--\r\n');
        Observer.Expect('same_as_body', 'Yes');
        Observer.Expect('len', '80');
        Observer.Expect('lines', '6:<--b1><Content-Disposition: form-data; name="a"><><value one><value two><--b1-->');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromBlobStream_LinesFromWriteText()
    // Issue 671 item 33: lines written into the Blob with OutStream.WriteText() between them.
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT DB Http Blob" temporary;
        Content: HttpContent;
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
    begin
        Rec.Init();
        Rec.Id := 1;
        Rec.Data.CreateOutStream(OutS);
        OutS.WriteText('line1');
        OutS.WriteText();
        OutS.WriteText('line2');
        OutS.WriteText();
        Rec.Insert();
        Rec.Data.CreateInStream(InS);
        Content.WriteFrom(InS);
        Content.ReadAs(Txt);
        Observer.Observe('text', Txt);
        Observer.Observe('len', Format(StrLen(Txt)));
        Observer.Expect('text', 'line1\r\nline2\r\n');
        Observer.Expect('len', '14');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromStream_ReadAsTwice()
    // Issue 671 item 34 (microsoft/AL#4348): content written from an InStream, then ReadAs(Text) twice and ReadAs(InStream) after.
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT DB Http Blob" temporary;
        Content: HttpContent;
        InS: InStream;
        InS2: InStream;
        T1: Text;
        T2: Text;
    begin
        FillBlob(Rec, 'picture bytes', InS);
        Content.WriteFrom(InS);
        Observer.Observe('ok1', Format(Content.ReadAs(T1)));
        Observer.Observe('t1', T1);
        Observer.Observe('ok2', Format(Content.ReadAs(T2)));
        Observer.Observe('t2', T2);
        Observer.Observe('ok_stream', Format(Content.ReadAs(InS2)));
        Observer.Observe('stream_after', ReadAll(InS2));
        Observer.Observe('source_eos', Format(InS.EOS()));
        Observer.Expect('ok1', 'Yes');
        Observer.Expect('t1', 'picture bytes');
        Observer.Expect('ok2', 'Yes');
        Observer.Expect('t2', 'picture bytes');
        Observer.Expect('ok_stream', 'Yes');
        Observer.Expect('stream_after', '1:<picture bytes>');
        Observer.Expect('source_eos', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromStream_ReadAsStreamTwice()
    // Issue 671 item 34: content written from an InStream, then ReadAs(InStream) twice, each read to the end before the next.
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT DB Http Blob" temporary;
        Content: HttpContent;
        InS: InStream;
        InS1: InStream;
        InS2: InStream;
        Txt: Text;
    begin
        FillBlob(Rec, 'picture bytes', InS);
        Content.WriteFrom(InS);
        Content.ReadAs(InS1);
        Observer.Observe('s1', ReadAll(InS1));
        Content.ReadAs(InS2);
        Observer.Observe('s2', ReadAll(InS2));
        Content.ReadAs(Txt);
        Observer.Observe('text_after', Txt);
        Observer.Expect('s1', '1:<picture bytes>');
        Observer.Expect('s2', '0:');
        Observer.Expect('text_after', '');
        Observer.Verify();
    end;

    // Writer QG (runtime PR 380, lane-old-fails): ReadAs(Text) after a ReadAs(InStream) stream that was read only partly (2 of 6 characters),
    // or not at all, for the response's own content (Resp.Content() each time), a copy (C := Resp.Content()), a variable written from text
    // and a variable written from an InStream. After the text read: what is left in the first stream, and a fresh ReadAs(InStream).
    [TryFunction]
    local procedure QGTryRespText(var Resp: HttpResponseMessage; var Txt: Text)
    begin
        Resp.Content().ReadAs(Txt);
    end;

    [TryFunction]
    local procedure QGTryContentText(var Content: HttpContent; var Txt: Text)
    begin
        Content.ReadAs(Txt);
    end;

    local procedure QGRead2(var InS: InStream): Text
    var
        T: Text;
    begin
        InS.ReadText(T, 2);
        exit(T);
    end;

    local procedure QGObserveRespText(var Observer: Codeunit "Probe Observer"; Name: Text; var Resp: HttpResponseMessage)
    var
        Txt: Text;
    begin
        if QGTryRespText(Resp, Txt) then
            Observer.Observe(Name, Txt)
        else
            Observer.ObserveError(Name);
    end;

    local procedure QGObserveContentText(var Observer: Codeunit "Probe Observer"; Name: Text; var Content: HttpContent)
    var
        Txt: Text;
    begin
        if QGTryContentText(Content, Txt) then
            Observer.Observe(Name, Txt)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure QG_RespContent_StreamPartlyRead_ThenText()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        InS: InStream;
        InS2: InStream;
    begin
        Resp.Content().WriteFrom('abcdef');
        Resp.Content().ReadAs(InS);
        Observer.Observe('part', QGRead2(InS));
        QGObserveRespText(Observer, 'text', Resp);
        Observer.Observe('rest_of_first', ReadAll(InS));
        QGObserveRespText(Observer, 'text_again', Resp);
        Resp.Content().ReadAs(InS2);
        Observer.Observe('fresh_stream', ReadAll(InS2));
        Observer.Expect('part', 'ab');
        Observer.Expect('text', 'abcdef');
        Observer.Expect('rest_of_first', '1:<cdef>');
        Observer.Expect('text_again', 'abcdef');
        Observer.Expect('fresh_stream', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure QG_RespContent_StreamNotRead_ThenText()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        InS: InStream;
        InS2: InStream;
    begin
        Resp.Content().WriteFrom('abcdef');
        Resp.Content().ReadAs(InS);
        QGObserveRespText(Observer, 'text', Resp);
        Observer.Observe('first_stream', ReadAll(InS));
        QGObserveRespText(Observer, 'text_again', Resp);
        Resp.Content().ReadAs(InS2);
        Observer.Observe('fresh_stream', ReadAll(InS2));
        Observer.Expect('text', 'abcdef');
        Observer.Expect('first_stream', '1:<abcdef>');
        Observer.Expect('text_again', 'abcdef');
        Observer.Expect('fresh_stream', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure QG_RespContentCopy_StreamPartlyRead_ThenText()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        Content: HttpContent;
        InS: InStream;
        InS2: InStream;
    begin
        Resp.Content().WriteFrom('abcdef');
        Content := Resp.Content();
        Content.ReadAs(InS);
        Observer.Observe('part', QGRead2(InS));
        QGObserveContentText(Observer, 'text', Content);
        Observer.Observe('rest_of_first', ReadAll(InS));
        QGObserveContentText(Observer, 'text_again', Content);
        QGObserveRespText(Observer, 'resp_text', Resp);
        Content.ReadAs(InS2);
        Observer.Observe('fresh_stream', ReadAll(InS2));
        Observer.Expect('part', 'ab');
        Observer.Expect('text', '');
        Observer.Expect('rest_of_first', '1:<cdef>');
        Observer.Expect('text_again', '');
        Observer.Expect('resp_text', 'abcdef');
        Observer.Expect('fresh_stream', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure QG_RespContentCopy_StreamNotRead_ThenText()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        Content: HttpContent;
        InS: InStream;
        InS2: InStream;
    begin
        Resp.Content().WriteFrom('abcdef');
        Content := Resp.Content();
        Content.ReadAs(InS);
        QGObserveContentText(Observer, 'text', Content);
        Observer.Observe('first_stream', ReadAll(InS));
        QGObserveContentText(Observer, 'text_again', Content);
        QGObserveRespText(Observer, 'resp_text', Resp);
        Content.ReadAs(InS2);
        Observer.Observe('fresh_stream', ReadAll(InS2));
        Observer.Expect('text', '');
        Observer.Expect('first_stream', '1:<abcdef>');
        Observer.Expect('text_again', '');
        Observer.Expect('resp_text', 'abcdef');
        Observer.Expect('fresh_stream', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure QG_RespContentCopy_RespStreamPartlyRead_ThenCopyText()
    var
        Observer: Codeunit "Probe Observer";
        Resp: HttpResponseMessage;
        Content: HttpContent;
        InS: InStream;
    begin
        Resp.Content().WriteFrom('abcdef');
        Content := Resp.Content();
        Resp.Content().ReadAs(InS);
        Observer.Observe('part', QGRead2(InS));
        QGObserveContentText(Observer, 'copy_text', Content);
        QGObserveRespText(Observer, 'resp_text', Resp);
        Observer.Observe('rest_of_first', ReadAll(InS));
        Observer.Expect('part', 'ab');
        Observer.Expect('copy_text', 'abcdef');
        Observer.Expect('resp_text', 'abcdef');
        Observer.Expect('rest_of_first', '1:<cdef>');
        Observer.Verify();
    end;

    [Test]
    procedure QG_TextContent_StreamPartlyRead_ThenText()
    var
        Observer: Codeunit "Probe Observer";
        Content: HttpContent;
        InS: InStream;
        InS2: InStream;
    begin
        Content.WriteFrom('abcdef');
        Content.ReadAs(InS);
        Observer.Observe('part', QGRead2(InS));
        QGObserveContentText(Observer, 'text', Content);
        Observer.Observe('rest_of_first', ReadAll(InS));
        QGObserveContentText(Observer, 'text_again', Content);
        Content.ReadAs(InS2);
        Observer.Observe('fresh_stream', ReadAll(InS2));
        Observer.Expect('part', 'ab');
        Observer.Expect('text', 'abcdef');
        Observer.Expect('rest_of_first', '1:<cdef>');
        Observer.Expect('text_again', 'abcdef');
        Observer.Expect('fresh_stream', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure QG_TextContent_StreamNotRead_ThenText()
    var
        Observer: Codeunit "Probe Observer";
        Content: HttpContent;
        InS: InStream;
        InS2: InStream;
    begin
        Content.WriteFrom('abcdef');
        Content.ReadAs(InS);
        QGObserveContentText(Observer, 'text', Content);
        Observer.Observe('first_stream', ReadAll(InS));
        QGObserveContentText(Observer, 'text_again', Content);
        Content.ReadAs(InS2);
        Observer.Observe('fresh_stream', ReadAll(InS2));
        Observer.Expect('text', 'abcdef');
        Observer.Expect('first_stream', '1:<abcdef>');
        Observer.Expect('text_again', 'abcdef');
        Observer.Expect('fresh_stream', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure QG_StreamContent_StreamPartlyRead_ThenText()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT DB Http Blob" temporary;
        Content: HttpContent;
        Source: InStream;
        InS: InStream;
        InS2: InStream;
    begin
        FillBlob(Rec, 'abcdef', Source);
        Content.WriteFrom(Source);
        Content.ReadAs(InS);
        Observer.Observe('part', QGRead2(InS));
        QGObserveContentText(Observer, 'text', Content);
        Observer.Observe('rest_of_first', ReadAll(InS));
        QGObserveContentText(Observer, 'text_again', Content);
        Content.ReadAs(InS2);
        Observer.Observe('fresh_stream', ReadAll(InS2));
        Observer.Expect('part', 'ab');
        Observer.Expect('text', '');
        Observer.Expect('rest_of_first', '1:<cdef>');
        Observer.Expect('text_again', '');
        Observer.Expect('fresh_stream', '0:');
        Observer.Verify();
    end;

    [Test]
    procedure QG_StreamContent_StreamNotRead_ThenText()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT DB Http Blob" temporary;
        Content: HttpContent;
        Source: InStream;
        InS: InStream;
        InS2: InStream;
    begin
        FillBlob(Rec, 'abcdef', Source);
        Content.WriteFrom(Source);
        Content.ReadAs(InS);
        QGObserveContentText(Observer, 'text', Content);
        Observer.Observe('first_stream', ReadAll(InS));
        QGObserveContentText(Observer, 'text_again', Content);
        Content.ReadAs(InS2);
        Observer.Observe('fresh_stream', ReadAll(InS2));
        Observer.Expect('text', '');
        Observer.Expect('first_stream', '1:<abcdef>');
        Observer.Expect('text_again', '');
        Observer.Expect('fresh_stream', '0:');
        Observer.Verify();
    end;
}
