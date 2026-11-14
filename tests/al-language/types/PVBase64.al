// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/base64convert/base64convert-codeunit
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// System Application "Base64 Convert": ToBase64(Text) uses UTF-8 ('Hello' gives SGVsbG8=, an empty text gives an empty text, a umlaut text w6TDtsO8, padding 0 to 2 equals signs); with
// a TextEncoding the bytes follow it: UTF8 w6TDtsO8, UTF16 (little endian, no byte order mark) 5AD2APwA, Windows 5Pb8 (Windows-1252), MSDos the UTF-8 form; a code page argument decides
// (1252 and 28591 give 5Pb8, 65001 w6TDtsO8). FromBase64 reverses it (UTF-8 by default; the Windows bytes read as UTF-8 give U+FFFD three times). A text that is no Base-64 ("not base64!",
// a single character, an unpadded "SGVsbG8") raises "The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an
// illegal character among the padding characters." / AL:Format; an inner space is ignored. The InStream form reads all bytes; FromBase64(Text, OutStream) writes the decoded bytes.
// ToBase64Url replaces + and / by - and _ and leaves out the padding. With InsertLineBreaks = true a text that needs more than 76 characters is broken with CR LF after 76 characters (164
// characters instead of 160 for 120 bytes); the InStream form breaks too (see Base64LineBreaks.al, corpus issue 1390).
// Fixtures used: self-contained codeunit 69339
// BC versions: 27.5, 29.0

codeunit 69339 "PV Base64 Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFrom(Value: Text; var Result: Text)
    var
        Base64: Codeunit "Base64 Convert";
    begin
        Result := Base64.FromBase64(Value);
    end;

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

    [Test]
    procedure ToBase64_Text_AsciiUmlautsEmpty()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ascii', Base64.ToBase64('Hello'));
        Observer.Observe('empty', '[' + Base64.ToBase64('') + ']');
        Observer.Observe('umlauts', Base64.ToBase64('äöü'));
        Observer.Observe('euro', Base64.ToBase64('€'));
        Observer.Observe('padding_1', Base64.ToBase64('ab'));
        Observer.Observe('padding_2', Base64.ToBase64('a'));
        Observer.Observe('padding_0', Base64.ToBase64('abc'));
        Observer.Expect('ascii', 'SGVsbG8=');
        Observer.Expect('empty', '[]');
        Observer.Expect('umlauts', 'w6TDtsO8');
        Observer.Expect('euro', '4oKs');
        Observer.Expect('padding_1', 'YWI=');
        Observer.Expect('padding_2', 'YQ==');
        Observer.Expect('padding_0', 'YWJj');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_Text_WithEncodings()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('utf8', Base64.ToBase64('äöü', TextEncoding::UTF8));
        Observer.Observe('utf16', Base64.ToBase64('äöü', TextEncoding::UTF16));
        Observer.Observe('windows', Base64.ToBase64('äöü', TextEncoding::Windows));
        Observer.Observe('msdos', Base64.ToBase64('äöü', TextEncoding::MSDos));
        Observer.Observe('codepage_1252', Base64.ToBase64('äöü', TextEncoding::Windows, 1252));
        Observer.Observe('codepage_28591', Base64.ToBase64('äöü', TextEncoding::Windows, 28591));
        Observer.Observe('codepage_65001', Base64.ToBase64('äöü', TextEncoding::UTF8, 65001));
        Observer.Observe('with_line_breaks_short', Base64.ToBase64('Hello', true));
        Observer.Observe('without_line_breaks_short', Base64.ToBase64('Hello', false));
        Observer.Expect('utf8', 'w6TDtsO8');
        Observer.Expect('utf16', '5AD2APwA');
#if BC28PLUS
        Observer.Expect('windows', '5Pb8');
#else
        Observer.Expect('windows', 'w6TDtsO8');
#endif
#if BC28PLUS
        Observer.Expect('msdos', '5Pb8');
#else
        Observer.Expect('msdos', 'w6TDtsO8');
#endif
        Observer.Expect('codepage_1252', '5Pb8');
        Observer.Expect('codepage_28591', '5Pb8');
        Observer.Expect('codepage_65001', 'w6TDtsO8');
        Observer.Expect('with_line_breaks_short', 'SGVsbG8=');
        Observer.Expect('without_line_breaks_short', 'SGVsbG8=');
        Observer.Verify();
    end;

    [Test]
    procedure ToBase64_LongText_LineBreaks()
    var
        Base64: Codeunit "Base64 Convert";
        Plain: Text;
        Wb: Text;
        Wo: Text;
        i: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        for i := 1 to 120 do
            Plain += 'a';
        Wb := Base64.ToBase64(Plain, true);
        Wo := Base64.ToBase64(Plain, false);
        Observer.Observe('without_length', Format(StrLen(Wo)));
        Observer.Observe('with_length', Format(StrLen(Wb)));
        Observer.Observe('with_contains_cr', Format(StrPos(Wb, '\r') > 0));
        Observer.Observe('with_codes_at_76_to_78', Codes(CopyStr(Wb, 76, 3)));
        Observer.Observe('without_default_equals_without', Format(Base64.ToBase64(Plain) = Wo));
        Observer.Expect('without_length', '160');
        Observer.Expect('with_length', '164');
        Observer.Expect('with_contains_cr', 'No');
        Observer.Expect('with_codes_at_76_to_78', '104 13 10 ');
        Observer.Expect('without_default_equals_without', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure FromBase64_Text_AndEncodings()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ascii', Base64.FromBase64('SGVsbG8='));
        Observer.Observe('empty', '[' + Base64.FromBase64('') + ']');
        Observer.Observe('umlauts_utf8_codes', Codes(Base64.FromBase64('w6TDtsO8')));
        Observer.Observe('umlauts_utf8_explicit', Codes(Base64.FromBase64('w6TDtsO8', TextEncoding::UTF8)));
        Observer.Observe('umlauts_windows', Codes(Base64.FromBase64('5Pb8', TextEncoding::Windows)));
        Observer.Observe('umlauts_windows_as_utf8', Codes(Base64.FromBase64('5Pb8', TextEncoding::UTF8)));
        Observer.Observe('codepage_28591', Codes(Base64.FromBase64('5Pb8', TextEncoding::Windows, 28591)));
        Observer.Observe('utf16', Codes(Base64.FromBase64('5AD2APwA', TextEncoding::UTF16)));
        Observer.Expect('ascii', 'Hello');
        Observer.Expect('empty', '[]');
        Observer.Expect('umlauts_utf8_codes', '228 246 252 ');
        Observer.Expect('umlauts_utf8_explicit', '228 246 252 ');
        Observer.Expect('umlauts_windows', '228 246 252 ');
        Observer.Expect('umlauts_windows_as_utf8', '65533 65533 65533 ');
        Observer.Expect('codepage_28591', '228 246 252 ');
        Observer.Expect('utf16', '228 246 252 ');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure FromBase64_Invalid_Text()
    var
        Result: Text;
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Ok := TryFrom('not base64!', Result);
        Observer.Observe('not_base64', Format(Ok) + ' [' + Result + '] ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryFrom('A', Result);
        Observer.Observe('single_char', Format(Ok) + ' [' + Result + '] ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryFrom('SGVsbG8', Result);
        Observer.Observe('padding_missing', Format(Ok) + ' [' + Result + '] ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryFrom('SGVs bG8=', Result);
        Observer.Observe('inner_space', Format(Ok) + ' [' + Result + '] ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('not_base64', 'No [] The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters.|AL:Format');
        Observer.Expect('single_char', 'No [] The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters.|AL:Format');
        Observer.Expect('padding_missing', 'No [] The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters.|AL:Format');
        Observer.Expect('inner_space', 'Yes [Hello] |');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure Base64_Streams()
    var
        Base64: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Text: Text;
        Observer: Codeunit "Probe Observer";
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('Hello');
        TempBlob.CreateInStream(InS);
        Observer.Observe('instream', Base64.ToBase64(InS));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64('SGVsbG8=', OutS);
        TempBlob.CreateInStream(InS);
        InS.ReadText(Text);
        Observer.Observe('outstream_text', Text);
        Observer.Observe('outstream_length', Format(TempBlob.Length()));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789');
        TempBlob.CreateInStream(InS);
        Observer.Observe('instream_long_line_breaks_true_has_lf', Format(StrPos(Base64.ToBase64(InS, true), '\n') > 0));
        TempBlob.CreateInStream(InS);
        Observer.Observe('instream_long_line_breaks_false_has_lf', Format(StrPos(Base64.ToBase64(InS, false), '\n') > 0));
        Observer.Expect('instream', 'SGVsbG8=');
        Observer.Expect('outstream_text', 'Hello');
        Observer.Expect('outstream_length', '5');
        Observer.Expect('instream_long_line_breaks_true_has_lf', 'No');
        Observer.Expect('instream_long_line_breaks_false_has_lf', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Base64Url_Forms()
    var
        Base64: Codeunit "Base64 Convert";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('url_ascii', Base64.ToBase64Url('Hello'));
        Observer.Observe('url_plus_slash', Base64.ToBase64Url('>>>???'));
        Observer.Observe('standard_plus_slash', Base64.ToBase64('>>>???'));
        Observer.Observe('url_padding', Base64.ToBase64Url('a'));
        Observer.Observe('url_umlauts_windows', Base64.ToBase64Url('äöü', TextEncoding::Windows));
        Observer.Expect('url_ascii', 'SGVsbG8');
        Observer.Expect('url_plus_slash', 'Pj4-Pz8_');
        Observer.Expect('standard_plus_slash', 'Pj4+Pz8/');
        Observer.Expect('url_padding', 'YQ');
#if BC28PLUS
        Observer.Expect('url_umlauts_windows', '5Pb8');
#else
        Observer.Expect('url_umlauts_windows', 'w6TDtsO8');
#endif
        Observer.Verify();
    end;

    // Corpus issue 672 item 15 (AL issues 5666 and 7289): binary data (a 1x1 PNG, the first bytes of a ZIP file) decoded with
    // FromBase64 into a Text and encoded again with ToBase64: the text form (UTF-8 by default, then Windows-1252) against the stream
    // form (FromBase64(Text, OutStream) and ToBase64(InStream)). Each value: the result | result = input | StrLen of the text.
    [Test]
    procedure BT_Base64_BinaryThroughText()
    var
        Base64: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        Png: Text;
        Zip: Text;
        Txt: Text;
        Back: Text;
    begin
        Png := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
        Zip := 'UEsDBBQAAAAIAI1jd1n/AA==';
        Txt := Base64.FromBase64(Png);
        Back := Base64.ToBase64(Txt);
        Observer.Observe('png utf8', Back + '|' + Format(Back = Png) + '|' + Format(StrLen(Txt)));
        Observer.Observe('png utf8 first codes', Codes(CopyStr(Txt, 1, 8)));
        Txt := Base64.FromBase64(Png, TextEncoding::Windows);
        Back := Base64.ToBase64(Txt, TextEncoding::Windows);
        Observer.Observe('png windows', Format(Back = Png) + '|' + Format(StrLen(Txt)));
#if not BC28PLUS
        Observer.Observe('png windows back', Back);
#endif
        Txt := Base64.FromBase64(Zip);
        Back := Base64.ToBase64(Txt);
        Observer.Observe('zip utf8', Back + '|' + Format(Back = Zip) + '|' + Format(StrLen(Txt)));
        Txt := Base64.FromBase64(Zip, TextEncoding::Windows);
        Back := Base64.ToBase64(Txt, TextEncoding::Windows);
        Observer.Observe('zip windows', Back + '|' + Format(Back = Zip) + '|' + Format(StrLen(Txt)));
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64(Png, OutS);
        TempBlob.CreateInStream(InS);
        Back := Base64.ToBase64(InS);
        Observer.Observe('png stream', Format(Back = Png) + '|' + Format(TempBlob.Length()));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64(Zip, OutS);
        TempBlob.CreateInStream(InS);
        Back := Base64.ToBase64(InS);
        Observer.Observe('zip stream', Back + '|' + Format(Back = Zip) + '|' + Format(TempBlob.Length()));
#if BC28PLUS
        Observer.Expect('png utf8', '77+9UE5HDQoaCgAAAA1JSERSAAAAAQAAAAEIAAAAADp+77+9VQAAAAtJREFUeO+/vWNk77+9DwABBQEBJxjvv71mAAAAAElFTkTvv71CYO+/vQ==|No|68');
        Observer.Expect('png utf8 first codes', '65533 80 78 71 13 10 26 10 ');
        Observer.Expect('png windows', 'Yes|68');
        Observer.Expect('zip utf8', 'UEsDBBQAAAAIAO+/vWN3We+/vQA=|No|16');
        Observer.Expect('zip windows', 'UEsDBBQAAAAIAI1jd1n/AA==|Yes|16');
        Observer.Expect('png stream', 'Yes|68');
        Observer.Expect('zip stream', 'UEsDBBQAAAAIAI1jd1n/AA==|Yes|16');
        Observer.Verify();
#else
        // BC 27.5: ToBase64(Text, TextEncoding::Windows) writes the text as UTF-8 (U+2030 from byte 0x89 comes back as E2 80 B0).
        Observer.Expect('png utf8', '77+9UE5HDQoaCgAAAA1JSERSAAAAAQAAAAEIAAAAADp+77+9VQAAAAtJREFUeO+/vWNk77+9DwABBQEBJxjvv71mAAAAAElFTkTvv71CYO+/vQ==|No|68');
        Observer.Expect('png utf8 first codes', '65533 80 78 71 13 10 26 10 ');
        Observer.Expect('png windows', 'No|68');
        Observer.Expect('png windows back', '4oCwUE5HDQoaCgAAAA1JSERSAAAAAQAAAAEIAAAAADp+4oC6VQAAAAtJREFUeMOaY2TDuA8AAQUBAScYw6NmAAAAAElFTkTCrkJg4oCa');
        Observer.Expect('zip utf8', 'UEsDBBQAAAAIAO+/vWN3We+/vQA=|No|16');
        Observer.Expect('zip windows', 'UEsDBBQAAAAIAMKNY3dZw78A|No|16');
        Observer.Expect('png stream', 'Yes|68');
        Observer.Expect('zip stream', 'UEsDBBQAAAAIAI1jd1n/AA==|Yes|16');
        Observer.Verify();
#endif
    end;
}
