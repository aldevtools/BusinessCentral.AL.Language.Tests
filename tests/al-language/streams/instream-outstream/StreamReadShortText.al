// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-read-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); Temp Blob (System Application)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: InStream.Read(Text) and Read(Text, Length) into a Text[N] variable shorter than the characters in the stream (UTF-8, Windows and UTF-16 streams), what the next read finds afterwards, a read at the end of the stream, and Read(Text) of a stream written without a terminator
// Settles docs/probes-needed.md row "InStream.Read(Text)" (Probe fixes): REFUSED cases "a read at the end of the stream" and "a Text variable shorter than the characters"
// BC versions: 29 (27 and 28 by CI)

codeunit 74316 "LT P166 Stream Read Short"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryReadShort(var InS: InStream; var Target: Text[3]; var Count: Integer)
    begin
        Count := InS.Read(Target);
    end;

    [TryFunction]
    local procedure TryReadShortLength(var InS: InStream; var Target: Text[3]; Length: Integer; var Count: Integer)
    begin
        Count := InS.Read(Target, Length);
    end;

    [TryFunction]
    local procedure TryReadText(var InS: InStream; var Target: Text; var Count: Integer)
    begin
        Count := InS.Read(Target);
    end;

    local procedure Codes(Value: Text): Text
    var
        i: Integer;
        Code: Integer;
        Result: Text;
    begin
        for i := 1 to StrLen(Value) do begin
            Code := Value[i];
            Result += Format(Code) + ' ';
        end;
        exit(Result.TrimEnd());
    end;

    local procedure WriteTerminated(var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding; First: Text; Second: Text)
    var
        OutS: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, Encoding);
        OutS.Write(First);
        if Second <> '' then
            OutS.Write(Second);
    end;

    local procedure ObserveShort(var Observer: Codeunit "Probe Observer"; Name: Text; var TempBlob: Codeunit "Temp Blob"; Encoding: TextEncoding)
    var
        InS: InStream;
        Target: Text[3];
        Count: Integer;
        Passed: Boolean;
    begin
        TempBlob.CreateInStream(InS, Encoding);
        Passed := TryReadShort(InS, Target, Count);
        Observer.Observe(Name + '_first_noError', Format(Passed));
        if Passed then begin
            Observer.Observe(Name + '_first_count', Format(Count));
            Observer.Observe(Name + '_first_value', Target);
        end else
            Observer.ObserveError(Name + '_first');
        Clear(Target);
        Passed := TryReadShort(InS, Target, Count);
        Observer.Observe(Name + '_second_noError', Format(Passed));
        if Passed then begin
            Observer.Observe(Name + '_second_count', Format(Count));
            Observer.Observe(Name + '_second_value', Target);
        end else
            Observer.ObserveError(Name + '_second');
        Observer.Observe(Name + '_eos', Format(InS.EOS()));
    end;

    [Test]
    procedure ReadText_IntoShorterVariable_Utf8()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        WriteTerminated(TempBlob, TextEncoding::UTF8, 'abcdef', 'gh');
        ObserveShort(Observer, 'utf8', TempBlob, TextEncoding::UTF8);
        Observer.Expect('utf8_first_noError', 'Yes');
        Observer.Expect('utf8_first_count', '4');
        Observer.Expect('utf8_first_value', 'abc');
        Observer.Expect('utf8_second_noError', 'Yes');
        Observer.Expect('utf8_second_count', '4');
        Observer.Expect('utf8_second_value', 'def');
        Observer.Expect('utf8_eos', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_IntoShorterVariable_Windows()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        WriteTerminated(TempBlob, TextEncoding::Windows, 'abcdef', 'gh');
        ObserveShort(Observer, 'windows', TempBlob, TextEncoding::Windows);
        Observer.Expect('windows_first_noError', 'Yes');
        Observer.Expect('windows_first_count', '3');
        Observer.Expect('windows_first_value', 'abc');
        Observer.Expect('windows_second_noError', 'Yes');
        Observer.Expect('windows_second_count', '4');
        Observer.Expect('windows_second_value', 'def');
        Observer.Expect('windows_eos', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_IntoShorterVariable_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
    begin
        WriteTerminated(TempBlob, TextEncoding::UTF16, 'abcdef', 'gh');
        ObserveShort(Observer, 'utf16', TempBlob, TextEncoding::UTF16);
        Observer.Expect('utf16_first_noError', 'Yes');
        Observer.Expect('utf16_first_count', '8');
        Observer.Expect('utf16_first_value', 'abc');
        Observer.Expect('utf16_second_noError', 'Yes');
        Observer.Expect('utf16_second_count', '8');
        Observer.Expect('utf16_second_value', 'def');
        Observer.Expect('utf16_eos', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReadTextLength_IntoShorterVariable()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Target: Text[3];
        Count: Integer;
        Passed: Boolean;
    begin
        WriteTerminated(TempBlob, TextEncoding::UTF8, 'abcdef', '');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Passed := TryReadShortLength(InS, Target, 5, Count);
        Observer.Observe('len5_noError', Format(Passed));
        if Passed then begin
            Observer.Observe('len5_count', Format(Count));
            Observer.Observe('len5_value', Target);
        end else
            ObserveRestError(Observer, 'len5');
        Clear(Target);
        Passed := TryReadShortLength(InS, Target, 2, Count);
        Observer.Observe('len2_noError', Format(Passed));
        if Passed then begin
            Observer.Observe('len2_count', Format(Count));
            Observer.Observe('len2_value', Target);
        end else
            ObserveRestError(Observer, 'len2');
        Observer.Expect('len5_noError', 'Yes');
        Observer.Expect('len5_count', '4');
        Observer.Expect('len5_value', 'abc');
        Observer.Expect('len2_noError', 'Yes');
        Observer.Expect('len2_count', '3');
        Observer.Expect('len2_value', 'de');
        Observer.Verify();
    end;

    local procedure ObserveRestError(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure ReadText_AtTheEndOfTheStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Target: Text;
        Count: Integer;
        Passed: Boolean;
    begin
        WriteTerminated(TempBlob, TextEncoding::UTF8, 'ab', '');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Passed := TryReadText(InS, Target, Count);
        Observer.Observe('first_noError', Format(Passed));
        Observer.Observe('first_count', Format(Count));
        Observer.Observe('first_codes', Codes(Target));
        Observer.Observe('eosAfterFirst', Format(InS.EOS()));
        Target := 'unchanged';
        Count := -1;
        Passed := TryReadText(InS, Target, Count);
        Observer.Observe('atEnd_noError', Format(Passed));
        if not Passed then
            Observer.ObserveError('atEnd');
        Observer.Observe('atEnd_count', Format(Count));
        Observer.Observe('atEnd_value', Target);
        Observer.Expect('first_noError', 'Yes');
        Observer.Expect('first_count', '3');
        Observer.Expect('first_codes', '97 98');
        Observer.Expect('eosAfterFirst', 'Yes');
        Observer.Expect('atEnd_noError', 'Yes');
        Observer.Expect('atEnd_count', '1');
        Observer.Expect('atEnd_value', '');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_AtTheEndOfTheStream_Utf16AndWindows()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Target: Text;
        Count: Integer;
        Passed: Boolean;
    begin
        WriteTerminated(TempBlob, TextEncoding::UTF16, 'ab', '');
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        Passed := TryReadText(InS, Target, Count);
        Count := 0;
        Passed := TryReadText(InS, Target, Count);
        Observer.Observe('utf16_atEnd_noError', Format(Passed));
        if not Passed then
            Observer.ObserveError('utf16_atEnd');
        Observer.Observe('utf16_atEnd_count', Format(Count));
        WriteTerminated(TempBlob, TextEncoding::Windows, 'ab', '');
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Passed := TryReadText(InS, Target, Count);
        Count := 0;
        Passed := TryReadText(InS, Target, Count);
        Observer.Observe('windows_atEnd_noError', Format(Passed));
        if not Passed then
            Observer.ObserveError('windows_atEnd');
        Observer.Observe('windows_atEnd_count', Format(Count));
        Observer.Expect('utf16_atEnd_noError', 'Yes');
        Observer.Expect('utf16_atEnd_count', '2');
        Observer.Expect('windows_atEnd_noError', 'Yes');
        Observer.Expect('windows_atEnd_count', '0');
        Observer.Verify();
    end;
}
