// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (codeunit 4100)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: InStream.ReadText and InStream.Read into a Text of raw bytes ('a', one non-ASCII character, 'b') on a stream created with
// TextEncoding UTF8, UTF16, MSDos, Windows and on a stream created without an encoding; per test one character (e acute, u umlaut, euro sign, a 4-byte emoji)
// in three byte forms (UTF-8, UTF-16 LE, single byte / truncated). Observed: value returned, length, character codes, EOS and Position.
// The bytes are written with OutStream.Write(Byte) so the writing encoding plays no role.
// BC versions: 29 (27 and 28 by CI)

codeunit 71574 "LT P175 Stream Raw"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure HexVal(C: Text[1]): Integer
    begin
        exit(StrPos('0123456789ABCDEF', UpperCase(C)) - 1);
    end;

    local procedure Fill(var TempBlob: Codeunit "Temp Blob"; Hex: Text)
    var
        OutS: OutStream;
        B: Byte;
        i: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        i := 1;
        while i < StrLen(Hex) do begin
            B := HexVal(CopyStr(Hex, i, 1)) * 16 + HexVal(CopyStr(Hex, i + 1, 1));
            OutS.Write(B);
            i += 2;
        end;
    end;

    local procedure Codes(Value: Text): Text
    var
        i: Integer;
        Result: Text;
        C: Integer;
    begin
        for i := 1 to StrLen(Value) do begin
            C := Value[i];
            if Result <> '' then
                Result += ',';
            Result += Format(C);
        end;
        exit(Result);
    end;

    // Mode 0 = ReadText, 1 = Read
    [TryFunction]
    local procedure TryRead(var InS: InStream; Mode: Integer; var T: Text; var Cnt: Integer)
    begin
        if Mode = 0 then
            Cnt := InS.ReadText(T)
        else
            Cnt := InS.Read(T);
    end;

    local procedure ReadWith(Hex: Text; EncCode: Integer; Mode: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        T: Text;
        Cnt: Integer;
        Ok: Boolean;
    begin
        Fill(TempBlob, Hex);
        case EncCode of
            0:
                TempBlob.CreateInStream(InS);
            1:
                TempBlob.CreateInStream(InS, TextEncoding::UTF8);
            2:
                TempBlob.CreateInStream(InS, TextEncoding::UTF16);
            3:
                TempBlob.CreateInStream(InS, TextEncoding::MSDos);
            4:
                TempBlob.CreateInStream(InS, TextEncoding::Windows);
        end;
        Cnt := -1;
        Ok := TryRead(InS, Mode, T, Cnt);
        if not Ok then
            exit('err|' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode());
        exit('ret=' + Format(Cnt) + ';len=' + Format(StrLen(T)) + ';codes=' + Codes(T) + ';eos=' + Format(InS.EOS()) + ';pos=' + Format(InS.Position()));
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer"; Hex: Text; Mode: Integer; Form: Text)
    begin
        Observer.Observe(Form + ' none', ReadWith(Hex, 0, Mode));
        Observer.Observe(Form + ' utf8', ReadWith(Hex, 1, Mode));
        Observer.Observe(Form + ' utf16', ReadWith(Hex, 2, Mode));
        Observer.Observe(Form + ' msdos', ReadWith(Hex, 3, Mode));
        Observer.Observe(Form + ' windows', ReadWith(Hex, 4, Mode));
    end;


    [Test]
    procedure P175_Raw_EAcute_ReadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAll(Observer, '61C3A962', 0, 'utf8');
        ObserveAll(Observer, '6100E9006200', 0, 'utf16');
        ObserveAll(Observer, '61E962', 0, 'single');
        Observer.Expect('utf8 none', 'ret=4;len=4;codes=97,8220,20,98;eos=Yes;pos=5');
        Observer.Expect('utf8 utf8', 'ret=4;len=3;codes=97,233,98;eos=Yes;pos=5');
        Observer.Expect('utf8 utf16', 'ret=4;len=2;codes=50017,25257;eos=Yes;pos=5');
        Observer.Expect('utf8 msdos', 'ret=4;len=4;codes=97,8220,20,98;eos=Yes;pos=5');
        Observer.Expect('utf8 windows', 'ret=4;len=4;codes=97,195,169,98;eos=Yes;pos=5');
        Observer.Expect('utf16 none', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf8', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf16', 'ret=6;len=3;codes=97,233,98;eos=Yes;pos=7');
        Observer.Expect('utf16 msdos', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 windows', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('single none', 'ret=3;len=3;codes=97,210,98;eos=Yes;pos=4');
        Observer.Expect('single utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('single utf16', 'ret=2;len=1;codes=59745;eos=Yes;pos=4');
        Observer.Expect('single msdos', 'ret=3;len=3;codes=97,210,98;eos=Yes;pos=4');
        Observer.Expect('single windows', 'ret=3;len=3;codes=97,233,98;eos=Yes;pos=4');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Raw_EAcute_Read()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAll(Observer, '61C3A962', 1, 'utf8');
        ObserveAll(Observer, '6100E9006200', 1, 'utf16');
        ObserveAll(Observer, '61E962', 1, 'single');
        Observer.Expect('utf8 none', 'ret=4;len=4;codes=97,8220,20,98;eos=Yes;pos=5');
        Observer.Expect('utf8 utf8', 'ret=5;len=3;codes=97,233,98;eos=Yes;pos=5');
        Observer.Expect('utf8 utf16', 'ret=6;len=2;codes=50017,25257;eos=Yes;pos=5');
        Observer.Expect('utf8 msdos', 'ret=4;len=4;codes=97,8220,20,98;eos=Yes;pos=5');
        Observer.Expect('utf8 windows', 'ret=4;len=4;codes=97,195,169,98;eos=Yes;pos=5');
        Observer.Expect('utf16 none', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf8', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf16', 'ret=8;len=3;codes=97,233,98;eos=Yes;pos=7');
        Observer.Expect('utf16 msdos', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 windows', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('single none', 'ret=3;len=3;codes=97,210,98;eos=Yes;pos=4');
        Observer.Expect('single utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('single utf16', 'ret=4;len=1;codes=59745;eos=Yes;pos=4');
        Observer.Expect('single msdos', 'ret=3;len=3;codes=97,210,98;eos=Yes;pos=4');
        Observer.Expect('single windows', 'ret=3;len=3;codes=97,233,98;eos=Yes;pos=4');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Raw_UUml_ReadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAll(Observer, '61C3BC62', 0, 'utf8');
        ObserveAll(Observer, '6100FC006200', 0, 'utf16');
        ObserveAll(Observer, '61FC62', 0, 'single');
        Observer.Expect('utf8 none', 'ret=4;len=4;codes=97,8220,338,98;eos=Yes;pos=5');
        Observer.Expect('utf8 utf8', 'ret=4;len=3;codes=97,252,98;eos=Yes;pos=5');
        Observer.Expect('utf8 utf16', 'ret=4;len=2;codes=50017,25276;eos=Yes;pos=5');
        Observer.Expect('utf8 msdos', 'ret=4;len=4;codes=97,8220,338,98;eos=Yes;pos=5');
        Observer.Expect('utf8 windows', 'ret=4;len=4;codes=97,195,188,98;eos=Yes;pos=5');
        Observer.Expect('utf16 none', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf8', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf16', 'ret=6;len=3;codes=97,252,98;eos=Yes;pos=7');
        Observer.Expect('utf16 msdos', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 windows', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('single none', 'ret=3;len=3;codes=97,253,98;eos=Yes;pos=4');
        Observer.Expect('single utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('single utf16', 'ret=2;len=1;codes=64609;eos=Yes;pos=4');
        Observer.Expect('single msdos', 'ret=3;len=3;codes=97,253,98;eos=Yes;pos=4');
        Observer.Expect('single windows', 'ret=3;len=3;codes=97,252,98;eos=Yes;pos=4');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Raw_UUml_Read()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAll(Observer, '61C3BC62', 1, 'utf8');
        ObserveAll(Observer, '6100FC006200', 1, 'utf16');
        ObserveAll(Observer, '61FC62', 1, 'single');
        Observer.Expect('utf8 none', 'ret=4;len=4;codes=97,8220,338,98;eos=Yes;pos=5');
        Observer.Expect('utf8 utf8', 'ret=5;len=3;codes=97,252,98;eos=Yes;pos=5');
        Observer.Expect('utf8 utf16', 'ret=6;len=2;codes=50017,25276;eos=Yes;pos=5');
        Observer.Expect('utf8 msdos', 'ret=4;len=4;codes=97,8220,338,98;eos=Yes;pos=5');
        Observer.Expect('utf8 windows', 'ret=4;len=4;codes=97,195,188,98;eos=Yes;pos=5');
        Observer.Expect('utf16 none', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf8', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf16', 'ret=8;len=3;codes=97,252,98;eos=Yes;pos=7');
        Observer.Expect('utf16 msdos', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 windows', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('single none', 'ret=3;len=3;codes=97,253,98;eos=Yes;pos=4');
        Observer.Expect('single utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('single utf16', 'ret=4;len=1;codes=64609;eos=Yes;pos=4');
        Observer.Expect('single msdos', 'ret=3;len=3;codes=97,253,98;eos=Yes;pos=4');
        Observer.Expect('single windows', 'ret=3;len=3;codes=97,252,98;eos=Yes;pos=4');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Raw_Euro_ReadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAll(Observer, '61E282AC62', 0, 'utf8');
        ObserveAll(Observer, '6100AC206200', 0, 'utf16');
        ObserveAll(Observer, '618062', 0, 'single');
        Observer.Expect('utf8 none', 'ret=5;len=5;codes=97,203,233,188,98;eos=Yes;pos=6');
        Observer.Expect('utf8 utf8', 'ret=5;len=3;codes=97,8364,98;eos=Yes;pos=6');
        Observer.Expect('utf8 utf16', 'ret=4;len=2;codes=57953,44162;eos=Yes;pos=6');
        Observer.Expect('utf8 msdos', 'ret=5;len=5;codes=97,203,233,188,98;eos=Yes;pos=6');
        Observer.Expect('utf8 windows', 'ret=5;len=5;codes=97,226,8218,172,98;eos=Yes;pos=6');
        Observer.Expect('utf16 none', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf8', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf16', 'ret=6;len=3;codes=97,8364,98;eos=Yes;pos=7');
        Observer.Expect('utf16 msdos', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 windows', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('single none', 'ret=3;len=3;codes=97,199,98;eos=Yes;pos=4');
        Observer.Expect('single utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('single utf16', 'ret=2;len=1;codes=32865;eos=Yes;pos=4');
        Observer.Expect('single msdos', 'ret=3;len=3;codes=97,199,98;eos=Yes;pos=4');
        Observer.Expect('single windows', 'ret=3;len=3;codes=97,8364,98;eos=Yes;pos=4');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Raw_Euro_Read()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAll(Observer, '61E282AC62', 1, 'utf8');
        ObserveAll(Observer, '6100AC206200', 1, 'utf16');
        ObserveAll(Observer, '618062', 1, 'single');
        Observer.Expect('utf8 none', 'ret=5;len=5;codes=97,203,233,188,98;eos=Yes;pos=6');
        Observer.Expect('utf8 utf8', 'ret=6;len=3;codes=97,8364,98;eos=Yes;pos=6');
        Observer.Expect('utf8 utf16', 'ret=6;len=2;codes=57953,44162;eos=Yes;pos=6');
        Observer.Expect('utf8 msdos', 'ret=5;len=5;codes=97,203,233,188,98;eos=Yes;pos=6');
        Observer.Expect('utf8 windows', 'ret=5;len=5;codes=97,226,8218,172,98;eos=Yes;pos=6');
        Observer.Expect('utf16 none', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf8', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf16', 'ret=8;len=3;codes=97,8364,98;eos=Yes;pos=7');
        Observer.Expect('utf16 msdos', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 windows', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('single none', 'ret=3;len=3;codes=97,199,98;eos=Yes;pos=4');
        Observer.Expect('single utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('single utf16', 'ret=4;len=1;codes=32865;eos=Yes;pos=4');
        Observer.Expect('single msdos', 'ret=3;len=3;codes=97,199,98;eos=Yes;pos=4');
        Observer.Expect('single windows', 'ret=3;len=3;codes=97,8364,98;eos=Yes;pos=4');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Raw_Emoji_ReadText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAll(Observer, '61F09F988062', 0, 'utf8');
        ObserveAll(Observer, '61003DD800DE6200', 0, 'utf16');
        ObserveAll(Observer, '61F09F62', 0, 'trunc');
        Observer.Expect('utf8 none', 'ret=6;len=6;codes=97,218,402,255,199,98;eos=Yes;pos=7');
        Observer.Expect('utf8 utf8', 'ret=6;len=4;codes=97,55357,56832,98;eos=Yes;pos=7');
        Observer.Expect('utf8 utf16', 'ret=6;len=3;codes=61537,39071,25216;eos=Yes;pos=7');
        Observer.Expect('utf8 msdos', 'ret=6;len=6;codes=97,218,402,255,199,98;eos=Yes;pos=7');
        Observer.Expect('utf8 windows', 'ret=6;len=6;codes=97,240,376,732,8364,98;eos=Yes;pos=7');
        Observer.Expect('utf16 none', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf8', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf16', 'ret=8;len=4;codes=97,55357,56832,98;eos=Yes;pos=9');
        Observer.Expect('utf16 msdos', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 windows', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('trunc none', 'ret=4;len=4;codes=97,218,402,98;eos=Yes;pos=5');
        Observer.Expect('trunc utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('trunc utf16', 'ret=4;len=2;codes=61537,25247;eos=Yes;pos=5');
        Observer.Expect('trunc msdos', 'ret=4;len=4;codes=97,218,402,98;eos=Yes;pos=5');
        Observer.Expect('trunc windows', 'ret=4;len=4;codes=97,240,376,98;eos=Yes;pos=5');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Raw_Emoji_Read()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAll(Observer, '61F09F988062', 1, 'utf8');
        ObserveAll(Observer, '61003DD800DE6200', 1, 'utf16');
        ObserveAll(Observer, '61F09F62', 1, 'trunc');
        Observer.Expect('utf8 none', 'ret=6;len=6;codes=97,218,402,255,199,98;eos=Yes;pos=7');
        Observer.Expect('utf8 utf8', 'ret=7;len=4;codes=97,55357,56832,98;eos=Yes;pos=7');
        Observer.Expect('utf8 utf16', 'ret=8;len=3;codes=61537,39071,25216;eos=Yes;pos=7');
        Observer.Expect('utf8 msdos', 'ret=6;len=6;codes=97,218,402,255,199,98;eos=Yes;pos=7');
        Observer.Expect('utf8 windows', 'ret=6;len=6;codes=97,240,376,732,8364,98;eos=Yes;pos=7');
        Observer.Expect('utf16 none', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf8', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 utf16', 'ret=10;len=4;codes=97,55357,56832,98;eos=Yes;pos=9');
        Observer.Expect('utf16 msdos', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('utf16 windows', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('trunc none', 'ret=4;len=4;codes=97,218,402,98;eos=Yes;pos=5');
        Observer.Expect('trunc utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('trunc utf16', 'ret=6;len=2;codes=61537,25247;eos=Yes;pos=5');
        Observer.Expect('trunc msdos', 'ret=4;len=4;codes=97,218,402,98;eos=Yes;pos=5');
        Observer.Expect('trunc windows', 'ret=4;len=4;codes=97,240,376,98;eos=Yes;pos=5');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Raw_AsciiOnly_AllEncodings()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveAll(Observer, '616263', 0, 'abc');
        ObserveAll(Observer, '616263', 1, 'abcRead');
        Observer.Expect('abc none', 'ret=3;len=3;codes=97,98,99;eos=Yes;pos=4');
        Observer.Expect('abc utf8', 'ret=3;len=3;codes=97,98,99;eos=Yes;pos=4');
        Observer.Expect('abc utf16', 'ret=2;len=1;codes=25185;eos=Yes;pos=4');
        Observer.Expect('abc msdos', 'ret=3;len=3;codes=97,98,99;eos=Yes;pos=4');
        Observer.Expect('abc windows', 'ret=3;len=3;codes=97,98,99;eos=Yes;pos=4');
        Observer.Expect('abcRead none', 'ret=3;len=3;codes=97,98,99;eos=Yes;pos=4');
        Observer.Expect('abcRead utf8', 'ret=4;len=3;codes=97,98,99;eos=Yes;pos=4');
        Observer.Expect('abcRead utf16', 'ret=4;len=1;codes=25185;eos=Yes;pos=4');
        Observer.Expect('abcRead msdos', 'ret=3;len=3;codes=97,98,99;eos=Yes;pos=4');
        Observer.Expect('abcRead windows', 'ret=3;len=3;codes=97,98,99;eos=Yes;pos=4');
        Observer.Verify();
    end;
}
