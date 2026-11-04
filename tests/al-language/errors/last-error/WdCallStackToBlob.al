// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 90740-90742
// Probe: written against al-runner issue 6310; every value asserted below is what the BC service tier produced.
// Facts: the call stack text of an error (GetLastErrorCallStack, and ErrorInfo.Callstack() of a collected error) written to a Blob with TextEncoding::Windows
//        and read back: whether the write raises, whether the text round-trips, whether it is empty. The call stack text itself is not asserted (it names apps and lines).
// BC versions: 27, 28, 29

table 90740 "LT WD Call Stack Log"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Call Stack"; Blob) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

codeunit 90741 "LT WD Call Stack Worker"
{
    [TryFunction]
    procedure Fail()
    begin
        Error('boom');
    end;
}

codeunit 90742 "LT WD Call Stack To Blob"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure RoundTrip(CallStack: Text; Encoding: TextEncoding; var Log: Record "LT WD Call Stack Log" temporary): Text
    var
        OutStr: OutStream;
        InStr: InStream;
        ReadBack: Text;
    begin
        Log."Entry No." += 1;
        Log."Call Stack".CreateOutStream(OutStr, Encoding);
        OutStr.Write(CallStack);
        Log.Insert();
        Log.CalcFields("Call Stack");
        Log."Call Stack".CreateInStream(InStr, Encoding);
        InStr.Read(ReadBack);
        exit(ReadBack);
    end;

    [Test]
    procedure WD_CallStack_LastError_ToWindowsBlob()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT WD Call Stack Log" temporary;
        Worker: Codeunit "LT WD Call Stack Worker";
        CallStack: Text;
        ReadBack: Text;
    begin
        Observer.Observe('try function result', Format(Worker.Fail()));
        CallStack := GetLastErrorCallStack();
        Observer.Observe('call stack empty', Format(CallStack = ''));
        ReadBack := RoundTrip(CallStack, TextEncoding::Windows, Log);
        Observer.Observe('round trip equal', Format(ReadBack = CallStack));
        Observer.Observe('read back empty', Format(ReadBack = ''));
        Observer.Expect('try function result', 'No');
        Observer.Expect('call stack empty', 'No');
        Observer.Expect('round trip equal', 'Yes');
        Observer.Expect('read back empty', 'No');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure WD_CallStack_Collected_ToWindowsBlob()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT WD Call Stack Log" temporary;
        ErrInfo: ErrorInfo;
        Collected: List of [ErrorInfo];
        CallStack: Text;
        ReadBack: Text;
    begin
        ErrInfo := ErrorInfo.Create('boom');
        ErrInfo.Collectible := true;
        Error(ErrInfo);
        Collected := GetCollectedErrors(true);
        Observer.Observe('collected count', Format(Collected.Count()));
        foreach ErrInfo in Collected do begin
            CallStack := ErrInfo.Callstack();
            Observer.Observe('call stack empty', Format(CallStack = ''));
            ReadBack := RoundTrip(CallStack, TextEncoding::Windows, Log);
            Observer.Observe('windows round trip equal', Format(ReadBack = CallStack));
            ReadBack := RoundTrip(CallStack, TextEncoding::UTF8, Log);
            Observer.Observe('utf8 round trip equal', Format(ReadBack = CallStack));
        end;
        Observer.Expect('collected count', '1');
        Observer.Expect('call stack empty', 'No');
        Observer.Expect('windows round trip equal', 'Yes');
        Observer.Expect('utf8 round trip equal', 'Yes');
        Observer.Verify();
    end;
}
