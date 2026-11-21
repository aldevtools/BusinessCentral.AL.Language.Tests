// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.text.base64-convert
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer", System Application codeunits "Base64 Convert" and "Temp Blob"
// Probe: written against local BC tiers; every literal asserted below is what those tiers produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 27.5, 28.5, 29.0
// Lead: corpus issue 1390 (PVBase64.al searches for '\n' and '\r', which AL reads as two plain characters each, so those checks
// measure nothing), al-runner issues 7996 (ToBase64(InStream, true) line breaks) and 7997 item 2 (FromBase64 with UTF16 and 1252).
//
// What BC did (BC 28.5 and 29.0 gave the same results everywhere; 27.5 differs where a #if BC28PLUS block says so):
// - ToBase64(InStream, true) breaks a line after 76 characters with CR LF (13 10), none after the last line: 57 bytes give 76
//   characters, 100 bytes 138, 114 bytes 154, 120 bytes 164. With false: 76, 136, 152, 160. Removing CR LF from the true
//   form gives the false form. The Text form with true gives the same string as the InStream form.
// - Stream position: 28.5 and 29.0 convert the whole stream whatever was read before, and a second call on the same stream
//   gives the same text. 27.5 converts from the read position (10 bytes read: 122 characters) and a second call gives another text.
// - ToBase64(InStream, Boolean, OutStream) (System Application 28 and later) writes the same characters as the string form.
//   One ReadText of the target returns only the first line (76); an empty source writes 0; a target that held 'AB' keeps it.
// - FromBase64 with UTF16 or UTF8 ignores the code page. With Windows or MSDos the code page counts: 1252, 850, 437, 65001
//   and 1200 decode as those pages. Code page 0 decodes as Windows-1252 on 28.5 and 29.0 and as UTF-8 on 27.5.
// Held (not a test): code pages above 65535 (99999 and 70000) with Windows or MSDos. 27.5 raises a catchable error
// (code DotNetInvoke:ArgumentOutOfRange, 'Valid values are between 0 and 65535, inclusive. (Parameter 'codepage')'); 28.5 and 29.0
// raise 'Unexpected CLR exception thrown.: System.ArgumentOutOfRangeException' that asserterror and TryFunction do not
// catch, so the test itself fails.

codeunit 75240 "B64 LineBreaks InStream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Codes(Value: Text): Text
    var
        i: Integer;
        C: Char;
        V: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            C := Value[i];
            V := C;
            Result += Format(V) + ' ';
        end;
        exit(Result);
    end;

    local procedure Digits(Count: Integer): Text
    var
        Result: Text;
    begin
        while StrLen(Result) < Count do
            Result += '0123456789';
        exit(CopyStr(Result, 1, Count));
    end;

    local procedure FillStream(var TempBlob: Codeunit "Temp Blob"; Count: Integer; var InS: InStream)
    var
        OutS: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Digits(Count));
        TempBlob.CreateInStream(InS);
    end;

    local procedure LastCodes(Value: Text; Count: Integer): Text
    begin
        if StrLen(Value) < Count then
            exit(Codes(Value));
        exit(Codes(CopyStr(Value, StrLen(Value) - Count + 1, Count)));
    end;

    local procedure CrLf(): Text
    var
        Cr: Char;
        Lf: Char;
    begin
        Cr := 13;
        Lf := 10;
        exit(Format(Cr) + Format(Lf));
    end;

    local procedure ObserveInStream(var Observer: Codeunit "Probe Observer"; Count: Integer)
    var
        Base64: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        WithBreaks: Text;
        WithoutBreaks: Text;
    begin
        FillStream(TempBlob, Count, InS);
        WithBreaks := Base64.ToBase64(InS, true);
        FillStream(TempBlob, Count, InS);
        WithoutBreaks := Base64.ToBase64(InS, false);
        Observer.Observe('true_length', Format(StrLen(WithBreaks)));
        Observer.Observe('true_codes_76_to_78', Codes(CopyStr(WithBreaks, 76, 3)));
        Observer.Observe('true_codes_153_to_157', Codes(CopyStr(WithBreaks, 153, 5)));
        Observer.Observe('true_last_two_codes', LastCodes(WithBreaks, 2));
        Observer.Observe('false_length', Format(StrLen(WithoutBreaks)));
        Observer.Observe('false_codes_76_to_78', Codes(CopyStr(WithoutBreaks, 76, 3)));
        Observer.Observe('false_last_two_codes', LastCodes(WithoutBreaks, 2));
        Observer.Observe('true_without_crlf_equals_false', Format(DelChr(WithBreaks, '=', CrLf()) = WithoutBreaks));
    end;

    [Test]
    procedure ToBase64_InStream57Bytes_OneFullLine()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveInStream(Observer, 57);
        Observer.Expect('true_length', '76');
        Observer.Expect('true_codes_76_to_78', '50 ');
        Observer.Expect('true_codes_153_to_157', '');
        Observer.Expect('true_last_two_codes', '85 50 ');
        Observer.Expect('false_length', '76');
        Observer.Expect('false_codes_76_to_78', '50 ');
        Observer.Expect('false_last_two_codes', '85 50 ');
        Observer.Expect('true_without_crlf_equals_false', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_InStream100Bytes_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveInStream(Observer, 100);
        Observer.Expect('true_length', '138');
        Observer.Expect('true_codes_76_to_78', '50 13 10 ');
        Observer.Expect('true_codes_153_to_157', '');
        Observer.Expect('true_last_two_codes', '61 61 ');
        Observer.Expect('false_length', '136');
        Observer.Expect('false_codes_76_to_78', '50 78 122 ');
        Observer.Expect('false_last_two_codes', '61 61 ');
        Observer.Expect('true_without_crlf_equals_false', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_InStream114Bytes_TwoFullLines()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveInStream(Observer, 114);
        Observer.Expect('true_length', '154');
        Observer.Expect('true_codes_76_to_78', '50 13 10 ');
        Observer.Expect('true_codes_153_to_157', '73 122 ');
        Observer.Expect('true_last_two_codes', '73 122 ');
        Observer.Expect('false_length', '152');
        Observer.Expect('false_codes_76_to_78', '50 78 122 ');
        Observer.Expect('false_last_two_codes', '73 122 ');
        Observer.Expect('true_without_crlf_equals_false', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_InStream120Bytes_ThreeLines()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveInStream(Observer, 120);
        Observer.Expect('true_length', '164');
        Observer.Expect('true_codes_76_to_78', '50 13 10 ');
        Observer.Expect('true_codes_153_to_157', '73 122 13 10 78 ');
        Observer.Expect('true_last_two_codes', '103 53 ');
        Observer.Expect('false_length', '160');
        Observer.Expect('false_codes_76_to_78', '50 78 122 ');
        Observer.Expect('false_last_two_codes', '103 53 ');
        Observer.Expect('true_without_crlf_equals_false', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_InStream_EmptyPartReadAndSecondCall()
    var
        Base64: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Skipped: Text;
        R: Text;
    begin
        // an empty stream
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        TempBlob.CreateInStream(InS);
        Observer.Observe('empty_true', '[' + Base64.ToBase64(InS, true) + ']');
        // 100 bytes of which 10 were read before the call
        FillStream(TempBlob, 100, InS);
        InS.ReadText(Skipped, 10);
        R := Base64.ToBase64(InS, true);
        Observer.Observe('after_10_read_true_length', Format(StrLen(R)));
        Observer.Observe('after_10_read_true_codes_76_to_78', Codes(CopyStr(R, 76, 3)));
        Observer.Observe('after_10_read_true_first_8', CopyStr(R, 1, 8));
        Observer.Observe('after_10_read_equals_full_text_form', Format(R = Base64.ToBase64(Digits(100), true)));
        // the same stream converted twice
        FillStream(TempBlob, 100, InS);
        R := Base64.ToBase64(InS, true);
        Observer.Observe('first_call_true_length', Format(StrLen(R)));
        Observer.Observe('second_call_equals_first', Format(Base64.ToBase64(InS, true) = R));
        Observer.Expect('empty_true', '[]');
#if BC28PLUS
        Observer.Expect('after_10_read_true_length', '138');
        Observer.Expect('after_10_read_true_codes_76_to_78', '50 13 10 ');
        Observer.Expect('after_10_read_true_first_8', 'MDEyMzQ1');
        Observer.Expect('after_10_read_equals_full_text_form', 'Yes');
#else
        Observer.Expect('after_10_read_true_length', '122');
        Observer.Expect('after_10_read_true_codes_76_to_78', '50 13 10 ');
        Observer.Expect('after_10_read_true_first_8', 'MDEyMzQ1');
        Observer.Expect('after_10_read_equals_full_text_form', 'No');
#endif
        Observer.Expect('first_call_true_length', '138');
#if BC28PLUS
        Observer.Expect('second_call_equals_first', 'Yes');
#else
        Observer.Expect('second_call_equals_first', 'No');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_Text_LineBreaksControl()
    var
        Base64: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        T57: Text;
        T100: Text;
        T120: Text;
    begin
        T57 := Base64.ToBase64(Digits(57), true);
        T100 := Base64.ToBase64(Digits(100), true);
        T120 := Base64.ToBase64(Digits(120), true);
        Observer.Observe('text57_true_length', Format(StrLen(T57)));
        Observer.Observe('text57_true_last_two_codes', LastCodes(T57, 2));
        Observer.Observe('text100_true_length', Format(StrLen(T100)));
        Observer.Observe('text100_true_codes_76_to_78', Codes(CopyStr(T100, 76, 3)));
        Observer.Observe('text120_true_length', Format(StrLen(T120)));
        Observer.Observe('text120_true_codes_153_to_157', Codes(CopyStr(T120, 153, 5)));
        FillStream(TempBlob, 100, InS);
        Observer.Observe('text100_equals_instream100', Format(T100 = Base64.ToBase64(InS, true)));
        FillStream(TempBlob, 120, InS);
        Observer.Observe('text120_equals_instream120', Format(T120 = Base64.ToBase64(InS, true)));
        Observer.Expect('text57_true_length', '76');
        Observer.Expect('text57_true_last_two_codes', '85 50 ');
        Observer.Expect('text100_true_length', '138');
        Observer.Expect('text100_true_codes_76_to_78', '50 13 10 ');
        Observer.Expect('text120_true_length', '164');
        Observer.Expect('text120_true_codes_153_to_157', '73 122 13 10 78 ');
        Observer.Expect('text100_equals_instream100', 'Yes');
        Observer.Expect('text120_equals_instream120', 'Yes');
        Observer.Verify();
    end;

#if BC28PLUS
    local procedure ByteCodes(var TempBlob: Codeunit "Temp Blob"; FromPos: Integer; Count: Integer): Text
    var
        InS: InStream;
        B: Byte;
        V: Integer;
        Pos: Integer;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            Pos += 1;
            V := B;
            if (Pos >= FromPos) and (Pos < FromPos + Count) then
                Result += Format(V) + ' ';
        end;
        exit(Result);
    end;

    local procedure ObserveOutStream(var Observer: Codeunit "Probe Observer"; Count: Integer)
    var
        Base64: Codeunit "Base64 Convert";
        Source: Codeunit "Temp Blob";
        Target: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Len: Integer;
    begin
        FillStream(Source, Count, InS);
        Target.CreateOutStream(OutS);
        Base64.ToBase64(InS, true, OutS);
        Len := Target.Length();
        Observer.Observe('true_written_length', Format(Len));
        Observer.Observe('true_codes_76_to_78', ByteCodes(Target, 76, 3));
        Observer.Observe('true_codes_153_to_157', ByteCodes(Target, 153, 5));
        Observer.Observe('true_last_two_codes', ByteCodes(Target, Len - 1, 2));
        FillStream(Source, Count, InS);
        Clear(Target);
        Target.CreateOutStream(OutS);
        Base64.ToBase64(InS, false, OutS);
        Len := Target.Length();
        Observer.Observe('false_written_length', Format(Len));
        Observer.Observe('false_codes_76_to_78', ByteCodes(Target, 76, 3));
        Observer.Observe('false_last_two_codes', ByteCodes(Target, Len - 1, 2));
    end;

    [Test]
    procedure ToBase64_OutStream57Bytes_OneFullLine()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveOutStream(Observer, 57);
        Observer.Expect('true_written_length', '76');
        Observer.Expect('true_codes_76_to_78', '50 ');
        Observer.Expect('true_codes_153_to_157', '');
        Observer.Expect('true_last_two_codes', '85 50 ');
        Observer.Expect('false_written_length', '76');
        Observer.Expect('false_codes_76_to_78', '50 ');
        Observer.Expect('false_last_two_codes', '85 50 ');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_OutStream100Bytes_TwoLines()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveOutStream(Observer, 100);
        Observer.Expect('true_written_length', '138');
        Observer.Expect('true_codes_76_to_78', '50 13 10 ');
        Observer.Expect('true_codes_153_to_157', '');
        Observer.Expect('true_last_two_codes', '61 61 ');
        Observer.Expect('false_written_length', '136');
        Observer.Expect('false_codes_76_to_78', '50 78 122 ');
        Observer.Expect('false_last_two_codes', '61 61 ');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_OutStream120Bytes_ThreeLines()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveOutStream(Observer, 120);
        Observer.Expect('true_written_length', '164');
        Observer.Expect('true_codes_76_to_78', '50 13 10 ');
        Observer.Expect('true_codes_153_to_157', '73 122 13 10 78 ');
        Observer.Expect('true_last_two_codes', '103 53 ');
        Observer.Expect('false_written_length', '160');
        Observer.Expect('false_codes_76_to_78', '50 78 122 ');
        Observer.Expect('false_last_two_codes', '103 53 ');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_OutStream_ReadBackEmptyAndAppend()
    var
        Base64: Codeunit "Base64 Convert";
        Source: Codeunit "Temp Blob";
        Target: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        OutS: OutStream;
        ResultInS: InStream;
        ReadBack: Text;
        ReadLength: Integer;
    begin
        // read back with one ReadText, as Microsoft's InStreamToBase64WithLineBreaksToOutStreamTest does
        FillStream(Source, 120, InS);
        Target.CreateOutStream(OutS);
        Target.CreateInStream(ResultInS);
        Base64.ToBase64(InS, true, OutS);
        ReadLength := ResultInS.ReadText(ReadBack);
        Observer.Observe('readtext_return', Format(ReadLength));
        Observer.Observe('readtext_strlen', Format(StrLen(ReadBack)));
        Observer.Observe('readtext_codes_76_to_78', Codes(CopyStr(ReadBack, 76, 3)));
        Observer.Observe('readtext_equals_text_form', Format(ReadBack = Base64.ToBase64(Digits(120), true)));
        ReadLength := ResultInS.ReadText(ReadBack);
        Observer.Observe('second_readtext_return', Format(ReadLength));
        Observer.Observe('second_readtext_first_codes', Codes(CopyStr(ReadBack, 1, 2)));
        // an empty source writes nothing
        Clear(Source);
        Source.CreateOutStream(OutS);
        Source.CreateInStream(InS);
        Clear(Target);
        Target.CreateOutStream(OutS);
        Base64.ToBase64(InS, true, OutS);
        Observer.Observe('empty_written_length', Format(Target.Length()));
        // a target that already holds two bytes
        FillStream(Source, 100, InS);
        Clear(Target);
        Target.CreateOutStream(OutS);
        OutS.WriteText('AB');
        Base64.ToBase64(InS, true, OutS);
        Observer.Observe('after_ab_written_length', Format(Target.Length()));
        Observer.Observe('after_ab_codes_1_to_4', ByteCodes(Target, 1, 4));
        Observer.Observe('after_ab_codes_78_to_80', ByteCodes(Target, 78, 3));
        Observer.Expect('readtext_return', '76');
        Observer.Expect('readtext_strlen', '76');
        Observer.Expect('readtext_codes_76_to_78', '50 ');
        Observer.Expect('readtext_equals_text_form', 'No');
        Observer.Expect('second_readtext_return', '76');
        Observer.Expect('second_readtext_first_codes', '78 122 ');
        Observer.Expect('empty_written_length', '0');
        Observer.Expect('after_ab_written_length', '140');
        Observer.Expect('after_ab_codes_1_to_4', '65 66 77 68 ');
        Observer.Expect('after_ab_codes_78_to_80', '50 13 10 ');
        Observer.Verify();
    end;
#endif
}

codeunit 75241 "B64 FromBase64 Encodings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Utf16AB: Label 'QQBCAA==', Locked = true;
        WindowsUmlauts: Label '5Pb8', Locked = true;
        Utf8Umlauts: Label 'w6TDtsO8', Locked = true;

    local procedure Codes(Value: Text): Text
    var
        i: Integer;
        C: Char;
        V: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            C := Value[i];
            V := C;
            Result += Format(V) + ' ';
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryFrom(Value: Text; Encoding: TextEncoding; CodePage: Integer; var Result: Text)
    var
        Base64: Codeunit "Base64 Convert";
    begin
        Result := Base64.FromBase64(Value, Encoding, CodePage);
    end;

    local procedure From(Value: Text; Encoding: TextEncoding; CodePage: Integer): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryFrom(Value, Encoding, CodePage, Result) then
            exit('ok ' + Codes(Result));
        exit('error ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure FromBase64_UTF16_CodePages()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('utf16_1252', From(Utf16AB, TextEncoding::UTF16, 1252));
        Observer.Observe('utf16_0', From(Utf16AB, TextEncoding::UTF16, 0));
        Observer.Observe('utf16_65001', From(Utf16AB, TextEncoding::UTF16, 65001));
        Observer.Observe('utf16_1200', From(Utf16AB, TextEncoding::UTF16, 1200));
        Observer.Observe('utf16_1201', From(Utf16AB, TextEncoding::UTF16, 1201));
        Observer.Observe('utf16_28591', From(Utf16AB, TextEncoding::UTF16, 28591));
        Observer.Observe('utf16_99999', From(Utf16AB, TextEncoding::UTF16, 99999));
        Observer.Observe('utf16_umlauts_1252', From('5AD2APwA', TextEncoding::UTF16, 1252));
        Observer.Expect('utf16_1252', 'ok 65 66 ');
        Observer.Expect('utf16_0', 'ok 65 66 ');
        Observer.Expect('utf16_65001', 'ok 65 66 ');
        Observer.Expect('utf16_1200', 'ok 65 66 ');
        Observer.Expect('utf16_1201', 'ok 65 66 ');
        Observer.Expect('utf16_28591', 'ok 65 66 ');
        Observer.Expect('utf16_99999', 'ok 65 66 ');
        Observer.Expect('utf16_umlauts_1252', 'ok 228 246 252 ');
        Observer.Verify();
    end;

    [Test]
    procedure FromBase64_UTF8_CodePages()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('utf8_0_utf8bytes', From(Utf8Umlauts, TextEncoding::UTF8, 0));
        Observer.Observe('utf8_1252_utf8bytes', From(Utf8Umlauts, TextEncoding::UTF8, 1252));
        Observer.Observe('utf8_1252_windowsbytes', From(WindowsUmlauts, TextEncoding::UTF8, 1252));
        Observer.Observe('utf8_28591_windowsbytes', From(WindowsUmlauts, TextEncoding::UTF8, 28591));
        Observer.Observe('utf8_1200_utf16bytes', From(Utf16AB, TextEncoding::UTF8, 1200));
        Observer.Observe('utf8_99999', From(Utf8Umlauts, TextEncoding::UTF8, 99999));
        Observer.Expect('utf8_0_utf8bytes', 'ok 228 246 252 ');
        Observer.Expect('utf8_1252_utf8bytes', 'ok 228 246 252 ');
        Observer.Expect('utf8_1252_windowsbytes', 'ok 65533 65533 65533 ');
        Observer.Expect('utf8_28591_windowsbytes', 'ok 65533 65533 65533 ');
        Observer.Expect('utf8_1200_utf16bytes', 'ok 65 0 66 0 ');
        Observer.Expect('utf8_99999', 'ok 228 246 252 ');
        Observer.Verify();
    end;

    [Test]
    procedure FromBase64_Windows_CodePages()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('windows_0_windowsbytes', From(WindowsUmlauts, TextEncoding::Windows, 0));
        Observer.Observe('windows_0_utf8bytes', From(Utf8Umlauts, TextEncoding::Windows, 0));
        Observer.Observe('windows_1252_windowsbytes', From(WindowsUmlauts, TextEncoding::Windows, 1252));
        Observer.Observe('windows_65001_utf8bytes', From(Utf8Umlauts, TextEncoding::Windows, 65001));
        Observer.Observe('windows_1200_utf16bytes', From(Utf16AB, TextEncoding::Windows, 1200));
        Observer.Observe('windows_850_windowsbytes', From(WindowsUmlauts, TextEncoding::Windows, 850));
#if BC28PLUS
        Observer.Expect('windows_0_windowsbytes', 'ok 228 246 252 ');
        Observer.Expect('windows_0_utf8bytes', 'ok 195 164 195 182 195 188 ');
#else
        Observer.Expect('windows_0_windowsbytes', 'ok 65533 65533 65533 ');
        Observer.Expect('windows_0_utf8bytes', 'ok 228 246 252 ');
#endif
        Observer.Expect('windows_1252_windowsbytes', 'ok 228 246 252 ');
        Observer.Expect('windows_65001_utf8bytes', 'ok 228 246 252 ');
        Observer.Expect('windows_1200_utf16bytes', 'ok 65 66 ');
        Observer.Expect('windows_850_windowsbytes', 'ok 245 247 179 ');
        Observer.Verify();
    end;

    [Test]
    procedure FromBase64_MSDos_CodePages()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('msdos_0_windowsbytes', From(WindowsUmlauts, TextEncoding::MSDos, 0));
        Observer.Observe('msdos_0_utf8bytes', From(Utf8Umlauts, TextEncoding::MSDos, 0));
        Observer.Observe('msdos_1252_windowsbytes', From(WindowsUmlauts, TextEncoding::MSDos, 1252));
        Observer.Observe('msdos_850_windowsbytes', From(WindowsUmlauts, TextEncoding::MSDos, 850));
        Observer.Observe('msdos_437_windowsbytes', From(WindowsUmlauts, TextEncoding::MSDos, 437));
        Observer.Observe('msdos_65001_utf8bytes', From(Utf8Umlauts, TextEncoding::MSDos, 65001));
#if BC28PLUS
        Observer.Expect('msdos_0_windowsbytes', 'ok 228 246 252 ');
        Observer.Expect('msdos_0_utf8bytes', 'ok 195 164 195 182 195 188 ');
#else
        Observer.Expect('msdos_0_windowsbytes', 'ok 65533 65533 65533 ');
        Observer.Expect('msdos_0_utf8bytes', 'ok 228 246 252 ');
#endif
        Observer.Expect('msdos_1252_windowsbytes', 'ok 228 246 252 ');
        Observer.Expect('msdos_850_windowsbytes', 'ok 245 247 179 ');
        Observer.Expect('msdos_437_windowsbytes', 'ok 931 247 8319 ');
        Observer.Expect('msdos_65001_utf8bytes', 'ok 228 246 252 ');
        Observer.Verify();
    end;

    [Test]
    procedure FromBase64_EncodingOnly_Defaults()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('utf16_only', Codes(Base64.FromBase64(Utf16AB, TextEncoding::UTF16)));
        Observer.Observe('windows_only', Codes(Base64.FromBase64(WindowsUmlauts, TextEncoding::Windows)));
        Observer.Observe('msdos_only', Codes(Base64.FromBase64(WindowsUmlauts, TextEncoding::MSDos)));
        Observer.Observe('utf8_only_windowsbytes', Codes(Base64.FromBase64(WindowsUmlauts, TextEncoding::UTF8)));
        Observer.Expect('utf16_only', '65 66 ');
        Observer.Expect('windows_only', '228 246 252 ');
        Observer.Expect('msdos_only', '228 246 252 ');
        Observer.Expect('utf8_only_windowsbytes', '65533 65533 65533 ');
        Observer.Verify();
    end;
}
