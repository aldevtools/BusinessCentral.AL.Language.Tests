// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-read-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (codeunit 4100)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: ONE character per stream (e acute, euro sign, U+4E2D, a 4-byte emoji = surrogate pair) written with OutStream.WriteText on a UTF8 stream and read back with InStream.Read / ReadText
// from a UTF8 stream, into Text, Text[2] and Text[1] variables and with a length argument (1, 2, 3, 4): return value, text length, character codes, EOS, Position.
// The emoji does not fit a one-character Text[1]: the observation shows truncation or the error. LT P175 Stream Written (streams/lt-stream-non-ascii) pins the combined string 'a' + e acute +
// u umlaut + euro + emoji + 'b'; U+4E2D, the single characters, the length arguments and the bounded targets are new here.
// BC versions: 29 (27 and 28 by CI)

codeunit 71701 "LT Stream Utf8 Chars"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure CharText(Which: Integer): Text
    var
        T: Text[2];
        One: Text[1];
    begin
        case Which of
            1:
                One[1] := 233;
            2:
                One[1] := 8364;
            3:
                One[1] := 20013;
            4:
                begin
                    T[1] := 55357;
                    T[2] := 56832;
                    exit(T);
                end;
        end;
        exit(One);
    end;

    local procedure Codes(Value: Text): Text
    var
        i: Integer;
        C: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            C := Value[i];
            if Result <> '' then
                Result += ',';
            Result += Format(C);
        end;
        exit(Result);
    end;

    [TryFunction]
    local procedure DoRead(var InS: InStream; Mode: Integer; Len: Integer; var T: Text)
    begin
        case Mode of
            0:
                InS.Read(T);
            1:
                InS.Read(T, Len);
            2:
                InS.ReadText(T);
            3:
                InS.ReadText(T, Len);
        end;
    end;

    [TryFunction]
    local procedure DoRead2(var InS: InStream; Mode: Integer; Len: Integer; var T: Text[2])
    begin
        if Mode = 0 then
            InS.Read(T)
        else
            InS.Read(T, Len);
    end;

    [TryFunction]
    local procedure DoRead1(var InS: InStream; Mode: Integer; Len: Integer; var T: Text[1])
    begin
        if Mode = 0 then
            InS.Read(T)
        else
            InS.Read(T, Len);
    end;

    local procedure Describe(var InS: InStream; Mode: Integer; Len: Integer): Text
    var
        T: Text;
    begin
        if not DoRead(InS, Mode, Len, T) then
            exit('err|' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode());
        exit('len=' + Format(StrLen(T)) + ';codes=' + Codes(T) + ';eos=' + Format(InS.EOS()) + ';pos=' + Format(InS.Position()));
    end;

    local procedure Describe2(var InS: InStream; Mode: Integer; Len: Integer): Text
    var
        T: Text[2];
    begin
        if not DoRead2(InS, Mode, Len, T) then
            exit('err|' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode());
        exit('len=' + Format(StrLen(T)) + ';codes=' + Codes(T) + ';eos=' + Format(InS.EOS()) + ';pos=' + Format(InS.Position()));
    end;

    local procedure Describe1(var InS: InStream; Mode: Integer; Len: Integer): Text
    var
        T: Text[1];
    begin
        if not DoRead1(InS, Mode, Len, T) then
            exit('err|' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode());
        exit('len=' + Format(StrLen(T)) + ';codes=' + Codes(T) + ';eos=' + Format(InS.EOS()) + ';pos=' + Format(InS.Position()));
    end;

    local procedure Fill(var TempBlob: Codeunit "Temp Blob"; Which: Integer)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(CharText(Which));
    end;

    local procedure ObserveChar(var Observer: Codeunit "Probe Observer"; Which: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Len: Integer;
    begin
        Fill(TempBlob, Which);
        Observer.Observe('blobLength', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('Read(Text)', Describe(InS, 0, 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('ReadText(Text)', Describe(InS, 2, 0));
        for Len := 1 to 4 do begin
            TempBlob.CreateInStream(InS, TextEncoding::UTF8);
            Observer.Observe('Read(Text,' + Format(Len) + ')', Describe(InS, 1, Len));
        end;
        for Len := 1 to 2 do begin
            TempBlob.CreateInStream(InS, TextEncoding::UTF8);
            Observer.Observe('ReadText(Text,' + Format(Len) + ')', Describe(InS, 3, Len));
        end;
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('Read(Text[2])', Describe2(InS, 0, 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('Read(Text[2],1)', Describe2(InS, 1, 1));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('Read(Text[2],2)', Describe2(InS, 1, 2));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('Read(Text[1])', Describe1(InS, 0, 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('Read(Text[1],1)', Describe1(InS, 1, 1));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('Read(Text[1],2)', Describe1(InS, 1, 2));
    end;

    [Test]
    procedure Utf8_EAcute_ReadVariants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveChar(Observer, 1);
        Observer.Expect('blobLength', '2');
        Observer.Expect('Read(Text)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('ReadText(Text)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('Read(Text,1)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('Read(Text,2)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('Read(Text,3)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('Read(Text,4)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('ReadText(Text,1)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('ReadText(Text,2)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('Read(Text[2])', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('Read(Text[2],1)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('Read(Text[2],2)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('Read(Text[1])', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('Read(Text[1],1)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Expect('Read(Text[1],2)', 'len=1;codes=233;eos=Yes;pos=3');
        Observer.Verify();
    end;

    [Test]
    procedure Utf8_Euro_ReadVariants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveChar(Observer, 2);
        Observer.Expect('blobLength', '3');
        Observer.Expect('Read(Text)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('ReadText(Text)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('Read(Text,1)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('Read(Text,2)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('Read(Text,3)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('Read(Text,4)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('ReadText(Text,1)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('ReadText(Text,2)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('Read(Text[2])', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('Read(Text[2],1)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('Read(Text[2],2)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('Read(Text[1])', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('Read(Text[1],1)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Expect('Read(Text[1],2)', 'len=1;codes=8364;eos=Yes;pos=4');
        Observer.Verify();
    end;

    [Test]
    procedure Utf8_U4E2D_ReadVariants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveChar(Observer, 3);
        Observer.Expect('blobLength', '3');
        Observer.Expect('Read(Text)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('ReadText(Text)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('Read(Text,1)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('Read(Text,2)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('Read(Text,3)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('Read(Text,4)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('ReadText(Text,1)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('ReadText(Text,2)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('Read(Text[2])', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('Read(Text[2],1)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('Read(Text[2],2)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('Read(Text[1])', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('Read(Text[1],1)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Expect('Read(Text[1],2)', 'len=1;codes=20013;eos=Yes;pos=4');
        Observer.Verify();
    end;

    [Test]
    procedure Utf8_Emoji_ReadVariants()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveChar(Observer, 4);
        Observer.Expect('blobLength', '4');
        Observer.Expect('Read(Text)', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('ReadText(Text)', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('Read(Text,1)', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('Read(Text,2)', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('Read(Text,3)', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('Read(Text,4)', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('ReadText(Text,1)', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('ReadText(Text,2)', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('Read(Text[2])', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('Read(Text[2],1)', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('Read(Text[2],2)', 'len=2;codes=55357,56832;eos=Yes;pos=5');
        Observer.Expect('Read(Text[1])', 'err|The length of the string is 2, but it must be less than or equal to 1 characters. Value: \uD83D\uDE00|StringLengthExceeded');
        Observer.Expect('Read(Text[1],1)', 'err|The length of the string is 2, but it must be less than or equal to 1 characters. Value: \uD83D\uDE00|StringLengthExceeded');
        Observer.Expect('Read(Text[1],2)', 'err|The length of the string is 2, but it must be less than or equal to 1 characters. Value: \uD83D\uDE00|StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure Utf8_CjkRun_ThreeChars_LengthArguments()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Run: Text;
        T: Text;
        N: Integer;
        Len: Integer;
    begin
        Run := CharText(3) + CharText(3) + 'x';
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Run);
        Observer.Observe('blobLength', Format(TempBlob.Length()));
        for Len := 1 to 4 do begin
            TempBlob.CreateInStream(InS, TextEncoding::UTF8);
            Observer.Observe('Read(Text,' + Format(Len) + ')', Describe(InS, 1, Len));
        end;
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('two reads', Describe(InS, 1, 1) + ' // ' + Describe(InS, 1, 1));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        N := InS.Read(T, 2);
        Observer.Observe('Read(T,2) return', Format(N) + ';' + Format(StrLen(T)) + ';pos=' + Format(InS.Position()));
        Observer.Expect('blobLength', '7');
        Observer.Expect('Read(Text,1)', 'len=1;codes=20013;eos=No;pos=4');
        Observer.Expect('Read(Text,2)', 'len=2;codes=20013,20013;eos=No;pos=7');
        Observer.Expect('Read(Text,3)', 'len=3;codes=20013,20013,120;eos=Yes;pos=8');
        Observer.Expect('Read(Text,4)', 'len=3;codes=20013,20013,120;eos=Yes;pos=8');
        Observer.Expect('two reads', 'len=1;codes=20013;eos=No;pos=4 // len=1;codes=20013;eos=No;pos=7');
        Observer.Expect('Read(T,2) return', '7;2;pos=7');
        Observer.Verify();
    end;
}
