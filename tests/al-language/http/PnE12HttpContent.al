// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72601, table 72602
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "NP Retail blockers - `HttpContent`" (`ReadAs` on a fresh content, WriteFrom(InStream) then ReadAs(Text), headers after WriteFrom(Text), copy on Request.Content := C)
// Facts: HttpContent ReadAs of a fresh content, round trip of non-ASCII bytes, Content-Type header after WriteFrom, whether the request copies the content
// BC versions: 29 (27 and 28 by CI)

table 72602 "LT PnE Http Rec"
{
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

codeunit 72601 "LT PnE Http Content"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure HexVal(c: Char): Integer
    begin
        exit(StrPos('0123456789ABCDEF', UpperCase(Format(c))) - 1);
    end;

    local procedure PutBytes(var Rec: Record "LT PnE Http Rec"; Hex: Text; var Ins: InStream)
    var
        Out: OutStream;
        B: Byte;
        i: Integer;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Data.CreateOutStream(Out);
        i := 1;
        while i < StrLen(Hex) do begin
            B := HexVal(Hex[i]) * 16 + HexVal(Hex[i + 1]);
            Out.Write(B);
            i += 2;
        end;
        Rec.Insert();
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins);
    end;

    local procedure Dump(Txt: Text): Text
    var
        i: Integer;
        Ord: Integer;
        R: Text;
    begin
        for i := 1 to StrLen(Txt) do begin
            Ord := Txt[i];
            R += Format(Ord) + ' ';
        end;
        exit(Format(StrLen(Txt)) + ':' + R);
    end;

    local procedure HeaderValues(var H: HttpHeaders; Name: Text): Text
    var
        Values: List of [Text];
        V: Text;
        R: Text;
    begin
        if not H.GetValues(Name, Values) then
            exit('absent');
        foreach V in Values do
            R += V + ';';
        exit(R);
    end;

    [Test]
    procedure ReadAs_FreshContent()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        T: Text;
        Ins: InStream;
    begin
        C.ReadAs(T);
        Observer.Observe('readAsFresh', 'no error');
        C.ReadAs(Ins);
        Observer.Observe('readAsStreamFresh', 'no error');
        C.GetHeaders(H);
        Observer.Observe('freshContentType', HeaderValues(H, 'Content-Type'));
        Observer.Observe('freshContainsContentType', Format(H.Contains('Content-Type')));
        Observer.Expect('readAsFresh', 'no error');
        Observer.Expect('readAsStreamFresh', 'no error');
        Observer.Expect('freshContentType', 'text/plain; charset=utf-8;');
        Observer.Expect('freshContainsContentType', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromText_ThenReadAndHeaders()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        T: Text;
    begin
        C.WriteFrom('hello');
        C.ReadAs(T);
        Observer.Observe('roundTrip', T);
        C.GetHeaders(H);
        Observer.Observe('contentType', HeaderValues(H, 'Content-Type'));
        Observer.Observe('contentLength', HeaderValues(H, 'Content-Length'));
        Observer.Observe('containsLowerCase', Format(H.Contains('content-type')));
        H.Remove('Content-Type');
        Observer.Observe('afterRemove', HeaderValues(H, 'Content-Type'));
        H.Add('Content-Type', 'text/plain');
        Observer.Observe('afterAdd', HeaderValues(H, 'Content-Type'));
        Observer.Expect('roundTrip', 'hello');
        Observer.Expect('contentType', 'text/plain; charset=utf-8;');
        Observer.Expect('contentLength', '5;');
        Observer.Expect('containsLowerCase', 'Yes');
        Observer.Expect('afterRemove', 'absent');
        Observer.Expect('afterAdd', 'text/plain;');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromText_NonAscii()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        T: Text;
        Back: Text;
    begin
        T := 'wörld€';
        C.WriteFrom(T);
        C.ReadAs(Back);
        Observer.Observe('nonAsciiRoundTrip', Dump(Back));
        Observer.Expect('nonAsciiRoundTrip', '6:119 246 114 108 100 8364 ');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFromInStream_NonAsciiBytes()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Http Rec";
        C: HttpContent;
        Ins: InStream;
        T: Text;
    begin
        PutBytes(Rec, '77C3B6726C64', Ins);
        C.WriteFrom(Ins);
        C.ReadAs(T);
        Observer.Observe('utf8Bytes', Dump(T));
        PutBytes(Rec, '77F6726C64', Ins);
        Clear(C);
        C.WriteFrom(Ins);
        C.ReadAs(T);
        Observer.Observe('latin1Bytes', 'no error');
        Observer.Observe('latin1Text', Dump(T));
        Rec.DeleteAll();
        Observer.Expect('utf8Bytes', '5:119 246 114 108 100 ');
        Observer.Expect('latin1Bytes', 'no error');
        Observer.Expect('latin1Text', '5:119 65533 114 108 100 ');
        Observer.Verify();
    end;

    [Test]
    procedure RequestContent_IsItACopy()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        C: HttpContent;
        Got: HttpContent;
        T: Text;
    begin
        C.WriteFrom('first');
        Req.Content := C;
        C.WriteFrom('second');
        Req.Content.ReadAs(T);
        Observer.Observe('requestAfterChange', T);
        C.ReadAs(T);
        Observer.Observe('originalAfterChange', T);
        Got := Req.Content;
        Got.WriteFrom('third');
        Req.Content.ReadAs(T);
        Observer.Observe('requestAfterGotChange', T);
        Observer.Expect('requestAfterChange', 'first');
        Observer.Expect('originalAfterChange', 'second');
        Observer.Expect('requestAfterGotChange', 'first');
        Observer.Verify();
    end;

    [Test]
    procedure RequestWithoutContent()
    var
        Observer: Codeunit "Probe Observer";
        Req: HttpRequestMessage;
        T: Text;
    begin
        asserterror Req.Content.ReadAs(T);
        Observer.ObserveError('noContentReadAs');
        Observer.Observe('method', Req.Method());
        Observer.Expect('noContentReadAs|text', 'Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.');
        Observer.Expect('noContentReadAs|code', 'NotInitialized');
        Observer.Expect('method', 'GET');
        Observer.Verify();
    end;
    // Writer PW: docs/probes-needed.md "Values and builtins": HttpContent.ReadAs with its result used, on a copy in a variable of the content of a
    // request that has none (Req.Content.ReadAs(T) with the result used answers false, network/lt-http/HttpRequest.al:220; as a statement it
    // raises NotInitialized, RequestWithoutContent), and ReadAs(InStream) on such a content, with the result used and as a statement.
    [TryFunction]
    local procedure PwTryCopyReadAsText(var Answer: Boolean; var T: Text)
    var
        Req: HttpRequestMessage;
        Content: HttpContent;
    begin
        Content := Req.Content;
        Answer := Content.ReadAs(T);
    end;

    [TryFunction]
    local procedure PwTryReadAsStreamUsed(var Answer: Boolean)
    var
        Req: HttpRequestMessage;
        Ins: InStream;
    begin
        Answer := Req.Content.ReadAs(Ins);
    end;

    [TryFunction]
    local procedure PwTryReadAsStreamStatement()
    var
        Req: HttpRequestMessage;
        Ins: InStream;
    begin
        Req.Content.ReadAs(Ins);
    end;

    [TryFunction]
    local procedure PwTryCopyReadAsStreamUsed(var Answer: Boolean)
    var
        Req: HttpRequestMessage;
        Content: HttpContent;
        Ins: InStream;
    begin
        Content := Req.Content;
        Answer := Content.ReadAs(Ins);
    end;

    [Test]
    procedure PW_RequestWithoutContent_CopyAndStream()
    var
        Observer: Codeunit "Probe Observer";
        Answer: Boolean;
        T: Text;
    begin
        T := 'kept';
        Observer.Observe('copyTextUsed', Format(PwTryCopyReadAsText(Answer, T)) + ' answer=' + Format(Answer) + ' text=' + T);
        Observer.ObserveError('copyTextUsed');
        Answer := true;
        Observer.Observe('streamUsed', Format(PwTryReadAsStreamUsed(Answer)) + ' answer=' + Format(Answer));
        Observer.ObserveError('streamUsed');
        Observer.Observe('streamStatement', Format(PwTryReadAsStreamStatement()));
        Observer.ObserveError('streamStatement');
        Answer := true;
        Observer.Observe('copyStreamUsed', Format(PwTryCopyReadAsStreamUsed(Answer)) + ' answer=' + Format(Answer));
        Observer.ObserveError('copyStreamUsed');
        Observer.Expect('copyTextUsed', 'Yes answer=No text=kept');
        Observer.Expect('copyTextUsed|text', '');
        Observer.Expect('copyTextUsed|code', '');
        Observer.Expect('streamUsed', 'Yes answer=No');
        Observer.Expect('streamUsed|text', '');
        Observer.Expect('streamUsed|code', '');
        Observer.Expect('streamStatement', 'No');
        Observer.Expect('streamStatement|text', 'Microsoft.Dynamics.Nav.Runtime.NavHttpContent variable not initialized.');
        Observer.Expect('streamStatement|code', 'NotInitialized');
        Observer.Expect('copyStreamUsed', 'Yes answer=No');
        Observer.Expect('copyStreamUsed|text', '');
        Observer.Expect('copyStreamUsed|code', '');
        Observer.Verify();
    end;
}
