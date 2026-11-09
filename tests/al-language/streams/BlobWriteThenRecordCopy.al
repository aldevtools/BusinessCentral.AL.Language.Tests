// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Blob (60008), Probe Observer (69160)
// BC versions: 27.5+
//
// Probe (al-runner issue 7360): a Blob written in memory (CreateOutStream + WriteText) and then copied
// by record assignment. Each test writes the Blob, copies the record (":=", or a by-value parameter
// and back through a var parameter), and observes on the copy: HasValue before CalcFields, the text
// and Length after CalcFields, and what Modify (or Insert, for a row that was never stored) of the
// copy stores (read back with a fresh Get and CalcFields). Stored and never-stored rows, with and
// without Clear before the write.
// Related pin: types/ProbeTypeFormsAndFilters.al (FormatRecord_AssignmentCopiesBlobBytes).

// local object: a codeunit that holds a record in a global variable, so the test can pass a record by value and get it back through a var parameter
codeunit 96501 "LT Blob Copy Holder"
{
    var
        GlobalRec: Record "ALT Blob";

    procedure SetRec(Rec: Record "ALT Blob")
    begin
        GlobalRec := Rec;
    end;

    procedure GetRec(var Rec: Record "ALT Blob")
    begin
        Rec := GlobalRec;
    end;
}

codeunit 96500 "LT Blob Write Then Copy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Stored_WriteThenAssign()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        StoreRow(Row, 'S1');
        WriteBlob(Row, 'abc', false);
        Copy1 := Row;
        ObserveCopy(Observer, 'copy', Copy1, true);
        Observer.Finish();
    end;

    [Test]
    procedure Stored_ClearWriteThenAssign()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        StoreRow(Row, 'S2');
        WriteBlob(Row, 'abc', true);
        Copy1 := Row;
        ObserveCopy(Observer, 'copy', Copy1, true);
        Observer.Finish();
    end;

    [Test]
    procedure Stored_WriteThenParameterRoundTrip()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Holder: Codeunit "LT Blob Copy Holder";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        StoreRow(Row, 'S3');
        WriteBlob(Row, 'abc', false);
        Holder.SetRec(Row);
        Holder.GetRec(Copy1);
        ObserveCopy(Observer, 'copy', Copy1, true);
        Observer.Finish();
    end;

    [Test]
    procedure Stored_ClearWriteThenParameterRoundTrip()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Holder: Codeunit "LT Blob Copy Holder";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        StoreRow(Row, 'S4');
        WriteBlob(Row, 'abc', true);
        Holder.SetRec(Row);
        Holder.GetRec(Copy1);
        ObserveCopy(Observer, 'copy', Copy1, true);
        Observer.Finish();
    end;

    // The form from the issue: copy first, write on the copy, then pass the copy through the holder.
    [Test]
    procedure Stored_AssignThenWriteCopyThenParameterRoundTrip()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Copy2: Record "ALT Blob";
        Holder: Codeunit "LT Blob Copy Holder";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        StoreRow(Row, 'S5');
        Copy1 := Row;
        WriteBlob(Copy1, 'abc', true);
        Holder.SetRec(Copy1);
        Holder.GetRec(Copy2);
        ObserveCopy(Observer, 'copy', Copy2, true);
        Observer.Finish();
    end;

    [Test]
    procedure Stored_AssignThenWriteCopyNoClearThenParameterRoundTrip()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Copy2: Record "ALT Blob";
        Holder: Codeunit "LT Blob Copy Holder";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        StoreRow(Row, 'S6');
        Copy1 := Row;
        WriteBlob(Copy1, 'abc', false);
        Holder.SetRec(Copy1);
        Holder.GetRec(Copy2);
        ObserveCopy(Observer, 'copy', Copy2, true);
        Observer.Finish();
    end;

    [Test]
    procedure Unstored_WriteThenAssign()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        Row.Init();
        Row.Code := 'U1';
        WriteBlob(Row, 'abc', false);
        Copy1 := Row;
        ObserveCopy(Observer, 'copy', Copy1, false);
        Observer.Finish();
    end;

    [Test]
    procedure Unstored_ClearWriteThenAssign()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        Row.Init();
        Row.Code := 'U2';
        WriteBlob(Row, 'abc', true);
        Copy1 := Row;
        ObserveCopy(Observer, 'copy', Copy1, false);
        Observer.Finish();
    end;

    [Test]
    procedure Unstored_WriteThenParameterRoundTrip()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Holder: Codeunit "LT Blob Copy Holder";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        Row.Init();
        Row.Code := 'U3';
        WriteBlob(Row, 'abc', false);
        Holder.SetRec(Row);
        Holder.GetRec(Copy1);
        ObserveCopy(Observer, 'copy', Copy1, false);
        Observer.Finish();
    end;

    [Test]
    procedure Unstored_ClearWriteThenParameterRoundTrip()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Holder: Codeunit "LT Blob Copy Holder";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        Row.Init();
        Row.Code := 'U4';
        WriteBlob(Row, 'abc', true);
        Holder.SetRec(Row);
        Holder.GetRec(Copy1);
        ObserveCopy(Observer, 'copy', Copy1, false);
        Observer.Finish();
    end;

    [Test]
    procedure Unstored_AssignThenWriteCopyThenParameterRoundTrip()
    var
        Row: Record "ALT Blob";
        Copy1: Record "ALT Blob";
        Copy2: Record "ALT Blob";
        Holder: Codeunit "LT Blob Copy Holder";
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup.Initialize();
        Row.Init();
        Row.Code := 'U5';
        Copy1 := Row;
        WriteBlob(Copy1, 'abc', true);
        Holder.SetRec(Copy1);
        Holder.GetRec(Copy2);
        ObserveCopy(Observer, 'copy', Copy2, false);
        Observer.Finish();
    end;

    local procedure StoreRow(var Row: Record "ALT Blob"; RowCode: Code[20])
    begin
        Row.Init();
        Row.Code := RowCode;
        Row.Insert();
    end;

    local procedure WriteBlob(var Row: Record "ALT Blob"; Value: Text; ClearFirst: Boolean)
    var
        Out: OutStream;
    begin
        if ClearFirst then
            Clear(Row.Data);
        Row.Data.CreateOutStream(Out, TextEncoding::UTF8);
        Out.WriteText(Value);
    end;

    local procedure ReadBlob(var Row: Record "ALT Blob"): Text
    var
        InS: InStream;
        Txt: Text;
    begin
        Row.Data.CreateInStream(InS, TextEncoding::UTF8);
        InS.ReadText(Txt);
        exit(Txt);
    end;

    // Observes the copy before and after CalcFields, then stores it (Modify, or Insert for a row that was never stored) and reads the row fresh.
    local procedure ObserveCopy(var Observer: Codeunit "Probe Observer"; Prefix: Text; var Copy1: Record "ALT Blob"; Stored: Boolean)
    var
        Fresh: Record "ALT Blob";
    begin
        Observer.Observe(Prefix + 'HasValueBefore', Format(Copy1.Data.HasValue()));
        Copy1.CalcFields(Data);
        Observer.Observe(Prefix + 'HasValueAfter', Format(Copy1.Data.HasValue()));
        Observer.Observe(Prefix + 'LengthAfter', Format(Copy1.Data.Length()));
        Observer.Observe(Prefix + 'TextAfter', ReadBlob(Copy1));
        if Stored then
            Copy1.Modify()
        else
            Copy1.Insert();
        Fresh.Get(Copy1.Code);
        Observer.Observe(Prefix + 'FreshHasValue', Format(Fresh.Data.HasValue()));
        Fresh.CalcFields(Data);
        Observer.Observe(Prefix + 'FreshLength', Format(Fresh.Data.Length()));
        Observer.Observe(Prefix + 'FreshText', ReadBlob(Fresh));
    end;
}
