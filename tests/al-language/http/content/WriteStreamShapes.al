// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-writefrom-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: measured on BC 27.5, 28.5 and 29.0 service tiers (local observation, then the PR CI run); every literal asserted below is what they produced.
// HttpContent.WriteFrom(InStream) over a Content-Type the code changed first. Each cell observes one string
// ok|error code|error text|Content-Type before the write|Content-Type after|body read after the write (HttpContent.al ObserveStreamResult).
// The cells: Remove after a ReadAs; Clear after a ReadAs; another Content-Type value (application/xml, text/html with a charset, the JSON with a charset,
// the default again); other headers next to it; application/json on a never-written content; a body handed out as a stream and given back;
// a secret header; the request's own content that has none; an assigned InStream and a stream already given to another content; a stream not
// on a Blob field; a second stream write; the state of the stream after the write; a secret content around a stream write.
// BC versions: 27, 28, 29.

codeunit 70887 "LT HtT Content WriteStream Sh"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryWrite(var Content: HttpContent; var InS: InStream)
    begin
        Content.WriteFrom(InS);
    end;

    [TryFunction]
    local procedure TryAddHeader(var Headers: HttpHeaders; Name: Text; Value: Text)
    begin
        Headers.Add(Name, Value);
    end;

    [TryFunction]
    local procedure TryAddSecretHeader(var Headers: HttpHeaders; Name: Text; Value: SecretText)
    begin
        Headers.Add(Name, Value);
    end;

    [TryFunction]
    local procedure TryGetRequestHeaders(var Request: HttpRequestMessage; var Headers: HttpHeaders)
    begin
        Request.Content.GetHeaders(Headers);
    end;

    [TryFunction]
    local procedure TryWriteRequest(var Request: HttpRequestMessage; var InS: InStream)
    begin
        Request.Content.WriteFrom(InS);
    end;

    local procedure ContentType(var Headers: HttpHeaders): Text
    var
        Values: List of [Text];
    begin
        if Headers.GetValues('Content-Type', Values) then
            exit(Values.Get(1));
        exit('<absent>');
    end;

    local procedure TypeOf(var Content: HttpContent): Text
    var
        Headers: HttpHeaders;
    begin
        Content.GetHeaders(Headers);
        exit(ContentType(Headers));
    end;

    local procedure Stream(var Blob: Codeunit "Temp Blob"; var InS: InStream; Value: Text)
    var
        OutS: OutStream;
    begin
        Blob.CreateOutStream(OutS);
        OutS.WriteText(Value);
        Blob.CreateInStream(InS);
    end;

    local procedure WriteCell(Name: Text; var Content: HttpContent; var InS: InStream; Before: Text)
    var
        Ok: Boolean;
        ErrorCode: Text;
        ErrorText: Text;
        Body: Text;
    begin
        ClearLastError();
        Ok := TryWrite(Content, InS);
        ErrorCode := GetLastErrorCode();
        ErrorText := GetLastErrorText();
        ClearLastError();
        Content.ReadAs(Body);
        Observer.Observe(Name, Format(Ok) + '|' + ErrorCode + '|' + ErrorText + '|' + Before + '|' + TypeOf(Content) + '|' + Body);
    end;

    local procedure WriteRequestCell(Name: Text; var Request: HttpRequestMessage; var InS: InStream; Before: Text)
    var
        Headers: HttpHeaders;
        Ok: Boolean;
        ErrorCode: Text;
        ErrorText: Text;
        Body: Text;
        After: Text;
    begin
        ClearLastError();
        Ok := TryWriteRequest(Request, InS);
        ErrorCode := GetLastErrorCode();
        ErrorText := GetLastErrorText();
        ClearLastError();
        Request.Content.GetHeaders(Headers);
        After := ContentType(Headers);
        Request.Content.ReadAs(Body);
        Observer.Observe(Name, Format(Ok) + '|' + ErrorCode + '|' + ErrorText + '|' + Before + '|' + After + '|' + Body);
    end;

    local procedure Written(var Content: HttpContent; Value: Text; var Headers: HttpHeaders)
    begin
        Content.WriteFrom(Value);
        Content.GetHeaders(Headers);
    end;

    // ---- S1 and cell 10: after a ReadAs ----

    [Test]
    procedure S1_ReadAsThenRemove()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Txt: Text;
        Before: Text;
    begin
        Written(Content, 'x', Headers);
        Content.ReadAs(Txt);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('readText|remove', Content, InS, Before);
        Observer.Finish();
    end;

    [Test]
    procedure S1_ReadAsStreamThenRemove()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        Read: InStream;
        InS: InStream;
        Before: Text;
    begin
        Written(Content, 'x', Headers);
        Content.ReadAs(Read);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('readStream|remove', Content, InS, Before);
        Observer.Finish();
    end;

    [Test]
    procedure Cell10_ReadAsThenClear()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Txt: Text;
        Before: Text;
    begin
        Written(Content, 'x', Headers);
        Content.ReadAs(Txt);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('readText|clear', Content, InS, Before);
        Observer.Finish();
    end;

    // ---- S2, cell 14: other Content-Type values ----

    local procedure ReaddedType(Value: Text): Text
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Before: Text;
        Name: Text;
    begin
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', Value);
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        Name := Value;
        WriteCell(Name, Content, InS, Before);
        exit(Name);
    end;

    [Test]
    procedure S2_ReaddedTypes()
    begin
        ReaddedType('application/xml');
        ReaddedType('text/xml');
        ReaddedType('text/html; charset=utf-8');
        ReaddedType('application/json; charset=utf-8');
        ReaddedType('text/plain; charset=utf-8');
        ReaddedType('text/plain');
        ReaddedType('application/octet-stream');
        Observer.Finish();
    end;

    // ---- S3: other headers next to it ----

    [Test]
    procedure S3_OtherHeadersNextToIt()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Before: Text;
    begin
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Observer.Observe('add|ok', Format(TryAddHeader(Headers, 'X-A', 'v')));
        Observer.Observe('addLanguage|ok', Format(TryAddHeader(Headers, 'Content-Language', 'en')));
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('other', Content, InS, Before);
        Content.GetHeaders(Headers);
        Observer.Observe('other|x-a', Format(Headers.Contains('X-A')));
        Observer.Observe('other|language', Format(Headers.Contains('Content-Language')));
        Observer.Finish();
    end;

    // ---- S4: application/json on a never-written content ----

    [Test]
    procedure S4_JsonOnNeverWrittenContent()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Before: Text;
    begin
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Observer.Observe('add|ok', Format(TryAddHeader(Headers, 'Content-Type', 'application/json')));
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('neverWritten|json', Content, InS, Before);
        Observer.Finish();
    end;

    [Test]
    procedure S4_RemovedOnNeverWrittenContent()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Before: Text;
    begin
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('neverWritten|removed', Content, InS, Before);
        Observer.Finish();
    end;

    // ---- S5: a body handed out as a stream ----

    [Test]
    procedure S5_BodyHandedOutThenRemove()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        Handed: InStream;
        InS: InStream;
        Before: Text;
    begin
        Written(Content, 'x', Headers);
        Content.ReadAs(Handed);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('handedOut|otherStream', Content, InS, Before);
        Observer.Finish();
    end;

    [Test]
    procedure S5_BodyHandedOutAndGivenBack()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Handed: InStream;
        Before: Text;
    begin
        Written(Content, 'x', Headers);
        Content.ReadAs(Handed);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        WriteCell('handedOut|sameStream', Content, Handed, Before);
        Observer.Finish();
    end;

    // ---- S6: a secret header ----

    [Test]
    procedure S6_SecretHeader()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Secret: SecretText;
        Before: Text;
    begin
        Secret := SecretStrSubstNo('token');
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Observer.Observe('add|ok', Format(TryAddSecretHeader(Headers, 'X-Secret', Secret)));
        Observer.ObserveError('add|err');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('secretHeader', Content, InS, Before);
        Content.GetHeaders(Headers);
        Observer.Observe('secretHeader|contains', Format(Headers.ContainsSecret('X-Secret')));
        Observer.Finish();
    end;

    // ---- S7: the request's own content that has none ----

    [Test]
    procedure S7_RequestWithoutContent_WriteStream()
    var
        Request: HttpRequestMessage;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryGetRequestHeaders(Request, Headers);
        Observer.Observe('getHeaders|ok', Format(Ok));
        Observer.ObserveError('getHeaders|err');
        Stream(Blob, InS, 'stream body');
        WriteRequestCell('noContent|direct', Request, InS, '<n/a>');
        Observer.Finish();
    end;

    [Test]
    procedure S7_RequestWithoutContent_RemoveThenWriteStream()
    var
        Request: HttpRequestMessage;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Request.Content.WriteFrom('x');
        Request.Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Stream(Blob, InS, 'stream body');
        WriteRequestCell('writtenFirst', Request, InS, '<absent>');
        Observer.Finish();
    end;

    // ---- S8: an assigned or reused InStream ----

    [Test]
    procedure S8_AssignedInStream()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Assigned: InStream;
        Before: Text;
    begin
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        Assigned := InS;
        WriteCell('assigned', Content, Assigned, Before);
        Observer.Finish();
    end;

    [Test]
    procedure S8_StreamAlreadyGivenToAnotherContent()
    var
        First: HttpContent;
        Second: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Before: Text;
    begin
        Stream(Blob, InS, 'stream body');
        First.WriteFrom(InS);
        Written(Second, 'x', Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Second);
        WriteCell('reused', Second, InS, Before);
        Observer.Observe('first|body', ReadBody(First));
        Observer.Finish();
    end;

    [Test]
    procedure S8_StreamOfARecordThatIsGone()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        InS: InStream;
        Before: Text;
    begin
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        GoneStream(InS);
        WriteCell('gone', Content, InS, Before);
        Observer.Finish();
    end;

    local procedure GoneStream(var InS: InStream)
    var
        Blob: Codeunit "Temp Blob";
    begin
        Stream(Blob, InS, 'stream body');
    end;

    local procedure ReadBody(var Content: HttpContent): Text
    var
        Body: Text;
    begin
        Content.ReadAs(Body);
        exit(Body);
    end;

    // ---- cells 12 and 13 ----

    [Test]
    procedure Cell12_StreamNotOnABlobField()
    var
        Source: HttpContent;
        Content: HttpContent;
        Headers: HttpHeaders;
        InS: InStream;
        Before: Text;
    begin
        Source.WriteFrom('source body');
        Source.ReadAs(InS);
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        WriteCell('fromContent', Content, InS, Before);
        Observer.Finish();
    end;

    [Test]
    procedure Cell13_SecondStreamWrite()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        Blob2: Codeunit "Temp Blob";
        InS: InStream;
        InS2: InStream;
        Before: Text;
    begin
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'first stream');
        WriteCell('first', Content, InS, Before);
        Stream(Blob2, InS2, 'second stream');
        WriteCell('second', Content, InS2, TypeOf(Content));
        Observer.Finish();
    end;

    // ---- S9: the stream after the write ----

    [TryFunction]
    local procedure TryEos(var InS: InStream; var Value: Boolean)
    begin
        Value := InS.EOS();
    end;

    [TryFunction]
    local procedure TryLength(var InS: InStream; var Value: Integer)
    begin
        Value := InS.Length();
    end;

    [TryFunction]
    local procedure TryPosition(var InS: InStream; var Value: Integer)
    begin
        Value := InS.Position();
    end;

    [TryFunction]
    local procedure TryReadText(var InS: InStream; var Value: Text)
    begin
        InS.ReadText(Value);
    end;

    [TryFunction]
    local procedure TryReset(var InS: InStream)
    begin
        InS.ResetPosition();
    end;

    local procedure StreamState(Name: Text; var InS: InStream)
    var
        Eos: Boolean;
        Len: Integer;
        Pos: Integer;
        Txt: Text;
    begin
        ClearLastError();
        Observer.Observe(Name + '|eos|ok', Format(TryEos(InS, Eos)));
        Observer.Observe(Name + '|eos', Format(Eos));
        Observer.ObserveError(Name + '|eos');
        Observer.Observe(Name + '|length|ok', Format(TryLength(InS, Len)));
        Observer.Observe(Name + '|length', Format(Len));
        Observer.ObserveError(Name + '|length');
        Observer.Observe(Name + '|position|ok', Format(TryPosition(InS, Pos)));
        Observer.Observe(Name + '|position', Format(Pos));
        Observer.ObserveError(Name + '|position');
        Observer.Observe(Name + '|read|ok', Format(TryReadText(InS, Txt)));
        Observer.Observe(Name + '|read', Txt);
        Observer.ObserveError(Name + '|read');
        Txt := 'preset';
        Observer.Observe(Name + '|reset|ok', Format(TryReset(InS)));
        Observer.ObserveError(Name + '|reset');
        Observer.Observe(Name + '|readAfterReset|ok', Format(TryReadText(InS, Txt)));
        Observer.Observe(Name + '|readAfterReset', Txt);
        Observer.ObserveError(Name + '|readAfterReset');
    end;

    [Test]
    procedure S9_StreamAfterWrite_Fresh()
    var
        Content: HttpContent;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        Stream(Blob, InS, 'stream body');
        Content.WriteFrom(InS);
        StreamState('fresh', InS);
        Observer.Finish();
    end;

    [Test]
    procedure S9_StreamAfterWrite_PartlyRead()
    var
        Content: HttpContent;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Consumed: Text;
    begin
        Stream(Blob, InS, 'stream body');
        InS.ReadText(Consumed, 3);
        Content.WriteFrom(InS);
        StreamState('partly', InS);
        Observer.Observe('content|body', ReadBody(Content));
        Observer.Finish();
    end;

    [Test]
    procedure S9_StreamAfterWrite_ContentRead()
    var
        Content: HttpContent;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Body: Text;
    begin
        Stream(Blob, InS, 'stream body');
        Content.WriteFrom(InS);
        Content.ReadAs(Body);
        Observer.Observe('content|body', Body);
        StreamState('afterContentRead', InS);
        Observer.Finish();
    end;

    // ---- S10: a secret content around a stream write; other charsets ----

    [Test]
    procedure S10_StreamWriteOverSecretContent()
    var
        Content: HttpContent;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Secret: SecretText;
        Body: SecretText;
        Txt: Text;
    begin
        Secret := SecretStrSubstNo('secret body');
        Content.WriteFrom(Secret);
        Observer.Observe('before|isSecret', Format(Content.IsSecretContent()));
        Stream(Blob, InS, 'stream body');
        Observer.Observe('write|ok', Format(TryWrite(Content, InS)));
        Observer.ObserveError('write|err');
        Observer.Observe('after|isSecret', Format(Content.IsSecretContent()));
        Observer.Observe('after|type', TypeOf(Content));
        Txt := 'preset';
        Observer.Observe('after|readText', Format(Content.ReadAs(Txt)));
        Observer.Observe('after|text', Txt);
        Observer.Observe('after|readSecret', Format(Content.ReadAs(Body)));
        Observer.Observe('after|secretIsEmpty', Format(Body.IsEmpty()));
        Observer.Finish();
    end;

    [Test]
    procedure S10_TextWriteOverStreamContent_ThenSecretWrite()
    var
        Content: HttpContent;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Secret: SecretText;
        Txt: Text;
    begin
        Stream(Blob, InS, 'stream body');
        Content.WriteFrom(InS);
        Secret := SecretStrSubstNo('secret body');
        Content.WriteFrom(Secret);
        Observer.Observe('isSecret', Format(Content.IsSecretContent()));
        Observer.Observe('type', TypeOf(Content));
        Txt := 'preset';
        Observer.Observe('readText', Format(Content.ReadAs(Txt)));
        Observer.Observe('text', Txt);
        Observer.Finish();
    end;

    local procedure CharsetRead(Charset: Text): Text
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Txt: Text;
    begin
        Content.WriteFrom('caf' + Format(CharToUtf(233)) + ' x');
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'text/plain; charset=' + Charset);
        Txt := 'preset';
        exit(Format(Content.ReadAs(Txt)) + '|' + Format(StrLen(Txt)) + '|' + Txt);
    end;

    local procedure CharToUtf(Code: Integer): Text
    var
        Ch: Text[1];
    begin
        Ch[1] := Code;
        exit(Ch);
    end;

    [Test]
    procedure S10_ReadAsText_OtherCharsets()
    begin
        Observer.Observe('us-ascii', CharsetRead('us-ascii'));
        Observer.Observe('windows-1252', CharsetRead('windows-1252'));
        Observer.Observe('utf-32', CharsetRead('utf-32'));
        Observer.Observe('utf-16be', CharsetRead('utf-16be'));
        Observer.Observe('unicode', CharsetRead('unicode'));
        Observer.Observe('bogus', CharsetRead('lt-bogus'));
        Observer.Observe('quoted', CharsetRead('"utf-8"'));
        Observer.Observe('upper', CharsetRead('UTF-8'));
        Observer.Finish();
    end;
}
