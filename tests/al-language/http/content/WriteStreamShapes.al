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
        ClearLastError();
        Written(Content, 'x', Headers);
        Content.ReadAs(Txt);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('readText|remove', Content, InS, Before);
        Observer.Expect('readText|remove', 'Yes|||<absent>|<absent>|stream body');
        Observer.Verify();
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
        ClearLastError();
        Written(Content, 'x', Headers);
        Content.ReadAs(Read);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('readStream|remove', Content, InS, Before);
        Observer.Expect('readStream|remove', 'Yes|||<absent>|<absent>|stream body');
        Observer.Verify();
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
        ClearLastError();
        Written(Content, 'x', Headers);
        Content.ReadAs(Txt);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('readText|clear', Content, InS, Before);
        Observer.Expect('readText|clear', 'Yes|||<absent>|<absent>|stream body');
        Observer.Verify();
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
        ClearLastError();
        ReaddedType('application/xml');
        ReaddedType('text/xml');
        ReaddedType('text/html; charset=utf-8');
        ReaddedType('application/json; charset=utf-8');
        ReaddedType('text/plain; charset=utf-8');
        ReaddedType('text/plain');
        ReaddedType('application/octet-stream');
        Observer.Expect('application/xml', 'Yes|||application/xml|application/xml|stream body');
        Observer.Expect('text/xml', 'Yes|||text/xml|text/xml|stream body');
        Observer.Expect('text/html; charset=utf-8', 'Yes|||text/html; charset=utf-8|text/html; charset=utf-8|stream body');
        Observer.Expect('application/json; charset=utf-8', 'Yes|||application/json; charset=utf-8|application/json; charset=utf-8|stream body');
        Observer.Expect('text/plain; charset=utf-8', 'Yes|||text/plain; charset=utf-8|text/plain; charset=utf-8|stream body');
        Observer.Expect('text/plain', 'Yes|||text/plain|text/plain|stream body');
        Observer.Expect('application/octet-stream', 'Yes|||application/octet-stream|application/octet-stream|stream body');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('add|ok', 'Yes');
        Observer.Expect('addLanguage|ok', 'Yes');
        Observer.Expect('other', 'Yes|||<absent>|<absent>|stream body');
        Observer.Expect('other|x-a', 'Yes');
        Observer.Expect('other|language', 'Yes');
        Observer.Verify();
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
        ClearLastError();
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Observer.Observe('add|ok', Format(TryAddHeader(Headers, 'Content-Type', 'application/json')));
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('neverWritten|json', Content, InS, Before);
        Observer.Expect('add|ok', 'Yes');
        Observer.Expect('neverWritten|json', 'Yes|||application/json|application/json|stream body');
        Observer.Verify();
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
        ClearLastError();
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('neverWritten|removed', Content, InS, Before);
        Observer.Expect('neverWritten|removed', 'Yes|||<absent>|<absent>|stream body');
        Observer.Verify();
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
        ClearLastError();
        Written(Content, 'x', Headers);
        Content.ReadAs(Handed);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        WriteCell('handedOut|otherStream', Content, InS, Before);
        Observer.Expect('handedOut|otherStream', 'Yes|||<absent>|<absent>|stream body');
        Observer.Verify();
    end;

    [Test]
    procedure S5_BodyHandedOutAndGivenBack()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Handed: InStream;
        Before: Text;
    begin
        ClearLastError();
        Written(Content, 'x', Headers);
        Content.ReadAs(Handed);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        WriteCell('handedOut|sameStream', Content, Handed, Before);
        Observer.Expect('handedOut|sameStream', 'Yes|||<absent>|<absent>|x');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('add|ok', 'Yes');
        Observer.Expect('add|err|text', '');
        Observer.Expect('add|err|code', '');
        Observer.Expect('secretHeader', 'Yes|||<absent>|<absent>|stream body');
        Observer.Expect('secretHeader|contains', 'Yes');
        Observer.Verify();
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
        ClearLastError();
        Ok := TryGetRequestHeaders(Request, Headers);
        Observer.Observe('getHeaders|ok', Format(Ok));
        Observer.ObserveError('getHeaders|err');
        Stream(Blob, InS, 'stream body');
        WriteRequestCell('noContent|direct', Request, InS, '<n/a>');
        Observer.Expect('getHeaders|ok', 'No');
        Observer.Expect('getHeaders|err|text', 'Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.');
        Observer.Expect('getHeaders|err|code', 'NotInitialized');
        Observer.Expect('noContent|direct', 'Yes|||<n/a>|<absent>|stream body');
        Observer.Verify();
    end;

    [Test]
    procedure S7_RequestWithoutContent_RemoveThenWriteStream()
    var
        Request: HttpRequestMessage;
        Headers: HttpHeaders;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
    begin
        ClearLastError();
        Request.Content.WriteFrom('x');
        Request.Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Stream(Blob, InS, 'stream body');
        WriteRequestCell('writtenFirst', Request, InS, '<absent>');
        Observer.Expect('writtenFirst', 'Yes|||<absent>|<absent>|stream body');
        Observer.Verify();
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
        ClearLastError();
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'stream body');
        Assigned := InS;
        WriteCell('assigned', Content, Assigned, Before);
        Observer.Expect('assigned', 'Yes|||<absent>|<absent>|stream body');
        Observer.Verify();
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
        ClearLastError();
        Stream(Blob, InS, 'stream body');
        First.WriteFrom(InS);
        Written(Second, 'x', Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Second);
        WriteCell('reused', Second, InS, Before);
        Observer.Observe('first|body', ReadBody(First));
        Observer.Expect('reused', 'Yes|||<absent>|<absent>|stream body');
        Observer.Expect('first|body', 'stream body');
        Observer.Verify();
    end;

    [Test]
    procedure S8_StreamOfARecordThatIsGone()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        InS: InStream;
        Before: Text;
    begin
        ClearLastError();
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        GoneStream(InS);
        WriteCell('gone', Content, InS, Before);
        Observer.Expect('gone', 'Yes|||<absent>|<absent>|');
        Observer.Verify();
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
        ClearLastError();
        Source.WriteFrom('source body');
        Source.ReadAs(InS);
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        WriteCell('fromContent', Content, InS, Before);
        Observer.Expect('fromContent', 'Yes|||<absent>|<absent>|source body');
        Observer.Verify();
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
        ClearLastError();
        Written(Content, 'x', Headers);
        Headers.Remove('Content-Type');
        Before := TypeOf(Content);
        Stream(Blob, InS, 'first stream');
        WriteCell('first', Content, InS, Before);
        Stream(Blob2, InS2, 'second stream');
        WriteCell('second', Content, InS2, TypeOf(Content));
        Observer.Expect('first', 'Yes|||<absent>|<absent>|first stream');
        Observer.Expect('second', 'Yes|||<absent>|<absent>|second stream');
        Observer.Verify();
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
        ClearLastError();
        Stream(Blob, InS, 'stream body');
        Content.WriteFrom(InS);
        StreamState('fresh', InS);
        Observer.Expect('fresh|eos|ok', 'Yes');
        Observer.Expect('fresh|eos', 'No');
        Observer.Expect('fresh|eos|text', '');
        Observer.Expect('fresh|eos|code', '');
        Observer.Expect('fresh|length|ok', 'Yes');
        Observer.Expect('fresh|length', '11');
        Observer.Expect('fresh|length|text', '');
        Observer.Expect('fresh|length|code', '');
        Observer.Expect('fresh|position|ok', 'Yes');
        Observer.Expect('fresh|position', '1');
        Observer.Expect('fresh|position|text', '');
        Observer.Expect('fresh|position|code', '');
        Observer.Expect('fresh|read|ok', 'Yes');
        Observer.Expect('fresh|read', 'stream body');
        Observer.Expect('fresh|read|text', '');
        Observer.Expect('fresh|read|code', '');
        Observer.Expect('fresh|reset|ok', 'Yes');
        Observer.Expect('fresh|reset|text', '');
        Observer.Expect('fresh|reset|code', '');
        Observer.Expect('fresh|readAfterReset|ok', 'Yes');
        Observer.Expect('fresh|readAfterReset', 'stream body');
        Observer.Expect('fresh|readAfterReset|text', '');
        Observer.Expect('fresh|readAfterReset|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure S9_StreamAfterWrite_PartlyRead()
    var
        Content: HttpContent;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Consumed: Text;
    begin
        ClearLastError();
        Stream(Blob, InS, 'stream body');
        InS.ReadText(Consumed, 3);
        Content.WriteFrom(InS);
        StreamState('partly', InS);
        Observer.Observe('content|body', ReadBody(Content));
        Observer.Expect('partly|eos|ok', 'Yes');
        Observer.Expect('partly|eos', 'No');
        Observer.Expect('partly|eos|text', '');
        Observer.Expect('partly|eos|code', '');
        Observer.Expect('partly|length|ok', 'Yes');
        Observer.Expect('partly|length', '11');
        Observer.Expect('partly|length|text', '');
        Observer.Expect('partly|length|code', '');
        Observer.Expect('partly|position|ok', 'Yes');
        Observer.Expect('partly|position', '4');
        Observer.Expect('partly|position|text', '');
        Observer.Expect('partly|position|code', '');
        Observer.Expect('partly|read|ok', 'Yes');
        Observer.Expect('partly|read', 'eam body');
        Observer.Expect('partly|read|text', '');
        Observer.Expect('partly|read|code', '');
        Observer.Expect('partly|reset|ok', 'Yes');
        Observer.Expect('partly|reset|text', '');
        Observer.Expect('partly|reset|code', '');
        Observer.Expect('partly|readAfterReset|ok', 'Yes');
        Observer.Expect('partly|readAfterReset', 'stream body');
        Observer.Expect('partly|readAfterReset|text', '');
        Observer.Expect('partly|readAfterReset|code', '');
        Observer.Expect('content|body', 'eam body');
        Observer.Verify();
    end;

    [Test]
    procedure S9_StreamAfterWrite_ContentRead()
    var
        Content: HttpContent;
        Blob: Codeunit "Temp Blob";
        InS: InStream;
        Body: Text;
    begin
        ClearLastError();
        Stream(Blob, InS, 'stream body');
        Content.WriteFrom(InS);
        Content.ReadAs(Body);
        Observer.Observe('content|body', Body);
        StreamState('afterContentRead', InS);
        Observer.Expect('content|body', 'stream body');
        Observer.Expect('afterContentRead|eos|ok', 'Yes');
        Observer.Expect('afterContentRead|eos', 'No');
        Observer.Expect('afterContentRead|eos|text', '');
        Observer.Expect('afterContentRead|eos|code', '');
        Observer.Expect('afterContentRead|length|ok', 'Yes');
        Observer.Expect('afterContentRead|length', '11');
        Observer.Expect('afterContentRead|length|text', '');
        Observer.Expect('afterContentRead|length|code', '');
        Observer.Expect('afterContentRead|position|ok', 'Yes');
        Observer.Expect('afterContentRead|position', '1');
        Observer.Expect('afterContentRead|position|text', '');
        Observer.Expect('afterContentRead|position|code', '');
        Observer.Expect('afterContentRead|read|ok', 'Yes');
        Observer.Expect('afterContentRead|read', 'stream body');
        Observer.Expect('afterContentRead|read|text', '');
        Observer.Expect('afterContentRead|read|code', '');
        Observer.Expect('afterContentRead|reset|ok', 'Yes');
        Observer.Expect('afterContentRead|reset|text', '');
        Observer.Expect('afterContentRead|reset|code', '');
        Observer.Expect('afterContentRead|readAfterReset|ok', 'Yes');
        Observer.Expect('afterContentRead|readAfterReset', 'stream body');
        Observer.Expect('afterContentRead|readAfterReset|text', '');
        Observer.Expect('afterContentRead|readAfterReset|code', '');
        Observer.Verify();
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
        ClearLastError();
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
        Observer.Expect('before|isSecret', 'Yes');
        Observer.Expect('write|ok', 'Yes');
        Observer.Expect('write|err|text', '');
        Observer.Expect('write|err|code', '');
        Observer.Expect('after|isSecret', 'No');
        Observer.Expect('after|type', '<absent>');
        Observer.Expect('after|readText', 'Yes');
        Observer.Expect('after|text', 'stream body');
        Observer.Expect('after|readSecret', 'Yes');
        Observer.Expect('after|secretIsEmpty', 'No');
        Observer.Verify();
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
        ClearLastError();
        Stream(Blob, InS, 'stream body');
        Content.WriteFrom(InS);
        Secret := SecretStrSubstNo('secret body');
        Content.WriteFrom(Secret);
        Observer.Observe('isSecret', Format(Content.IsSecretContent()));
        Observer.Observe('type', TypeOf(Content));
        Txt := 'preset';
        Observer.Observe('readText', Format(Content.ReadAs(Txt)));
        Observer.Observe('text', Txt);
        Observer.Expect('isSecret', 'Yes');
        Observer.Expect('type', '<absent>');
        Observer.Expect('readText', 'No');
        Observer.Expect('text', 'preset');
        Observer.Verify();
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
        ClearLastError();
        Observer.Observe('us-ascii', CharsetRead('us-ascii'));
        Observer.Observe('windows-1252', CharsetRead('windows-1252'));
        Observer.Observe('utf-32', CharsetRead('utf-32'));
        Observer.Observe('utf-16be', CharsetRead('utf-16be'));
        Observer.Observe('unicode', CharsetRead('unicode'));
        Observer.Observe('bogus', CharsetRead('lt-bogus'));
        Observer.Observe('quoted', CharsetRead('"utf-8"'));
        Observer.Observe('upper', CharsetRead('UTF-8'));
        Observer.Expect('us-ascii', 'Yes|7|caf?? x');
        Observer.Expect('windows-1252', 'Yes|7|cafÃ© x');
        Observer.Expect('utf-32', 'Yes|2|��');
        Observer.Expect('utf-16be', 'Yes|4|捡曃ꤠ�');
        Observer.Expect('unicode', 'Yes|4|慣썦₩�');
        Observer.Expect('bogus', 'No|6|preset');
        Observer.Expect('quoted', 'Yes|6|café x');
        Observer.Expect('upper', 'Yes|6|café x');
        Observer.Verify();
    end;
}
