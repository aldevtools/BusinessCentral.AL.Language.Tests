// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-writetext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (codeunit 4100)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a text with e acute, u umlaut, euro sign and a 4-byte emoji (surrogate pair) written with OutStream.WriteText on a stream created with a given
// TextEncoding (or without one), read back with InStream.ReadText and InStream.Read on a stream with the same encoding and on one without an encoding:
// blob length, text length, character codes, EOS, Position.
// BC versions: 29 (27 and 28 by CI)

codeunit 71575 "LT P175 Stream Written"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Sample(): Text
    var
        Emoji: Text[2];
        Result: Text;
    begin
        Emoji[1] := 55357;
        Emoji[2] := 56832;
        Result := 'a' + 'é' + 'ü' + '€' + Emoji + 'b';
        exit(Result);
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

    [TryFunction]
    local procedure TryRead(var InS: InStream; Mode: Integer; var T: Text; var Cnt: Integer)
    begin
        if Mode = 0 then
            Cnt := InS.ReadText(T)
        else
            Cnt := InS.Read(T);
    end;

    local procedure Describe(var InS: InStream; Mode: Integer): Text
    var
        T: Text;
        Cnt: Integer;
    begin
        Cnt := -1;
        if not TryRead(InS, Mode, T, Cnt) then
            exit('err|' + CopyStr(GetLastErrorText(), 1, 150) + '|' + GetLastErrorCode());
        exit('ret=' + Format(Cnt) + ';len=' + Format(StrLen(T)) + ';codes=' + Codes(T) + ';eos=' + Format(InS.EOS()) + ';pos=' + Format(InS.Position()));
    end;

    [Test]
    procedure P175_Written_None()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Sample());
        Observer.Observe('blobLength', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        Observer.Observe('readText none', Describe(InS, 0));
        TempBlob.CreateInStream(InS);
        Observer.Observe('read none', Describe(InS, 1));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('readText utf8', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('readText utf16', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::MSDos);
        Observer.Observe('readText msdos', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('readText windows', Describe(InS, 0));
        Observer.Expect('blobLength', '7');
        Observer.Expect('readText none', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Expect('read none', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Expect('readText utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('readText utf16', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('readText msdos', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Expect('readText windows', 'ret=7;len=7;codes=97,8218,129,177,63,63,98;eos=Yes;pos=8');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Written_Utf8()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText(Sample());
        Observer.Observe('blobLength', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('readText same', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('read same', Describe(InS, 1));
        TempBlob.CreateInStream(InS);
        Observer.Observe('readText none', Describe(InS, 0));
        TempBlob.CreateInStream(InS);
        Observer.Observe('read none', Describe(InS, 1));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('readText utf8', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('readText utf16', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::MSDos);
        Observer.Observe('readText msdos', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('readText windows', Describe(InS, 0));
        Observer.Expect('blobLength', '13');
        Observer.Expect('readText same', 'ret=13;len=7;codes=97,233,252,8364,55357,56832,98;eos=Yes;pos=14');
        Observer.Expect('read same', 'ret=14;len=7;codes=97,233,252,8364,55357,56832,98;eos=Yes;pos=14');
        Observer.Expect('readText none', 'ret=13;len=13;codes=97,8220,20,8220,338,203,233,188,218,402,255,199,98;eos=Yes;pos=14');
        Observer.Expect('read none', 'ret=13;len=13;codes=97,8220,20,8220,338,203,233,188,218,402,255,199,98;eos=Yes;pos=14');
        Observer.Expect('readText utf8', 'ret=13;len=7;codes=97,233,252,8364,55357,56832,98;eos=Yes;pos=14');
        Observer.Expect('readText utf16', 'ret=14;len=7;codes=97,233,252,8364,55357,56832,98;eos=Yes;pos=14');
        Observer.Expect('readText msdos', 'ret=13;len=13;codes=97,8220,20,8220,338,203,233,188,218,402,255,199,98;eos=Yes;pos=14');
        Observer.Expect('readText windows', 'ret=13;len=13;codes=97,195,169,195,188,226,8218,172,240,376,732,8364,98;eos=Yes;pos=14');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Written_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF16);
        OutS.WriteText(Sample());
        Observer.Observe('blobLength', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('readText same', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('read same', Describe(InS, 1));
        TempBlob.CreateInStream(InS);
        Observer.Observe('readText none', Describe(InS, 0));
        TempBlob.CreateInStream(InS);
        Observer.Observe('read none', Describe(InS, 1));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('readText utf8', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('readText utf16', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::MSDos);
        Observer.Observe('readText msdos', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('readText windows', Describe(InS, 0));
        Observer.Expect('blobLength', '14');
        Observer.Expect('readText same', 'ret=14;len=7;codes=97,233,252,8364,55357,56832,98;eos=Yes;pos=15');
        Observer.Expect('read same', 'ret=16;len=7;codes=97,233,252,8364,55357,56832,98;eos=Yes;pos=15');
        Observer.Expect('readText none', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('read none', 'ret=2;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('readText utf8', 'ret=13;len=7;codes=97,233,252,8364,55357,56832,98;eos=Yes;pos=15');
        Observer.Expect('readText utf16', 'ret=14;len=7;codes=97,233,252,8364,55357,56832,98;eos=Yes;pos=15');
        Observer.Expect('readText msdos', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Expect('readText windows', 'ret=1;len=1;codes=97;eos=No;pos=3');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Written_MsDos()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::MSDos);
        OutS.WriteText(Sample());
        Observer.Observe('blobLength', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS, TextEncoding::MSDos);
        Observer.Observe('readText same', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::MSDos);
        Observer.Observe('read same', Describe(InS, 1));
        TempBlob.CreateInStream(InS);
        Observer.Observe('readText none', Describe(InS, 0));
        TempBlob.CreateInStream(InS);
        Observer.Observe('read none', Describe(InS, 1));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('readText utf8', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('readText utf16', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::MSDos);
        Observer.Observe('readText msdos', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('readText windows', Describe(InS, 0));
        Observer.Expect('blobLength', '7');
        Observer.Expect('readText same', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Expect('read same', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Expect('readText none', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Expect('read none', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Expect('readText utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('readText utf16', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('readText msdos', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Expect('readText windows', 'ret=7;len=7;codes=97,8218,129,177,63,63,98;eos=Yes;pos=8');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Written_Windows()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::Windows);
        OutS.WriteText(Sample());
        Observer.Observe('blobLength', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('readText same', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('read same', Describe(InS, 1));
        TempBlob.CreateInStream(InS);
        Observer.Observe('readText none', Describe(InS, 0));
        TempBlob.CreateInStream(InS);
        Observer.Observe('read none', Describe(InS, 1));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('readText utf8', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Observer.Observe('readText utf16', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::MSDos);
        Observer.Observe('readText msdos', Describe(InS, 0));
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('readText windows', Describe(InS, 0));
        Observer.Expect('blobLength', '7');
        Observer.Expect('readText same', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Expect('read same', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Expect('readText none', 'ret=7;len=7;codes=97,210,253,199,63,63,98;eos=Yes;pos=8');
        Observer.Expect('read none', 'ret=7;len=7;codes=97,210,253,199,63,63,98;eos=Yes;pos=8');
        Observer.Expect('readText utf8', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('readText utf16', 'err|Invalid data encountered in stream, unable to read text.|InvalidStreamData');
        Observer.Expect('readText msdos', 'ret=7;len=7;codes=97,210,253,199,63,63,98;eos=Yes;pos=8');
        Observer.Expect('readText windows', 'ret=7;len=7;codes=97,233,252,8364,63,63,98;eos=Yes;pos=8');
        Observer.Verify();
    end;
}
