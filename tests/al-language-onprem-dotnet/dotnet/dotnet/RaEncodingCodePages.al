// BC Documentation: https://learn.microsoft.com/en-us/dotnet/api/system.text.encoding.getencoding
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99445
// Probe (writer RA, 2026-10-22): System.Text.Encoding.GetEncoding with a Windows code page (1252), DOS code pages (850, 437), Latin-1 (28591)
//   and an unknown code page (99999), by number and by name: WebName, CodePage, EncodingName, GetBytes of a fixed text (as hex) and GetString of
//   fixed bytes (as character codes). The question: does the BC server answer code-page encodings, and with which values.
//   Also the Base Application wrapper codeunit DotNet_Encoding.Encoding(code page) with a DotNet_StreamWriter / DotNet_StreamReader round trip.
// Facts (CI 27.5, 28.5, 29.0, the same): BC answers the code-page encodings 1252, 850, 437 and 28591, by number and by name, with the Windows
//   values (characters that do not map become 0x3F '?'); 99999 and an unknown name raise a DotNetInvoke error (texts asserted).
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.Text.Encoding"; LtRaEncoding) { }
        type("System.Byte[]"; LtRaBytes) { }
        type("System.Convert"; LtRaConvert) { }
        type("System.BitConverter"; LtRaBitConverter) { }
    }
}

codeunit 99445 "LT RA Encoding Code Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryByNumber(CodePage: Integer; var Enc: DotNet LtRaEncoding)
    begin
        Enc := Enc.GetEncoding(CodePage);
    end;

    [TryFunction]
    local procedure TryByName(Name: Text; var Enc: DotNet LtRaEncoding)
    begin
        Enc := Enc.GetEncoding(Name);
    end;

    [TryFunction]
    local procedure TryBytesHex(var Enc: DotNet LtRaEncoding; Value: Text; var Hex: Text)
    var
        BitConv: DotNet LtRaBitConverter;
    begin
        Hex := BitConv.ToString(Enc.GetBytes(Value));
    end;

    [TryFunction]
    local procedure TryStringCodes(var Enc: DotNet LtRaEncoding; Base64: Text; var Codes: Text)
    var
        Conv: DotNet LtRaConvert;
        Bytes: DotNet LtRaBytes;
        Decoded: Text;
        CharCode: Integer;
        i: Integer;
    begin
        Bytes := Conv.FromBase64String(Base64);
        Decoded := Enc.GetString(Bytes);
        Codes := '';
        for i := 1 to StrLen(Decoded) do begin
            CharCode := Decoded[i];
            Codes += Format(CharCode) + ',';
        end;
    end;

    local procedure Describe(Name: Text; var Enc: DotNet LtRaEncoding)
    var
        Hex: Text;
        Codes: Text;
    begin
        Observer.Observe(Name + ' identity', Enc.WebName + '|' + Format(Enc.CodePage) + '|' + Enc.EncodingName);
        // AE, O with stroke, A with ring, euro sign, ae, o with stroke, a with ring
        if TryBytesHex(Enc, 'ÆØÅ€æøå', Hex) then
            Observer.Observe(Name + ' GetBytes', Hex)
        else
            Observer.ObserveError(Name + ' GetBytes');
        // bytes 128, 138, 150, 159 (0x80 0x8A 0x96 0x9F) and 200, 230 (0xC8 0xE6)
        if TryStringCodes(Enc, 'gIqWn8jm', Codes) then
            Observer.Observe(Name + ' GetString', Codes)
        else
            Observer.ObserveError(Name + ' GetString');
    end;

    local procedure ObserveByNumber(CodePage: Integer)
    var
        Enc: DotNet LtRaEncoding;
        Name: Text;
    begin
        Name := 'cp ' + Format(CodePage);
        ClearLastError();
        if TryByNumber(CodePage, Enc) then begin
            Observer.Observe(Name + ' ok', 'Yes');
            Describe(Name, Enc);
        end else
            Observer.ObserveError(Name);
    end;

    local procedure ObserveByName(EncodingName: Text)
    var
        Enc: DotNet LtRaEncoding;
        Name: Text;
    begin
        Name := 'name ' + EncodingName;
        ClearLastError();
        if TryByName(EncodingName, Enc) then begin
            Observer.Observe(Name + ' ok', 'Yes');
            Describe(Name, Enc);
        end else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure RA_GetEncoding_WindowsCodePage1252()
    begin
        ObserveByNumber(1252);
        ObserveByName('windows-1252');
        Observer.Expect('cp 1252 ok', 'Yes');
        Observer.Expect('cp 1252 identity', 'windows-1252|1252|Western European (Windows)');
        Observer.Expect('cp 1252 GetBytes', 'C6-D8-C5-80-E6-F8-E5');
        Observer.Expect('cp 1252 GetString', '8364,352,8211,376,200,230,');
        Observer.Expect('name windows-1252 ok', 'Yes');
        Observer.Expect('name windows-1252 identity', 'windows-1252|1252|Western European (Windows)');
        Observer.Expect('name windows-1252 GetBytes', 'C6-D8-C5-80-E6-F8-E5');
        Observer.Expect('name windows-1252 GetString', '8364,352,8211,376,200,230,');
        Observer.Verify();
    end;

    [Test]
    procedure RA_GetEncoding_DosCodePages850And437()
    begin
        ObserveByNumber(850);
        ObserveByNumber(437);
        ObserveByName('ibm850');
        Observer.Expect('cp 850 ok', 'Yes');
        Observer.Expect('cp 850 identity', 'ibm850|850|Western European (DOS)');
        Observer.Expect('cp 850 GetBytes', '92-9D-8F-3F-91-9B-86');
        Observer.Expect('cp 850 GetString', '199,232,251,402,9562,181,');
        Observer.Expect('cp 437 ok', 'Yes');
        Observer.Expect('cp 437 identity', 'ibm437|437|OEM United States');
        Observer.Expect('cp 437 GetBytes', '92-4F-8F-3F-91-6F-86');
        Observer.Expect('cp 437 GetString', '199,232,251,402,9562,181,');
        Observer.Expect('name ibm850 ok', 'Yes');
        Observer.Expect('name ibm850 identity', 'ibm850|850|Western European (DOS)');
        Observer.Expect('name ibm850 GetBytes', '92-9D-8F-3F-91-9B-86');
        Observer.Expect('name ibm850 GetString', '199,232,251,402,9562,181,');
        Observer.Verify();
    end;

    [Test]
    procedure RA_GetEncoding_Latin1_28591()
    begin
        ObserveByNumber(28591);
        ObserveByName('iso-8859-1');
        Observer.Expect('cp 28591 ok', 'Yes');
        Observer.Expect('cp 28591 identity', 'iso-8859-1|28591|Western European (ISO)');
        Observer.Expect('cp 28591 GetBytes', 'C6-D8-C5-3F-E6-F8-E5');
        Observer.Expect('cp 28591 GetString', '128,138,150,159,200,230,');
        Observer.Expect('name iso-8859-1 ok', 'Yes');
        Observer.Expect('name iso-8859-1 identity', 'iso-8859-1|28591|Western European (ISO)');
        Observer.Expect('name iso-8859-1 GetBytes', 'C6-D8-C5-3F-E6-F8-E5');
        Observer.Expect('name iso-8859-1 GetString', '128,138,150,159,200,230,');
        Observer.Verify();
    end;

    [Test]
    procedure RA_GetEncoding_UnknownCodePage()
    begin
        ObserveByNumber(99999);
        ObserveByName('no-such-encoding');
        Observer.Expect('cp 99999|text', 'A call to System.Text.Encoding.GetEncoding failed with this message: Valid values are between 0 and 65535, inclusive. (Parameter ''codepage'')');
        Observer.Expect('cp 99999|code', 'DotNetInvoke:ArgumentOutOfRange');
        Observer.Expect('name no-such-encoding|text', 'A call to System.Text.Encoding.GetEncoding failed with this message: ''no-such-encoding'' is not a supported encoding name. For information on defining a custom encoding, see the documentation for the Encoding.RegisterProvider method. (Parameter ''name'')');
        Observer.Expect('name no-such-encoding|code', 'DotNetInvoke:Argument');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryWrapperEncoding(CodePage: Integer; var DotNetEnc: Codeunit DotNet_Encoding)
    begin
        DotNetEnc.Encoding(CodePage);
    end;

    [TryFunction]
    local procedure TryWrapperRoundTrip(var DotNetEnc: Codeunit DotNet_Encoding; Value: Text; var Hex: Text; var Codes: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Writer: Codeunit DotNet_StreamWriter;
        Reader: Codeunit DotNet_StreamReader;
        OutS: OutStream;
        InS: InStream;
        B: Byte;
        ByteValue: Integer;
        Decoded: Text;
        CharCode: Integer;
        i: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        Writer.StreamWriter(OutS, DotNetEnc);
        Writer.Write(Value);
        Writer.Flush();
        Writer.Close();
        TempBlob.CreateInStream(InS);
        Hex := '';
        while not InS.EOS() do begin
            InS.Read(B);
            ByteValue := B;
            Hex += Format(ByteValue) + ',';
        end;
        TempBlob.CreateInStream(InS);
        Reader.StreamReader(InS, DotNetEnc);
        Decoded := Reader.ReadToEnd();
        Reader.Close();
        Codes := '';
        for i := 1 to StrLen(Decoded) do begin
            CharCode := Decoded[i];
            Codes += Format(CharCode) + ',';
        end;
    end;

    local procedure ObserveWrapper(CodePage: Integer)
    var
        DotNetEnc: Codeunit DotNet_Encoding;
        Name: Text;
        Hex: Text;
        Codes: Text;
    begin
        Name := 'DotNet_Encoding ' + Format(CodePage);
        ClearLastError();
        if not TryWrapperEncoding(CodePage, DotNetEnc) then begin
            Observer.ObserveError(Name);
            exit;
        end;
        Observer.Observe(Name + ' Codepage', Format(DotNetEnc.Codepage()));
        // AE, O with stroke, A with ring: written bytes (decimal) and the character codes read back
        if TryWrapperRoundTrip(DotNetEnc, 'ÆØÅ', Hex, Codes) then
            Observer.Observe(Name + ' round trip', Hex + '|' + Codes)
        else
            Observer.ObserveError(Name + ' round trip');
    end;

    [Test]
    procedure RA_DotNetEncodingCodeunit_StreamRoundTrip()
    begin
        ObserveWrapper(1252);
        ObserveWrapper(850);
        ObserveWrapper(28591);
        ObserveWrapper(99999);
        Observer.Expect('DotNet_Encoding 1252 Codepage', '1252');
        Observer.Expect('DotNet_Encoding 1252 round trip', '198,216,197,|198,216,197,');
        Observer.Expect('DotNet_Encoding 850 Codepage', '850');
        Observer.Expect('DotNet_Encoding 850 round trip', '146,157,143,|198,216,197,');
        Observer.Expect('DotNet_Encoding 28591 Codepage', '28591');
        Observer.Expect('DotNet_Encoding 28591 round trip', '198,216,197,|198,216,197,');
        Observer.Expect('DotNet_Encoding 99999|text', 'A call to System.Text.Encoding.GetEncoding failed with this message: Valid values are between 0 and 65535, inclusive. (Parameter ''codepage'')');
        Observer.Expect('DotNet_Encoding 99999|code', 'DotNetInvoke:ArgumentOutOfRange');
        Observer.Verify();
    end;
}
