// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73258
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the bytes OutStream.Write(Text) stores (length and base64) for an ASCII text, a text with accented letters and the euro sign, a text with quotes and backslashes, an empty text,
// a text of 200 characters, a surrogate pair, Write(Code), Write(Text[n]) and WriteText, on a stream created with no encoding and with UTF8, UTF16, Windows and MsDos.
// BC versions: 29 (27 and 28 by CI)

codeunit 73258 "LT P129 Stream Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure BytesOf(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Base64: Codeunit "Base64 Convert";
    begin
        TempBlob.CreateInStream(InS);
        exit(Format(TempBlob.Length()) + ' bytes, base64=' + Base64.ToBase64(InS));
    end;

    local procedure Accented(): Text
    var
        T: Text;
    begin
        // a, a-umlaut, o-umlaut, u-umlaut, sharp s, euro sign, e-acute
        T := 'a';
        T[2] := 228;
        T[3] := 246;
        T[4] := 252;
        T[5] := 223;
        T[6] := 8364;
        T[7] := 233;
        exit(T);
    end;

    local procedure Surrogate(): Text
    var
        T: Text;
    begin
        // U+1F600 as a surrogate pair, between two letters
        T := 'a';
        T[2] := 55357;
        T[3] := 56832;
        T[4] := 'b';
        exit(T);
    end;

    local procedure Special(): Text
    var
        T: Text;
    begin
        T := '\\"Test Runner - Mgt"(CodeUnit 130451).Run line 2 - X by Y version 1.0\';
        T[StrLen(T) + 1] := 8230;
        exit(T);
    end;

    local procedure WriteDefault(Value: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
    begin
        TempBlob.CreateOutStream(Out);
        Out.Write(Value);
        exit(BytesOf(TempBlob));
    end;

    local procedure WriteWith(Enc: TextEncoding; Value: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
    begin
        TempBlob.CreateOutStream(Out, Enc);
        Out.Write(Value);
        exit(BytesOf(TempBlob));
    end;

    [Test]
    procedure P129_WriteText_Ascii_PerEncoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', WriteDefault('abc'));
        Observer.Observe('utf8', WriteWith(TextEncoding::UTF8, 'abc'));
        Observer.Observe('utf16', WriteWith(TextEncoding::UTF16, 'abc'));
        Observer.Observe('windows', WriteWith(TextEncoding::Windows, 'abc'));
        Observer.Observe('msdos', WriteWith(TextEncoding::MSDos, 'abc'));
        Observer.Observe('empty default', WriteDefault(''));
        Observer.Observe('empty utf8', WriteWith(TextEncoding::UTF8, ''));
        Observer.Observe('empty utf16', WriteWith(TextEncoding::UTF16, ''));
        Observer.Observe('empty windows', WriteWith(TextEncoding::Windows, ''));
        Observer.Observe('empty msdos', WriteWith(TextEncoding::MSDos, ''));
        Observer.Expect('default', '4 bytes, base64=YWJjAA==');
        Observer.Expect('utf8', '4 bytes, base64=YWJjAA==');
        Observer.Expect('utf16', '8 bytes, base64=YQBiAGMAAAA=');
        Observer.Expect('windows', '4 bytes, base64=YWJjAA==');
        Observer.Expect('msdos', '4 bytes, base64=YWJjAA==');
        Observer.Expect('empty default', '1 bytes, base64=AA==');
        Observer.Expect('empty utf8', '1 bytes, base64=AA==');
        Observer.Expect('empty utf16', '2 bytes, base64=AAA=');
        Observer.Expect('empty windows', '1 bytes, base64=AA==');
        Observer.Expect('empty msdos', '1 bytes, base64=AA==');
        Observer.Verify();
    end;

    [Test]
    procedure P129_WriteText_Accented_PerEncoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', WriteDefault(Accented()));
        Observer.Observe('utf8', WriteWith(TextEncoding::UTF8, Accented()));
        Observer.Observe('utf16', WriteWith(TextEncoding::UTF16, Accented()));
        Observer.Observe('windows', WriteWith(TextEncoding::Windows, Accented()));
        Observer.Observe('msdos', WriteWith(TextEncoding::MSDos, Accented()));
        Observer.Expect('default', '8 bytes, base64=YYSUgeGxggA=');
        Observer.Expect('utf8', '15 bytes, base64=YcOkw7bDvMOf4oKsw6kA');
        Observer.Expect('utf16', '16 bytes, base64=YQDkAPYA/ADfAKwg6QAAAA==');
        Observer.Expect('windows', '8 bytes, base64=YeT2/N+A6QA=');
        Observer.Expect('msdos', '8 bytes, base64=YYSUgeGxggA=');
        Observer.Verify();
    end;

    [Test]
    procedure P129_WriteText_Surrogate_PerEncoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', WriteDefault(Surrogate()));
        Observer.Observe('utf8', WriteWith(TextEncoding::UTF8, Surrogate()));
        Observer.Observe('utf16', WriteWith(TextEncoding::UTF16, Surrogate()));
        Observer.Observe('windows', WriteWith(TextEncoding::Windows, Surrogate()));
        Observer.Observe('msdos', WriteWith(TextEncoding::MSDos, Surrogate()));
        Observer.Expect('default', '5 bytes, base64=YT8/YgA=');
        Observer.Expect('utf8', '7 bytes, base64=YfCfmIBiAA==');
        Observer.Expect('utf16', '10 bytes, base64=YQA92ADeYgAAAA==');
        Observer.Expect('windows', '5 bytes, base64=YT8/YgA=');
        Observer.Expect('msdos', '5 bytes, base64=YT8/YgA=');
        Observer.Verify();
    end;

    [Test]
    procedure P129_WriteText_QuotesBackslashAndEllipsis_PerEncoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('default', WriteDefault(Special()));
        Observer.Observe('utf8', WriteWith(TextEncoding::UTF8, Special()));
        Observer.Observe('utf16', WriteWith(TextEncoding::UTF16, Special()));
        Observer.Observe('windows', WriteWith(TextEncoding::Windows, Special()));
        Observer.Observe('msdos', WriteWith(TextEncoding::MSDos, Special()));
        Observer.Expect('default', '73 bytes, base64=XFwiVGVzdCBSdW5uZXIgLSBNZ3QiKENvZGVVbml0IDEzMDQ1MSkuUnVuIGxpbmUgMiAtIFggYnkgWSB2ZXJzaW9uIDEuMFy1AA==');
        Observer.Expect('utf8', '75 bytes, base64=XFwiVGVzdCBSdW5uZXIgLSBNZ3QiKENvZGVVbml0IDEzMDQ1MSkuUnVuIGxpbmUgMiAtIFggYnkgWSB2ZXJzaW9uIDEuMFzigKYA');
        Observer.Expect('utf16', '146 bytes, base64=XABcACIAVABlAHMAdAAgAFIAdQBuAG4AZQByACAALQAgAE0AZwB0ACIAKABDAG8AZABlAFUAbgBpAHQAIAAxADMAMAA0ADUAMQApAC4AUgB1AG4AIABsAGkAbgBlACAAMgAgAC0AIABYACAAYgB5ACAAWQAgAHYAZQByAHMAaQBvAG4AIAAxAC4AMABcACYgAAA=');
        Observer.Expect('windows', '73 bytes, base64=XFwiVGVzdCBSdW5uZXIgLSBNZ3QiKENvZGVVbml0IDEzMDQ1MSkuUnVuIGxpbmUgMiAtIFggYnkgWSB2ZXJzaW9uIDEuMFyFAA==');
        Observer.Expect('msdos', '73 bytes, base64=XFwiVGVzdCBSdW5uZXIgLSBNZ3QiKENvZGVVbml0IDEzMDQ1MSkuUnVuIGxpbmUgMiAtIFggYnkgWSB2ZXJzaW9uIDEuMFy1AA==');
        Observer.Verify();
    end;

    [Test]
    procedure P129_WriteText_Long_AndTwoWrites()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
        Long: Text;
        I: Integer;
    begin
        for I := 1 to 20 do
            Long += 'abcdefghi' + Format(I mod 10);
        Observer.Observe('long length', Format(StrLen(Long)));
        Observer.Observe('long default', WriteDefault(Long));
        Observer.Observe('long utf16', WriteWith(TextEncoding::UTF16, Long));
        TempBlob.CreateOutStream(Out);
        Out.Write('ab');
        Out.Write('');
        Out.Write(Accented());
        Observer.Observe('three writes', BytesOf(TempBlob));
        Observer.Expect('long length', '200');
        Observer.Expect('long default', '201 bytes, base64=YWJjZGVmZ2hpMWFiY2RlZmdoaTJhYmNkZWZnaGkzYWJjZGVmZ2hpNGFiY2RlZmdoaTVhYmNkZWZnaGk2YWJjZGVmZ2hpN2FiY2RlZmdoaThhYmNkZWZnaGk5YWJjZGVmZ2hpMGFiY2RlZmdoaTFhYmNkZWZnaGkyYWJjZGVmZ2hpM2FiY2RlZmdoaTRhYmNkZWZnaGk1YWJjZGVmZ2hpNmFiY2RlZmdoaTdhYmNkZWZnaGk4YWJjZGVmZ2hpOWFiY2RlZmdoaTAA');
        Observer.Expect('long utf16', '402 bytes, base64=YQBiAGMAZABlAGYAZwBoAGkAMQBhAGIAYwBkAGUAZgBnAGgAaQAyAGEAYgBjAGQAZQBmAGcAaABpADMAYQBiAGMAZABlAGYAZwBoAGkANABhAGIAYwBkAGUAZgBnAGgAaQA1AGEAYgBjAGQAZQBmAGcAaABpADYAYQBiAGMAZABlAGYAZwBoAGkANwBhAGIAYwBkAGUAZgBnAGgAaQA4AGEAYgBjAGQAZQBmAGcAaABpADkAYQBiAGMAZABlAGYAZwBoAGkAMABhAGIAYwBkAGUAZgBnAGgAaQAxAGEAYgBjAGQAZQBmAGcAaABpADIAYQBiAGMAZABlAGYAZwBoAGkAMwBhAGIAYwBkAGUAZgBnAGgAaQA0AGEAYgBjAGQAZQBmAGcAaABpADUAYQBiAGMAZABlAGYAZwBoAGkANgBhAGIAYwBkAGUAZgBnAGgAaQA3AGEAYgBjAGQAZQBmAGcAaABpADgAYQBiAGMAZABlAGYAZwBoAGkAOQBhAGIAYwBkAGUAZgBnAGgAaQAwAAAA');
        Observer.Expect('three writes', '12 bytes, base64=YWIAAGGElIHhsYIA');
        Observer.Verify();
    end;

    [Test]
    procedure P129_WriteCode_WriteTextN_WriteText_Accented()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
        C: Code[10];
        T10: Text[10];
    begin
        C := 'abc';
        T10 := CopyStr(Accented(), 1, 7);
        TempBlob.CreateOutStream(Out);
        Out.Write(C);
        Observer.Observe('code', BytesOf(TempBlob));
        TempBlob.CreateOutStream(Out);
        Out.Write(T10);
        Observer.Observe('text10 accented', BytesOf(TempBlob));
        TempBlob.CreateOutStream(Out, TextEncoding::UTF8);
        Out.Write(T10);
        Observer.Observe('text10 accented utf8', BytesOf(TempBlob));
        TempBlob.CreateOutStream(Out);
        Out.WriteText(Accented());
        Observer.Observe('writetext accented', BytesOf(TempBlob));
        TempBlob.CreateOutStream(Out, TextEncoding::UTF8);
        Out.WriteText(Accented());
        Observer.Observe('writetext accented utf8', BytesOf(TempBlob));
        TempBlob.CreateOutStream(Out, TextEncoding::UTF16);
        Out.WriteText(Accented());
        Observer.Observe('writetext accented utf16', BytesOf(TempBlob));
        TempBlob.CreateOutStream(Out, TextEncoding::UTF8);
        Out.WriteText('abc');
        Out.WriteText();
        Out.WriteText('def');
        Observer.Observe('writetext ascii twice', BytesOf(TempBlob));
        Observer.Expect('code', '4 bytes, base64=QUJDAA==');
        Observer.Expect('text10 accented', '8 bytes, base64=YYSUgeGxggA=');
        Observer.Expect('text10 accented utf8', '15 bytes, base64=YcOkw7bDvMOf4oKsw6kA');
        Observer.Expect('writetext accented', '15 bytes, base64=YYSUgeGxgsOf4oKsw6kA');
        Observer.Expect('writetext accented utf8', '15 bytes, base64=YcOkw7bDvMOf4oKsw6kA');
        Observer.Expect('writetext accented utf16', '15 bytes, base64=YQDkAPYA/ADfAKwg6QAA');
        Observer.Expect('writetext ascii twice', '15 bytes, base64=YWJjDQpkZWbfAKwg6QAA');
        Observer.Verify();
    end;
}
