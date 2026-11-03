// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-writetext-method
// Scope: in-scope
// Fixtures used: self-contained codeunit 73564 (uses the Temp Blob codeunit like the corpus tests do), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: OutStream.WriteText(Text, Length): what is written for a Length shorter than, equal to and longer than the text, zero, negative, on an empty text, with a Code argument,
//   with non-ASCII text in UTF-8 and UTF-16, twice in a row, and next to WriteText() and WriteText(Text); the blob length and the lines read back; the error text and code where it raises
// Settles issue 130 reason 32 (OutStream.WriteText with a length)
// BC versions: 29 (27 and 28 by CI)

codeunit 73564 "LT P130 WriteText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryWrite(var OutS: OutStream; Txt: Text; Len: Integer)
    begin
        OutS.WriteText(Txt, Len);
    end;

    [TryFunction]
    local procedure TryWriteCode(var OutS: OutStream; Value: Code[20]; Len: Integer)
    begin
        OutS.WriteText(Value, Len);
    end;

    local procedure ReadBack(var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, Encoding);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '/';
        end;
        exit(Result);
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text; Len: Integer; Encoding: TextEncoding)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, Encoding);
        if TryWrite(OutS, Txt, Len) then
            Observer.Observe(Name, 'ok bytes=' + Format(TempBlob.Length()) + ' read=' + ReadBack(TempBlob, Encoding))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode() + ' bytes=' + Format(TempBlob.Length()));
    end;

    [Test]
    procedure P130_WriteText_WithLength_Utf8()
    var
        Observer: Codeunit "Probe Observer";
        Lf: Text[1];
    begin
        Lf[1] := 10;
        One(Observer, 'abcdef_3', 'abcdef', 3, TextEncoding::UTF8);
        One(Observer, 'abcdef_6', 'abcdef', 6, TextEncoding::UTF8);
        One(Observer, 'abcdef_10', 'abcdef', 10, TextEncoding::UTF8);
        One(Observer, 'abcdef_1', 'abcdef', 1, TextEncoding::UTF8);
        One(Observer, 'abcdef_0', 'abcdef', 0, TextEncoding::UTF8);
        One(Observer, 'abcdef_minus1', 'abcdef', -1, TextEncoding::UTF8);
        One(Observer, 'empty_5', '', 5, TextEncoding::UTF8);
        One(Observer, 'empty_0', '', 0, TextEncoding::UTF8);
        One(Observer, 'lf_inside_4', 'ab' + Lf + 'cd', 4, TextEncoding::UTF8);
        One(Observer, 'spaces_3', '   x', 3, TextEncoding::UTF8);
        One(Observer, 'long_to_2147483647', 'abcdef', 2147483647, TextEncoding::UTF8);
        Observer.Expect('abcdef_3', 'ok bytes=6 read=abcdef/');
        Observer.Expect('abcdef_6', 'ok bytes=6 read=abcdef/');
        Observer.Expect('abcdef_10', 'ok bytes=6 read=abcdef/');
        Observer.Expect('abcdef_1', 'ok bytes=6 read=abcdef/');
        Observer.Expect('abcdef_0', 'ok bytes=6 read=abcdef/');
        Observer.Expect('abcdef_minus1', 'ok bytes=6 read=abcdef/');
        Observer.Expect('empty_5', 'ok bytes=0 read=');
        Observer.Expect('empty_0', 'ok bytes=0 read=');
        Observer.Expect('lf_inside_4', 'ok bytes=5 read=ab/cd/');
        Observer.Expect('spaces_3', 'ok bytes=4 read=   x/');
        Observer.Expect('long_to_2147483647', 'ok bytes=6 read=abcdef/');
        Observer.Verify();
    end;

    [Test]
    procedure P130_WriteText_WithLength_NonAscii()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, 'umlauts_utf8_2', 'äöü€', 2, TextEncoding::UTF8);
        One(Observer, 'umlauts_utf8_4', 'äöü€', 4, TextEncoding::UTF8);
        One(Observer, 'umlauts_utf8_9', 'äöü€', 9, TextEncoding::UTF8);
        One(Observer, 'umlauts_utf16_2', 'äöü€', 2, TextEncoding::UTF16);
        One(Observer, 'umlauts_utf16_4', 'äöü€', 4, TextEncoding::UTF16);
        One(Observer, 'umlauts_utf16_9', 'äöü€', 9, TextEncoding::UTF16);
        One(Observer, 'umlauts_windows_3', 'äöü€', 3, TextEncoding::Windows);
        One(Observer, 'umlauts_msdos_3', 'äöü€', 3, TextEncoding::MSDos);
        One(Observer, 'ascii_utf16_3', 'abcdef', 3, TextEncoding::UTF16);
        Observer.Expect('umlauts_utf8_2', 'ok bytes=9 read=äöü€/');
        Observer.Expect('umlauts_utf8_4', 'ok bytes=9 read=äöü€/');
        Observer.Expect('umlauts_utf8_9', 'ok bytes=9 read=äöü€/');
        Observer.Expect('umlauts_utf16_2', 'ok bytes=8 read=äöü€/');
        Observer.Expect('umlauts_utf16_4', 'ok bytes=8 read=äöü€/');
        Observer.Expect('umlauts_utf16_9', 'ok bytes=8 read=äöü€/');
        Observer.Expect('umlauts_windows_3', 'ok bytes=3 read=äöü/');
        Observer.Expect('umlauts_msdos_3', 'ok bytes=3 read=äöü/');
        Observer.Expect('ascii_utf16_3', 'ok bytes=12 read=abcdef/');
        Observer.Verify();
    end;

    [Test]
    procedure P130_WriteText_Sequences()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('Hello', 3);
        OutS.WriteText('World', 10);
        Observer.Observe('two_calls_bytes', Format(TempBlob.Length()));
        Observer.Observe('two_calls_read', ReadBack(TempBlob, TextEncoding::UTF8));

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('abc');
        Observer.Observe('plain_bytes', Format(TempBlob.Length()));
        OutS.WriteText();
        Observer.Observe('plain_then_empty_bytes', Format(TempBlob.Length()));
        OutS.WriteText('def', 2);
        Observer.Observe('then_len2_bytes', Format(TempBlob.Length()));
        OutS.WriteText('ghi', 0);
        Observer.Observe('then_len0_bytes', Format(TempBlob.Length()));
        OutS.WriteText('jkl');
        Observer.Observe('then_plain_bytes', Format(TempBlob.Length()));
        Observer.Observe('all_read', ReadBack(TempBlob, TextEncoding::UTF8));

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('xyz', 2);
        OutS.WriteText();
        OutS.WriteText('uvw', 1);
        Observer.Observe('len_then_empty_then_len_bytes', Format(TempBlob.Length()));
        Observer.Observe('len_then_empty_then_len_read', ReadBack(TempBlob, TextEncoding::UTF8));
        Observer.Expect('two_calls_bytes', '10');
        Observer.Expect('two_calls_read', 'HelloWorld/');
        Observer.Expect('plain_bytes', '3');
        Observer.Expect('plain_then_empty_bytes', '5');
        Observer.Expect('then_len2_bytes', '8');
        Observer.Expect('then_len0_bytes', '11');
        Observer.Expect('then_plain_bytes', '14');
        Observer.Expect('all_read', 'abc/defghijkl/');
        Observer.Expect('len_then_empty_then_len_bytes', '8');
        Observer.Expect('len_then_empty_then_len_read', 'xyz/uvw/');
        Observer.Verify();
    end;

    [Test]
    procedure P130_WriteText_CodeArgumentWithLength()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        if TryWriteCode(OutS, 'abcdef', 3) then
            Observer.Observe('code_3', 'ok bytes=' + Format(TempBlob.Length()) + ' read=' + ReadBack(TempBlob, TextEncoding::UTF8))
        else
            Observer.Observe('code_3', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        if TryWriteCode(OutS, 'abcdef', 20) then
            Observer.Observe('code_20', 'ok bytes=' + Format(TempBlob.Length()) + ' read=' + ReadBack(TempBlob, TextEncoding::UTF8))
        else
            Observer.Observe('code_20', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('code_3', 'ok bytes=6 read=ABCDEF/');
        Observer.Expect('code_20', 'ok bytes=6 read=ABCDEF/');
        Observer.Verify();
    end;
}
