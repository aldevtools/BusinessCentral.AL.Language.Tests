// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// HttpContent without a request: WriteFrom/ReadAs Text and InStream, headers, Clear.
// Fixtures used: Probe Observer (codeunit 69160)
// BC versions: 29 (27 and 28 by CI)
// Added by writer BV (2026-10-19, Windows check 3 item AY): a HttpHeaders handle taken with GetHeaders BEFORE the first WriteFrom, used after it:
// GetValues with its return value used answers false, fills nothing and leaves the last error 'Exception of type
// ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.' (code InvalidHeader) without raising; as a statement it raises that
// error (the text real BC gave on Windows 27.5 and 29.0). Contains answers false and Keys still counts 1 without an error; a new GetHeaders handle works
// (test OldHeadersHandle_AfterWriteFrom).

codeunit 72019 "LT HtT Content Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure FreshContentReadAsText()
    var
        Content: HttpContent;
        Txt: Text;
        Ok: Boolean;
    begin
        Txt := 'preset';
        Ok := Content.ReadAs(Txt);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('text', Txt);
        Observer.Observe('len', Format(StrLen(Txt)));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('text', '');
        Observer.Expect('len', '0');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromTextRoundTrip()
    var
        Content: HttpContent;
        Txt: Text;
    begin
        Content.WriteFrom('hello');
        Observer.Observe('ok', Format(Content.ReadAs(Txt)));
        Observer.Observe('text', Txt);
        Content.WriteFrom('second');
        Observer.Observe('ok2', Format(Content.ReadAs(Txt)));
        Observer.Observe('text2', Txt);
        Content.WriteFrom('');
        Txt := 'preset';
        Observer.Observe('ok3', Format(Content.ReadAs(Txt)));
        Observer.Observe('text3', Txt);
        Observer.Observe('len3', Format(StrLen(Txt)));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('text', 'hello');
        Observer.Expect('ok2', 'Yes');
        Observer.Expect('text2', 'second');
        Observer.Expect('ok3', 'Yes');
        Observer.Expect('text3', '');
        Observer.Expect('len3', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ReadTwice()
    var
        Content: HttpContent;
        Txt: Text;
    begin
        Content.WriteFrom('twice');
        Content.ReadAs(Txt);
        Observer.Observe('first', Txt);
        Txt := '';
        Observer.Observe('okSecond', Format(Content.ReadAs(Txt)));
        Observer.Observe('second', Txt);
        Observer.Expect('first', 'twice');
        Observer.Expect('okSecond', 'Yes');
        Observer.Expect('second', 'twice');
        Observer.Verify();
    end;

    [Test]
    procedure UnicodeAndSpecial()
    var
        Content: HttpContent;
        Txt: Text;
        Cr: Text[1];
        Lf: Text[1];
    begin
        Cr[1] := 13;
        Lf[1] := 10;
        Content.WriteFrom('Grüße äöü € 日本語');
        Content.ReadAs(Txt);
        Observer.Observe('unicode', Txt);
        Observer.Observe('unicodeLen', Format(StrLen(Txt)));
        Content.WriteFrom('a' + Cr + Lf + 'b' + Lf + 'c');
        Content.ReadAs(Txt);
        Observer.Observe('lines', Txt);
        Observer.Observe('linesLen', Format(StrLen(Txt)));
        Content.WriteFrom('   ');
        Content.ReadAs(Txt);
        Observer.Observe('blanks', Format(StrLen(Txt)));
        Content.WriteFrom('{"a":1}');
        Content.ReadAs(Txt);
        Observer.Observe('json', Txt);
        Observer.Expect('unicode', 'Grüße äöü € 日本語');
        Observer.Expect('unicodeLen', '15');
        Observer.Expect('lines', 'a\r\nb\nc');
        Observer.Expect('linesLen', '6');
        Observer.Expect('blanks', '3');
        Observer.Expect('json', '{"a":1}');
        Observer.Verify();
    end;

    [Test]
    procedure LongText()
    var
        Content: HttpContent;
        Txt: Text;
        Big: Text;
        i: Integer;
    begin
        for i := 1 to 20000 do
            Big += 'x';
        Content.WriteFrom(Big);
        Content.ReadAs(Txt);
        Observer.Observe('len', Format(StrLen(Txt)));
        Observer.Observe('equal', Format(Txt = Big));
        Observer.Expect('len', '20000');
        Observer.Expect('equal', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ClearContent()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Txt: Text;
    begin
        Content.WriteFrom('abc');
        Content.GetHeaders(Headers);
        Headers.Add('X-One', 'v');
        Observer.Observe('hasBefore', Format(Headers.Contains('X-One')));
        Content.Clear();
        Txt := 'preset';
        Observer.Observe('okAfter', Format(Content.ReadAs(Txt)));
        Observer.Observe('textAfter', Txt);
        Content.GetHeaders(Headers);
        Observer.Observe('hasAfter', Format(Headers.Contains('X-One')));
        Observer.Observe('contentType', Format(Headers.Contains('Content-Type')));
        Observer.Expect('hasBefore', 'Yes');
        Observer.Expect('okAfter', 'Yes');
        Observer.Expect('textAfter', '');
        Observer.Expect('hasAfter', 'No');
        Observer.Expect('contentType', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ContentTypeHeaderAfterWrite()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        Content.GetHeaders(Headers);
        Observer.Observe('freshContainsType', Format(Headers.Contains('Content-Type')));
        Observer.Observe('freshKeys', Format(Headers.Keys().Count()));
        Content.WriteFrom('abc');
        Content.GetHeaders(Headers);
        Observer.Observe('afterWriteContainsType', Format(Headers.Contains('Content-Type')));
        Observer.Observe('afterWriteKeys', Format(Headers.Keys().Count()));
        if Headers.GetValues('Content-Type', Vals) then
            Observer.Observe('type', Vals[1]);
        Observer.Expect('freshContainsType', 'Yes');
        Observer.Expect('freshKeys', '1');
        Observer.Expect('afterWriteContainsType', 'Yes');
        Observer.Expect('afterWriteKeys', '1');
        Observer.Expect('type', 'text/plain; charset=utf-8');
        Observer.Verify();
    end;

    [Test]
    procedure SetContentTypeHeader()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        Content.WriteFrom('{}');
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Observer.Observe('add', Format(Headers.Add('Content-Type', 'application/json')));
        Headers.GetValues('Content-Type', Vals);
        Observer.Observe('type', Vals[1]);
        Headers.Remove('Content-Type');
        Observer.Observe('addCharset', Format(Headers.Add('Content-Type', 'text/plain; charset=utf-8')));
        Headers.GetValues('Content-Type', Vals);
        Observer.Observe('type2', Vals[1]);
        Headers.Remove('Content-Type');
        asserterror Headers.Add('Content-Type', 'not a media type');
        Observer.ObserveError('badMediaType');
        Observer.Expect('add', 'Yes');
        Observer.Expect('type', 'application/json');
        Observer.Expect('addCharset', 'Yes');
        Observer.Expect('type2', 'text/plain; charset=utf-8');
        Observer.Expect('badMediaType|text', 'Invalid HTTP header. Please, make sure the format of the header is correct.');
        Observer.Expect('badMediaType|code', 'InvalidHeader:Format');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryOldContains(var H: HttpHeaders; var R: Text)
    begin
        R := Format(H.Contains('Content-Length'));
    end;

    [TryFunction]
    local procedure TryOldGetValues(var H: HttpHeaders; var R: Text)
    var
        Vals: List of [Text];
    begin
        R := Format(H.GetValues('Content-Length', Vals)) + ' n=' + Format(Vals.Count());
    end;

    [TryFunction]
    local procedure TryOldKeys(var H: HttpHeaders; var R: Text)
    begin
        R := Format(H.Keys().Count());
    end;

    [Test]
    procedure OldHeadersHandle_AfterWriteFrom()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        NewHeaders: HttpHeaders;
        R: Text;
        Vals: List of [Text];
    begin
        Content.GetHeaders(Headers);
        Content.WriteFrom('hello');
        R := '-';
        ClearLastError();
        Observer.Observe('contains_ok', Format(TryOldContains(Headers, R)));
        Observer.Observe('contains', R);
        Observer.ObserveError('contains');
        R := '-';
        ClearLastError();
        Observer.Observe('getvalues_ok', Format(TryOldGetValues(Headers, R)));
        Observer.Observe('getvalues', R);
        Observer.ObserveError('getvalues');
        R := '-';
        ClearLastError();
        Observer.Observe('keys_ok', Format(TryOldKeys(Headers, R)));
        Observer.Observe('keys', R);
        Observer.ObserveError('keys');
        R := '-';
        ClearLastError();
        asserterror begin
            TryOldGetValues(Headers, R);
            Error('no error');
        end;
        Observer.ObserveError('value_used_in_asserterror');
        ClearLastError();
        asserterror begin
            Headers.GetValues('Content-Length', Vals);
            Error('no error');
        end;
        Observer.ObserveError('statement');
        Content.GetHeaders(NewHeaders);
        Observer.Observe('new_handle_contains', Format(NewHeaders.Contains('Content-Type')));
        Observer.Expect('contains_ok', 'Yes');
        Observer.Expect('contains', 'No');
        Observer.Expect('contains|text', '');
        Observer.Expect('contains|code', '');
        Observer.Expect('getvalues_ok', 'Yes');
        Observer.Expect('getvalues', 'No n=0');
        Observer.Expect('getvalues|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.');
        Observer.Expect('getvalues|code', 'InvalidHeader');
        Observer.Expect('keys_ok', 'Yes');
        Observer.Expect('keys', '1');
        Observer.Expect('keys|text', '');
        Observer.Expect('keys|code', '');
        Observer.Expect('value_used_in_asserterror|text', 'no error');
        Observer.Expect('value_used_in_asserterror|code', 'Dialog');
        Observer.Expect('statement|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNclInvalidHeaderException'' was thrown.');
        Observer.Expect('statement|code', 'InvalidHeader');
        Observer.Expect('new_handle_contains', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ContentLengthHeader()
    var
        Content: HttpContent;
        Headers: HttpHeaders;
        Vals: array[5] of Text;
    begin
        Content.WriteFrom('12345');
        Content.GetHeaders(Headers);
        Observer.Observe('contains', Format(Headers.Contains('Content-Length')));
        if Headers.GetValues('Content-Length', Vals) then
            Observer.Observe('len', Vals[1]);
        Observer.Expect('contains', 'No');
        Observer.Verify();
    end;
}

codeunit 72020 "LT HtT Content Stream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure WriteFromInStreamReadAsText()
    var
        Content: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('from stream');
        TempBlob.CreateInStream(InS);
        Content.WriteFrom(InS);
        Observer.Observe('ok', Format(Content.ReadAs(Txt)));
        Observer.Observe('text', Txt);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('text', 'from stream');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromTextReadAsInStream()
    var
        Content: HttpContent;
        InS: InStream;
        Txt: Text;
    begin
        Content.WriteFrom('to stream');
        Observer.Observe('ok', Format(Content.ReadAs(InS)));
        InS.ReadText(Txt);
        Observer.Observe('text', Txt);
        Observer.Observe('eos', Format(InS.EOS()));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('text', 'to stream');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FreshContentReadAsInStream()
    var
        Content: HttpContent;
        InS: InStream;
        Txt: Text;
    begin
        Observer.Observe('ok', Format(Content.ReadAs(InS)));
        Observer.Observe('eos', Format(InS.EOS()));
        InS.ReadText(Txt);
        Observer.Observe('len', Format(StrLen(Txt)));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('eos', 'Yes');
        Observer.Expect('len', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EmptyInStream()
    var
        Content: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Txt: Text;
    begin
        TempBlob.CreateInStream(InS);
        Content.WriteFrom(InS);
        Txt := 'preset';
        Observer.Observe('ok', Format(Content.ReadAs(Txt)));
        Observer.Observe('len', Format(StrLen(Txt)));
        Observer.Expect('ok', 'Yes');
        Observer.Expect('len', '0');
        Observer.Verify();
    end;

    [Test]
    procedure MultiLineStream()
    var
        Content: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        InS2: InStream;
        L1: Text;
        L2: Text;
        L3: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('line1');
        OutS.WriteText();
        OutS.WriteText('line2');
        TempBlob.CreateInStream(InS);
        Content.WriteFrom(InS);
        Content.ReadAs(InS2);
        InS2.ReadText(L1);
        InS2.ReadText(L2);
        Observer.Observe('l1', L1);
        Observer.Observe('l2', L2);
        Observer.Observe('eos', Format(InS2.EOS()));
        Observer.Expect('l1', 'line1');
        Observer.Expect('l2', 'line2');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PartiallyReadSourceStream()
    var
        Content: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Part: Text;
        Txt: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('abcdef');
        TempBlob.CreateInStream(InS);
        InS.Read(Part, 2);
        Content.WriteFrom(InS);
        Content.ReadAs(Txt);
        Observer.Observe('part', Part);
        Observer.Observe('rest', Txt);
        Observer.Expect('part', 'ab');
        Observer.Expect('rest', 'cdef');
        Observer.Verify();
    end;

    [Test]
    procedure ReadAsInStreamTwice()
    var
        Content: HttpContent;
        InS1: InStream;
        InS2: InStream;
        T1: Text;
        T2: Text;
    begin
        Content.WriteFrom('again');
        Content.ReadAs(InS1);
        Content.ReadAs(InS2);
        InS1.ReadText(T1);
        InS2.ReadText(T2);
        Observer.Observe('t1', T1);
        Observer.Observe('t2', T2);
        Observer.Expect('t1', 'again');
        Observer.Expect('t2', '');
        Observer.Verify();
    end;

    [Test]
    procedure OverwriteTextWithStream()
    var
        Content: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
    begin
        Content.WriteFrom('first');
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('second');
        TempBlob.CreateInStream(InS);
        Content.WriteFrom(InS);
        Content.ReadAs(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('text', 'second');
        Observer.Verify();
    end;

    // The stream header cases below were measured on BC 28.5; the PR matrix checks the other versions.
    local procedure Initialize()
    begin
        Observer.Discard();
    end;

    [TryFunction]
    local procedure TryWriteStream(var Content: HttpContent; var Stream: InStream)
    begin
        Content.WriteFrom(Stream);
    end;

    local procedure ObserveStreamWrite(Name: Text; var Content: HttpContent)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Headers: HttpHeaders;
        Values: array[2] of Text;
        Body: Text;
        Ok: Boolean;
    begin
        Content.GetHeaders(Headers);
        Observer.Observe(Name + '|before', Format(Headers.Contains('Content-Type')));
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('stream body');
        TempBlob.CreateInStream(InS);
        ClearLastError();
        Ok := TryWriteStream(Content, InS);
        Observer.Observe(Name + '|ok', Format(Ok));
        Observer.ObserveError(Name);
        Content.GetHeaders(Headers);
        Observer.Observe(Name + '|after', Format(Headers.Contains('Content-Type')));
        if Headers.GetValues('Content-Type', Values) then
            Observer.Observe(Name + '|type', Values[1])
        else
            Observer.Observe(Name + '|type', '<absent>');
        Content.ReadAs(Body);
        Observer.Observe(Name + '|body', Body);
    end;

    local procedure ObserveStreamCase(Scenario: Integer)
    var
        Content: HttpContent;
        Copy: HttpContent;
        Headers: HttpHeaders;
        CopyHeaders: HttpHeaders;
        Request: HttpRequestMessage;
        Name: Text;
    begin
        if Scenario >= 2 then
            Content.WriteFrom('before');
        Content.GetHeaders(Headers);
        if Scenario in [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 14, 15] then
            Headers.Remove('Content-Type');
        case Scenario of
            0:
                Name := 'fresh';
            1:
                Name := 'freshRemoved';
            2:
                Name := 'writtenRemoved';
            3:
                begin
                    Name := 'readded';
                    Headers.Add('Content-Type', 'application/json');
                end;
            4:
                begin
                    Name := 'headersCleared';
                    Headers.Clear();
                end;
            5:
                begin
                    Name := 'textRewritten';
                    Content.WriteFrom('after remove');
                end;
            6:
                begin
                    Name := 'contentCleared';
                    Content.Clear();
                end;
            7:
                begin
                    Name := 'copyRemoved';
                    Copy := Content;
                    ObserveStreamWrite(Name, Copy);
                    exit;
                end;
            8:
                begin
                    Name := 'headersClearOnly';
                    Headers.Clear();
                end;
            9:
                begin
                    Name := 'copyAfterSourceReadd';
                    Copy := Content;
                    Headers.Add('Content-Type', 'application/json');
                    ObserveStreamWrite(Name, Copy);
                    Observer.Observe(Name + '|sourceType', Format(Headers.Contains('Content-Type')));
                    exit;
                end;
            10:
                begin
                    Name := 'sourceAfterCopyReadd';
                    Copy := Content;
                    Copy.GetHeaders(CopyHeaders);
                    CopyHeaders.Add('Content-Type', 'application/json');
                    ObserveStreamWrite(Name, Content);
                    Observer.Observe(Name + '|copyType', Format(CopyHeaders.Contains('Content-Type')));
                    exit;
                end;
            11:
                begin
                    Name := 'requestAssigned';
                    Request.Content := Content;
                    Copy := Request.Content;
                    ObserveStreamWrite(Name, Copy);
                    exit;
                end;
            12:
                begin
                    Name := 'rawReadded';
                    Headers.TryAddWithoutValidation('Content-Type', 'application/json');
                end;
            13:
                begin
                    Name := 'freshHeadersClear';
                    Content.Clear();
                    Content.GetHeaders(Headers);
                    Headers.Clear();
                end;
            14, 15:
                begin
                    if Scenario = 14 then
                        Name := 'oldHeadersAfterRewrite'
                    else
                        Name := 'newHeadersAfterRewrite';
                    Content.WriteFrom('after remove');
                    if Scenario = 15 then
                        Content.GetHeaders(Headers);
                    Headers.Clear();
                end;
        end;
        ObserveStreamWrite(Name, Content);
    end;

    local procedure ExpectStreamWrite(Name: Text; HadType: Boolean; TypeValue: Text)
    begin
        Observer.Expect(Name + '|before', Format(HadType));
        Observer.Expect(Name + '|ok', 'Yes');
        Observer.Expect(Name + '|text', '');
        Observer.Expect(Name + '|code', '');
        Observer.Expect(Name + '|after', Format(TypeValue <> '<absent>'));
        Observer.Expect(Name + '|type', TypeValue);
        Observer.Expect(Name + '|body', 'stream body');
    end;

    [TryFunction]
    local procedure TryWriteResponseStream(var Response: HttpResponseMessage; var Stream: InStream)
    begin
        Response.Content.WriteFrom(Stream);
    end;

    local procedure ObserveResponseStreamCase(Scenario: Integer)
    var
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Values: array[2] of Text;
        Name: Text;
        Body: Text;
        Ok: Boolean;
    begin
        if Scenario > 0 then
            Response.Content.WriteFrom('before');
        Response.Content.GetHeaders(Headers);
        case Scenario of
            0:
                Name := 'responseFresh';
            1, 3, 4:
                begin
                    Headers.Remove('Content-Type');
                    case Scenario of
                        1:
                            Name := 'responseRemoved';
                        3:
                            begin
                                Name := 'responseReadded';
                                Headers.Add('Content-Type', 'application/json');
                            end;
                        4:
                            begin
                                Name := 'responseCopyRemoved';
                                Content := Response.Content;
                                ObserveStreamWrite(Name, Content);
                                exit;
                            end;
                    end;
                end;
            2:
                begin
                    Name := 'responseHeadersCleared';
                    Headers.Clear();
                end;
        end;
        Observer.Observe(Name + '|before', Format(Headers.Contains('Content-Type')));
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('stream body');
        TempBlob.CreateInStream(InS);
        ClearLastError();
        Ok := TryWriteResponseStream(Response, InS);
        Observer.Observe(Name + '|ok', Format(Ok));
        Observer.ObserveError(Name);
        Response.Content.GetHeaders(Headers);
        Observer.Observe(Name + '|after', Format(Headers.Contains('Content-Type')));
        if Headers.GetValues('Content-Type', Values) then
            Observer.Observe(Name + '|type', Values[1])
        else
            Observer.Observe(Name + '|type', '<absent>');
        Response.Content.ReadAs(Body);
        Observer.Observe(Name + '|body', Body);
    end;

    [Test]
    procedure HttpContent_WriteStream_FreshChangedType()
    var
        Scenario: Integer;
    begin
        Initialize();
        for Scenario := 0 to 4 do
            ObserveStreamCase(Scenario);
        ExpectStreamWrite('fresh', true, 'text/plain; charset=utf-8');
        ExpectStreamWrite('freshRemoved', false, '<absent>');
        ExpectStreamWrite('writtenRemoved', false, '<absent>');
        ExpectStreamWrite('readded', true, 'application/json');
        ExpectStreamWrite('headersCleared', false, '<absent>');
        Observer.Verify();
    end;

    [Test]
    procedure HttpContent_WriteStream_ResetCopiedType()
    var
        Scenario: Integer;
    begin
        Initialize();
        for Scenario := 5 to 8 do
            ObserveStreamCase(Scenario);
        ExpectStreamWrite('textRewritten', true, 'text/plain; charset=utf-8');
        ExpectStreamWrite('contentCleared', true, 'text/plain; charset=utf-8');
        ExpectStreamWrite('copyRemoved', false, '<absent>');
        ExpectStreamWrite('headersClearOnly', false, '<absent>');
        Observer.Verify();
    end;

    [Test]
    procedure HttpContent_WriteStream_IndependentCopy()
    var
        Scenario: Integer;
    begin
        Initialize();
        for Scenario := 9 to 13 do
            ObserveStreamCase(Scenario);
        ExpectStreamWrite('copyAfterSourceReadd', false, '<absent>');
        Observer.Expect('copyAfterSourceReadd|sourceType', 'Yes');
        ExpectStreamWrite('sourceAfterCopyReadd', false, '<absent>');
        Observer.Expect('sourceAfterCopyReadd|copyType', 'Yes');
        ExpectStreamWrite('requestAssigned', false, '<absent>');
        ExpectStreamWrite('rawReadded', true, 'application/json');
        ExpectStreamWrite('freshHeadersClear', false, '<absent>');
        Observer.Verify();
    end;

    [Test]
    procedure HttpContent_WriteStream_ResponseContent()
    var
        Scenario: Integer;
    begin
        Initialize();
        for Scenario := 0 to 4 do
            ObserveResponseStreamCase(Scenario);
        ExpectStreamWrite('responseFresh', false, '<absent>');
        ExpectStreamWrite('responseRemoved', false, '<absent>');
        ExpectStreamWrite('responseHeadersCleared', false, '<absent>');
        ExpectStreamWrite('responseReadded', true, 'application/json');
        ExpectStreamWrite('responseCopyRemoved', false, '<absent>');
        Observer.Verify();
    end;

    [Test]
    procedure HttpContent_WriteStream_AfterRewriteAndClear()
    var
        Scenario: Integer;
    begin
        Initialize();
        for Scenario := 14 to 15 do
            ObserveStreamCase(Scenario);
        ExpectStreamWrite('oldHeadersAfterRewrite', false, '<absent>');
        ExpectStreamWrite('newHeadersAfterRewrite', false, '<absent>');
        Observer.Verify();
    end;
}
