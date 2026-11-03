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

    // Writes Orig with WriteText (Method 1) or Write (Method 2), reads it back with ReadText and Read.
    local procedure RoundTrip(var Observer: Codeunit "Probe Observer"; Label: Text; Orig: Text; Mode: Integer; Method: Integer)
    var
        Log: Record "LT WD Call Stack Log" temporary;
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
        Joined: Text;
        Lines: Integer;
        Prefix: Text;
    begin
        Prefix := Label + ' m' + Format(Mode) + ' w' + Format(Method) + ' ';
        Open(Log, OutStr, Mode);
        if Method = 1 then
            OutStr.WriteText(Orig)
        else
            OutStr.Write(Orig);
        Log.Insert();
        Log.CalcFields("Call Stack");
        Observer.Observe(Prefix + 'length minus strlen', Format(Log."Call Stack".Length() - StrLen(Orig)));
        OpenIn(Log, InStr, Mode);
        InStr.ReadText(ReadBack);
        Observer.Observe(Prefix + 'readtext equal', Format(ReadBack = Orig));
        Observer.Observe(Prefix + 'readtext strlen minus', Format(StrLen(ReadBack) - StrLen(Orig)));
        Observer.Observe(Prefix + 'eos after readtext', Format(InStr.EOS()));
        OpenIn(Log, InStr, Mode);
        Clear(ReadBack);
        InStr.Read(ReadBack);
        Observer.Observe(Prefix + 'read equal', Format(ReadBack = Orig));
        Observer.Observe(Prefix + 'read strlen minus', Format(StrLen(ReadBack) - StrLen(Orig)));
        OpenIn(Log, InStr, Mode);
        while not InStr.EOS() do begin
            InStr.ReadText(ReadBack);
            Lines += 1;
            Joined += ReadBack;
        end;
        Observer.Observe(Prefix + 'loop lines', Format(Lines));
        Observer.Observe(Prefix + 'loop joined strlen minus', Format(StrLen(Joined) - StrLen(Orig)));
    end;

    local procedure AllShapes(Mode: Integer)
    var
        Observer: Codeunit "Probe Observer";
        Stack: Text;
        Method: Integer;
    begin
        Stack := Collected();
        for Method := 1 to 2 do
            RoundTrip(Observer, 'collected', Stack, Mode, Method);
        Stack := LastError();
        for Method := 1 to 2 do
            RoundTrip(Observer, 'lasterror', Stack, Mode, Method);
        for Method := 1 to 2 do
            RoundTrip(Observer, 'mark', Mark(), Mode, Method);
        Observer.Finish();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_WriteText_DefaultEncoding()
    begin
        AllShapes(0);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_WriteText_UTF8()
    begin
        AllShapes(1);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_WriteText_UTF16()
    begin
        AllShapes(2);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_WriteText_Windows()
    begin
        AllShapes(3);
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_WriteText_MSDos()
    begin
        AllShapes(4);
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
        Observer.Observe('shape2 readtext equal', Format(ReadBack = Stack));
        Clear(Entry);
        Entry.Add('Callstack', Stack);
        Clear(JsonText);
        Entry.WriteTo(JsonText);
        Observer.Observe('shape3 json empty', Format(JsonText = ''));
        Observer.Observe('shape3 json strlen minus stack', Format(StrLen(JsonText) - StrLen(Stack)));
        Observer.Finish();
    end;
}
