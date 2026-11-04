// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 73707 "LT P132 OutStream Unicode"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Hex(var TempBlob: Codeunit "Temp Blob"): Text
    var
        Ins: InStream;
        B: Byte;
        Digits: Text;
        Result: Text;
    begin
        Digits := '0123456789ABCDEF';
        TempBlob.CreateInStream(Ins);
        Result := Format(TempBlob.Length()) + ':';
        while not Ins.EOS() do begin
            Ins.Read(B);
            Result += CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1);
        end;
        exit(Result);
    end;

    local procedure WriteDefault(var Observer: Codeunit "Probe Observer"; ObsName: Text; Value: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
        Ret: Integer;
    begin
        TempBlob.CreateOutStream(Out);
        Ret := Out.Write(Value);
        Observer.Observe(ObsName, Format(Ret) + '|' + Hex(TempBlob));
    end;

    local procedure WriteEnc(var Observer: Codeunit "Probe Observer"; ObsName: Text; Enc: TextEncoding; Value: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
        Ret: Integer;
    begin
        TempBlob.CreateOutStream(Out, Enc);
        Ret := Out.Write(Value);
        Observer.Observe(ObsName, Format(Ret) + '|' + Hex(TempBlob));
    end;

    local procedure RoundTrip(var Observer: Codeunit "Probe Observer"; ObsName: Text; Value: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
        Ins: InStream;
        Back: Text;
        Ret: Integer;
    begin
        TempBlob.CreateOutStream(Out);
        Out.Write(Value);
        TempBlob.CreateInStream(Ins);
        Ret := Ins.Read(Back);
        Observer.Observe(ObsName, Format(Ret) + '|' + Back + '|' + Format(Back = Value));
    end;

    [Test]
    procedure P132_Write_Default_NonLatin()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WriteDefault(Observer, 'japanese', '日本語テスト');
        WriteDefault(Observer, 'json_like', '{ ''name'': ''日本語テスト'' }');
        WriteDefault(Observer, 'cyrillic', 'Привет');
        WriteDefault(Observer, 'greek', 'αβγ');
        WriteDefault(Observer, 'u0100', 'Āā');
        WriteDefault(Observer, 'euro', '€');
        WriteDefault(Observer, 'mixed', 'a日b');
        WriteDefault(Observer, 'latin1', 'äöüß');
        WriteDefault(Observer, 'oe_ligature', 'Œœ');
        WriteDefault(Observer, 'ascii', 'abc');
        Observer.Expect('japanese', '7|7:3F3F3F3F3F3F00');
        Observer.Expect('json_like', '21|21:7B20276E616D65273A20273F3F3F3F3F3F27207D00');
        Observer.Expect('cyrillic', '7|7:3F3F3F3F3F3F00');
        Observer.Expect('greek', '4|4:61E13F00');
        Observer.Expect('u0100', '3|3:416100');
        Observer.Expect('euro', '2|2:B100');
        Observer.Expect('mixed', '4|4:613F6200');
        Observer.Expect('latin1', '5|5:849481E100');
        Observer.Expect('oe_ligature', '3|3:BCCC00');
        Observer.Expect('ascii', '4|4:61626300');
        Observer.Verify();
    end;

    [Test]
    procedure P132_Write_Default_Emoji_Surrogates()
    var
        Observer: Codeunit "Probe Observer";
        Smile: Text;
        Hi: Text[1];
        Lo: Text[1];
    begin
        Hi[1] := 55357;
        Lo[1] := 56832;
        Smile := Hi + Lo;
        WriteDefault(Observer, 'emoji_pair', Smile);
        WriteDefault(Observer, 'emoji_in_text', 'a' + Smile + 'b');
        Observer.Observe('emoji_len', Format(StrLen(Smile)));
        Observer.Expect('emoji_pair', '3|3:3F3F00');
        Observer.Expect('emoji_in_text', '5|5:613F3F6200');
        Observer.Expect('emoji_len', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P132_Write_PerEncoding_Japanese()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WriteEnc(Observer, 'utf8', TextEncoding::UTF8, '日本語テスト');
        WriteEnc(Observer, 'utf16', TextEncoding::UTF16, '日本語テスト');
        WriteEnc(Observer, 'windows', TextEncoding::Windows, '日本語テスト');
        WriteEnc(Observer, 'msdos', TextEncoding::MSDos, '日本語テスト');
        WriteEnc(Observer, 'utf8_json', TextEncoding::UTF8, '{ ''name'': ''日本語テスト'' }');
        WriteEnc(Observer, 'utf16_json', TextEncoding::UTF16, '{ ''name'': ''日本語テスト'' }');
        WriteEnc(Observer, 'windows_json', TextEncoding::Windows, '{ ''name'': ''日本語テスト'' }');
        WriteEnc(Observer, 'msdos_json', TextEncoding::MSDos, '{ ''name'': ''日本語テスト'' }');
        Observer.Expect('utf8', '19|19:E697A5E69CACE8AA9EE38386E382B9E3838800');
        Observer.Expect('utf16', '14|14:E5652C679E8AC630B930C8300000');
        Observer.Expect('windows', '7|7:3F3F3F3F3F3F00');
        Observer.Expect('msdos', '7|7:3F3F3F3F3F3F00');
        Observer.Expect('utf8_json', '33|33:7B20276E616D65273A2027E697A5E69CACE8AA9EE38386E382B9E3838827207D00');
        Observer.Expect('utf16_json', '42|42:7B00200027006E0061006D00650027003A0020002700E5652C679E8AC630B930C830270020007D000000');
        Observer.Expect('windows_json', '21|21:7B20276E616D65273A20273F3F3F3F3F3F27207D00');
        Observer.Expect('msdos_json', '21|21:7B20276E616D65273A20273F3F3F3F3F3F27207D00');
        Observer.Verify();
    end;

    [Test]
    procedure P132_Write_RoundTrip_ReadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RoundTrip(Observer, 'japanese', '日本語テスト');
        RoundTrip(Observer, 'json_like', '{ ''name'': ''日本語テスト'' }');
        RoundTrip(Observer, 'cyrillic', 'Привет');
        RoundTrip(Observer, 'mixed', 'a日b');
        RoundTrip(Observer, 'latin1', 'äöüß');
        RoundTrip(Observer, 'euro', '€');
        Observer.Expect('japanese', '7|??????|No');
        Observer.Expect('json_like', '21|{ ''name'': ''??????'' }|No');
        Observer.Expect('cyrillic', '7|??????|No');
        Observer.Expect('mixed', '4|a?b|No');
        Observer.Expect('latin1', '5|äöüß|Yes');
        Observer.Expect('euro', '2|€|Yes');
        Observer.Verify();
    end;
}
