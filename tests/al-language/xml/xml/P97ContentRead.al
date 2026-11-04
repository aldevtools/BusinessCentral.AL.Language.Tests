// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: HttpContent ReadAs(Text) and ReadAs(InStream), WriteFrom(Text) and WriteFrom(InStream) overloads: empty, repeated, unicode, long, and read twice
// BC versions: 29 (27 and 28 by CI)

codeunit 74812 "LT P97 Content Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryReadText(var C: HttpContent; var Result: Text)
    var
        T: Text;
        Ok: Boolean;
    begin
        Ok := C.ReadAs(T);
        Result := Format(Ok) + '|' + T;
    end;

    [TryFunction]
    local procedure TryReadStream(var C: HttpContent; var Result: Text)
    var
        InS: InStream;
        T: Text;
        Ok: Boolean;
    begin
        Ok := C.ReadAs(InS);
        Result := Format(Ok) + '|' + Format(InS.EOS());
        if not InS.EOS() then begin
            InS.ReadText(T);
            Result += '|' + T;
        end;
    end;

    local procedure Rd(var Observer: Codeunit "Probe Observer"; Name: Text; var C: HttpContent)
    var
        R: Text;
    begin
        if TryReadText(C, R) then
            Observer.Observe(Name + '_text', R)
        else
            Observer.ObserveError(Name + '_text');
        if TryReadStream(C, R) then
            Observer.Observe(Name + '_stream', R)
        else
            Observer.ObserveError(Name + '_stream');
    end;

    [Test]
    procedure ReadAs_NewAndEmpty()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        D: HttpContent;
    begin
        Rd(Observer, 'new', C);
        D.WriteFrom('');
        Rd(Observer, 'empty_text', D);
        D.WriteFrom('x');
        D.Clear();
        Rd(Observer, 'cleared', D);
        Observer.Expect('new_text', 'Yes|');
        Observer.Expect('new_stream', 'Yes|Yes');
        Observer.Expect('empty_text_text', 'Yes|');
        Observer.Expect('empty_text_stream', 'Yes|Yes');
        Observer.Expect('cleared_text', 'Yes|');
        Observer.Expect('cleared_stream', 'Yes|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFrom_Text_Repeated()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
    begin
        C.WriteFrom('first');
        Rd(Observer, 'first', C);
        C.WriteFrom('second');
        Rd(Observer, 'second', C);
        Rd(Observer, 'again', C);
        Observer.Expect('first_text', 'Yes|first');
        Observer.Expect('first_stream', 'Yes|No|first');
        Observer.Expect('second_text', 'Yes|second');
        Observer.Expect('second_stream', 'Yes|No|second');
        Observer.Expect('again_text', 'Yes|second');
        Observer.Expect('again_stream', 'Yes|Yes');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFrom_Text_Special()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        Lf: Text[1];
        R: Text;
    begin
        Lf[1] := 10;
        C.WriteFrom('caf' + 'é ' + '日本');
        if TryReadText(C, R) then
            Observer.Observe('unicode', R)
        else
            Observer.ObserveError('unicode');
        C.WriteFrom('a' + Lf + 'b');
        if TryReadText(C, R) then
            Observer.Observe('newline', R)
        else
            Observer.ObserveError('newline');
        C.WriteFrom('  padded  ');
        if TryReadText(C, R) then
            Observer.Observe('padded', R)
        else
            Observer.ObserveError('padded');
        Observer.Expect('unicode', 'Yes|café 日本');
        Observer.Expect('newline', 'Yes|a\nb');
        Observer.Expect('padded', 'Yes|  padded  ');
        Observer.Verify();
    end;

    [Test]
    procedure WriteFrom_InStream()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Empty: InStream;
        R: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('from stream');
        TempBlob.CreateInStream(InS);
        C.WriteFrom(InS);
        Rd(Observer, 'stream', C);
        C.WriteFrom('text now');
        Rd(Observer, 'text_after', C);
        if TryWriteStream(C, Empty) then
            Observer.Observe('uninit_stream', 'ok')
        else
            Observer.ObserveError('uninit_stream');
        Rd(Observer, 'after_uninit', C);
        Observer.Expect('stream_text', 'Yes|from stream');
        Observer.Expect('stream_stream', 'Yes|No|from stream');
        Observer.Expect('text_after_text', 'Yes|text now');
        Observer.Expect('text_after_stream', 'Yes|No|text now');
        Observer.Expect('uninit_stream|text', 'Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.');
        Observer.Expect('uninit_stream|code', 'NotInitialized');
        Observer.Expect('after_uninit_text', 'Yes|text now');
        Observer.Expect('after_uninit_stream', 'Yes|Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryWriteStream(var C: HttpContent; var InS: InStream)
    begin
        C.WriteFrom(InS);
    end;

    [Test]
    procedure WriteFrom_Text_And_Headers()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        H: HttpHeaders;
        Vals: array[2] of Text;
    begin
        C.WriteFrom('body');
        C.GetHeaders(H);
        Observer.Observe('keys', Format(H.Keys().Count()));
        Observer.Observe('has_length', Format(H.Contains('Content-Length')));
        Observer.Observe('has_type', Format(H.Contains('Content-Type')));
        if H.GetValues('Content-Type', Vals) then
            Observer.Observe('type', Vals[1]);
        Observer.Expect('keys', '1');
        Observer.Expect('has_length', 'No');
        Observer.Expect('has_type', 'Yes');
        Observer.Expect('type', 'text/plain; charset=utf-8');
        Observer.Verify();
    end;

    [Test]
    procedure ReadAs_Long()
    var
        Observer: Codeunit "Probe Observer";
        C: HttpContent;
        Long: Text;
        T: Text;
        I: Integer;
    begin
        for I := 1 to 1000 do
            Long += 'abcdefghij';
        C.WriteFrom(Long);
        C.ReadAs(T);
        Observer.Observe('len', Format(StrLen(T)));
        Observer.Observe('same', Format(T = Long));
        Observer.Expect('len', '10000');
        Observer.Expect('same', 'Yes');
        Observer.Verify();
    end;
}
