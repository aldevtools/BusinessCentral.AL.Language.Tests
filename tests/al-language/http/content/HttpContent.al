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
}
