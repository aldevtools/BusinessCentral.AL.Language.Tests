// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-writetext-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 90740 and codeunit 90741 of WdCallStackToBlob.al
// Probe: written against al-runner issue 6853 (follow-up of 6310). The call stack text of a collected error and of the last error is written to a Blob with
//        OutStream.WriteText and OutStream.Write for every encoding and read back with InStream.ReadText and InStream.Read.
// Facts: stream length relative to StrLen, equality of the read-back text, the lines ReadText returns; the reporter's three shapes. The call stack text itself is not asserted.
// BC versions: 27, 28, 29

codeunit 94890 "LT WD Call Stack Write Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Collected(): Text
    var
        ErrInfo: ErrorInfo;
        Stack: Text;
    begin
        ErrInfo := ErrorInfo.Create('boom');
        ErrInfo.Collectible := true;
        Error(ErrInfo);
        foreach ErrInfo in GetCollectedErrors(true) do
            Stack := ErrInfo.Callstack();
        ClearCollectedErrors();
        exit(Stack);
    end;

    local procedure LastError(): Text
    var
        Worker: Codeunit "LT WD Call Stack Worker";
    begin
        if Worker.Fail() then;
        exit(GetLastErrorCallStack());
    end;

    local procedure Mark(): Text
    var
        Txt: Text[3];
    begin
        Txt[1] := 'a';
        Txt[2] := 64976;
        Txt[3] := 'b';
        exit(Txt);
    end;

    local procedure Open(var Log: Record "LT WD Call Stack Log" temporary; var OutStr: OutStream; Mode: Integer)
    begin
        Log."Entry No." += 1;
        case Mode of
            0:
                Log."Call Stack".CreateOutStream(OutStr);
            1:
                Log."Call Stack".CreateOutStream(OutStr, TextEncoding::UTF8);
            2:
                Log."Call Stack".CreateOutStream(OutStr, TextEncoding::UTF16);
            3:
                Log."Call Stack".CreateOutStream(OutStr, TextEncoding::Windows);
            4:
                Log."Call Stack".CreateOutStream(OutStr, TextEncoding::MSDos);
        end;
    end;

    local procedure OpenIn(var Log: Record "LT WD Call Stack Log" temporary; var InStr: InStream; Mode: Integer)
    begin
        case Mode of
            0:
                Log."Call Stack".CreateInStream(InStr);
            1:
                Log."Call Stack".CreateInStream(InStr, TextEncoding::UTF8);
            2:
                Log."Call Stack".CreateInStream(InStr, TextEncoding::UTF16);
            3:
                Log."Call Stack".CreateInStream(InStr, TextEncoding::Windows);
            4:
                Log."Call Stack".CreateInStream(InStr, TextEncoding::MSDos);
        end;
    end;

    local procedure FirstLine(Value: Text): Text
    var
        At: Integer;
    begin
        for At := 1 to StrLen(Value) do
            if (Value[At] = 13) or (Value[At] = 10) then
                exit(CopyStr(Value, 1, At - 1));
        exit(Value);
    end;

    local procedure NoBreaks(Value: Text): Text
    var
        Cr: Text[1];
        Lf: Text[1];
    begin
        Cr[1] := 13;
        Lf[1] := 10;
        exit(Value.Replace(Cr, '').Replace(Lf, ''));
    end;

    // Writes Orig with WriteText (Method 1), Write (Method 2) or WriteText with a length (Method 3); reads it back with ReadText and Read.
    local procedure RoundTrip(Label: Text; Orig: Text; Mode: Integer; Method: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT WD Call Stack Log" temporary;
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
        Joined: Text;
        Lines: Integer;
        BytesPerChar: Integer;
    begin
        BytesPerChar := 1;
        if Mode = 2 then
            BytesPerChar := 2;
        Open(Log, OutStr, Mode);
        case Method of
            1:
                OutStr.WriteText(Orig);
            2:
                OutStr.Write(Orig);
            3:
                OutStr.WriteText(Orig, StrLen(Orig));
        end;
        Log.Insert();
        Log.CalcFields("Call Stack");
        Observer.Observe('length minus bytes', Format(Log."Call Stack".Length() - BytesPerChar * StrLen(Orig)));
        OpenIn(Log, InStr, Mode);
        InStr.ReadText(ReadBack);
        Observer.Observe('readtext equal', Format(ReadBack = Orig));
        Observer.Observe('readtext is first line', Format(ReadBack = FirstLine(Orig)));
        Observer.Observe('eos after readtext', Format(InStr.EOS()));
        OpenIn(Log, InStr, Mode);
        Clear(ReadBack);
        InStr.ReadText(ReadBack, StrLen(Orig));
        Observer.Observe('readtext len is first line', Format(ReadBack = FirstLine(Orig)));
        OpenIn(Log, InStr, Mode);
        Clear(ReadBack);
        InStr.Read(ReadBack);
        Observer.Observe('read equal', Format(ReadBack = Orig));
        OpenIn(Log, InStr, Mode);
        while not InStr.EOS() do begin
            InStr.ReadText(ReadBack);
            Lines += 1;
            Joined += ReadBack;
        end;
        Observer.Observe('loop lines', Format(Lines));
        Observer.Observe('loop joined is text without breaks', Format(Joined = NoBreaks(Orig)));
        Observer.Finish();
    end;

    local procedure Source(Src: Integer): Text
    begin
        case Src of
            1:
                exit(Collected());
            2:
                exit(LastError());
            3:
                exit(Mark());
        end;
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_DefaultEncoding_Collected_WriteText()
    begin
        RoundTrip('', Source(1), 0, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_DefaultEncoding_Collected_Write()
    begin
        RoundTrip('', Source(1), 0, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_DefaultEncoding_Collected_WriteTextLength()
    begin
        RoundTrip('', Source(1), 0, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_DefaultEncoding_LastError_WriteText()
    begin
        RoundTrip('', Source(2), 0, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_DefaultEncoding_LastError_Write()
    begin
        RoundTrip('', Source(2), 0, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_DefaultEncoding_LastError_WriteTextLength()
    begin
        RoundTrip('', Source(2), 0, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_DefaultEncoding_Mark_WriteText()
    begin
        RoundTrip('', Source(3), 0, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_DefaultEncoding_Mark_Write()
    begin
        RoundTrip('', Source(3), 0, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_DefaultEncoding_Mark_WriteTextLength()
    begin
        RoundTrip('', Source(3), 0, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF8_Collected_WriteText()
    begin
        RoundTrip('', Source(1), 1, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF8_Collected_Write()
    begin
        RoundTrip('', Source(1), 1, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF8_Collected_WriteTextLength()
    begin
        RoundTrip('', Source(1), 1, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF8_LastError_WriteText()
    begin
        RoundTrip('', Source(2), 1, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF8_LastError_Write()
    begin
        RoundTrip('', Source(2), 1, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF8_LastError_WriteTextLength()
    begin
        RoundTrip('', Source(2), 1, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF8_Mark_WriteText()
    begin
        RoundTrip('', Source(3), 1, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF8_Mark_Write()
    begin
        RoundTrip('', Source(3), 1, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF8_Mark_WriteTextLength()
    begin
        RoundTrip('', Source(3), 1, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF16_Collected_WriteText()
    begin
        RoundTrip('', Source(1), 2, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF16_Collected_Write()
    begin
        RoundTrip('', Source(1), 2, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF16_Collected_WriteTextLength()
    begin
        RoundTrip('', Source(1), 2, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF16_LastError_WriteText()
    begin
        RoundTrip('', Source(2), 2, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF16_LastError_Write()
    begin
        RoundTrip('', Source(2), 2, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF16_LastError_WriteTextLength()
    begin
        RoundTrip('', Source(2), 2, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF16_Mark_WriteText()
    begin
        RoundTrip('', Source(3), 2, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF16_Mark_Write()
    begin
        RoundTrip('', Source(3), 2, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_UTF16_Mark_WriteTextLength()
    begin
        RoundTrip('', Source(3), 2, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_Windows_Collected_WriteText()
    begin
        RoundTrip('', Source(1), 3, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_Windows_Collected_Write()
    begin
        RoundTrip('', Source(1), 3, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_Windows_Collected_WriteTextLength()
    begin
        RoundTrip('', Source(1), 3, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_Windows_LastError_WriteText()
    begin
        RoundTrip('', Source(2), 3, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_Windows_LastError_Write()
    begin
        RoundTrip('', Source(2), 3, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_Windows_LastError_WriteTextLength()
    begin
        RoundTrip('', Source(2), 3, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_Windows_Mark_WriteText()
    begin
        RoundTrip('', Source(3), 3, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_Windows_Mark_Write()
    begin
        RoundTrip('', Source(3), 3, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_Windows_Mark_WriteTextLength()
    begin
        RoundTrip('', Source(3), 3, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_MSDos_Collected_WriteText()
    begin
        RoundTrip('', Source(1), 4, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_MSDos_Collected_Write()
    begin
        RoundTrip('', Source(1), 4, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_MSDos_Collected_WriteTextLength()
    begin
        RoundTrip('', Source(1), 4, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_MSDos_LastError_WriteText()
    begin
        RoundTrip('', Source(2), 4, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_MSDos_LastError_Write()
    begin
        RoundTrip('', Source(2), 4, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_MSDos_LastError_WriteTextLength()
    begin
        RoundTrip('', Source(2), 4, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_MSDos_Mark_WriteText()
    begin
        RoundTrip('', Source(3), 4, 1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_MSDos_Mark_Write()
    begin
        RoundTrip('', Source(3), 4, 2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_MSDos_Mark_WriteTextLength()
    begin
        RoundTrip('', Source(3), 4, 3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_ReporterShapes()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT WD Call Stack Log" temporary;
        Entry: JsonObject;
        Arr: JsonArray;
        JsonText: Text;
        ReadBack: Text;
        OutStr: OutStream;
        InStr: InStream;
        Stack: Text;
    begin
        Stack := Collected();
        Entry.Add('Callstack', Stack);
        Arr.Add(Entry);
        Arr.WriteTo(JsonText);
        Observer.Observe('shape1 json empty', Format(JsonText = ''));
        Log."Call Stack".CreateOutStream(OutStr);
        OutStr.WriteText(JsonText);
        Log.Insert();
        Log.CalcFields("Call Stack");
        Observer.Observe('shape1 length minus strlen', Format(Log."Call Stack".Length() - StrLen(JsonText)));
        Log."Call Stack".CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Observer.Observe('shape1 readtext equal', Format(ReadBack = JsonText));
        Observer.Observe('shape1 readtext strlen minus', Format(StrLen(ReadBack) - StrLen(JsonText)));
        Clear(Log);
        Log."Entry No." := 2;
        Log."Call Stack".CreateOutStream(OutStr);
        OutStr.WriteText(Stack);
        Log.Insert();
        Log.CalcFields("Call Stack");
        Observer.Observe('shape2 length minus strlen', Format(Log."Call Stack".Length() - StrLen(Stack)));
        Log."Call Stack".CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Observer.Observe('shape2 readtext is first line', Format(ReadBack = FirstLine(Stack)));
        Clear(Entry);
        Entry.Add('Callstack', Stack);
        Clear(JsonText);
        Entry.WriteTo(JsonText);
        Observer.Observe('shape3 json empty', Format(JsonText = ''));
        Observer.Observe('shape3 json has key', Format(JsonText.Contains('"Callstack"')));
        Observer.Finish();
    end;
}
