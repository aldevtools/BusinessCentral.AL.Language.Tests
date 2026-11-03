// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own table 71937, report 71938
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Risky: Report.SaveAs with every ReportFormat; the whole file is one unit.
// Facts: for a ProcessingOnly report with a dataset and no layout: the result of SaveAs for Xml, Pdf, Html, Word, Excel (value, bytes written, GetLastErrorText start and code) and whether the data item triggers ran.
// BC versions: 29 (27 and 28 by CI)

table 71937 "LT P160 PoRow"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 71943 "LT P160 Po Log"
{
    SingleInstance = true;

    var
        Count: Integer;

    procedure Hit()
    begin
        Count += 1;
    end;

    procedure Take(): Integer
    var
        Result: Integer;
    begin
        Result := Count;
        Count := 0;
        exit(Result);
    end;
}

report 71938 "LT P160 Po Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Rows; "LT P160 PoRow")
        {
            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT P160 Po Log";
            begin
                Log.Hit();
            end;
        }
    }
}

codeunit 71944 "LT P160 Po Formats"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySave(Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob"; var Ok: Boolean)
    var
        Rep: Report "LT P160 Po Report";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Ok := Rep.SaveAs('', Fmt, OutS);
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; Tag: Text; Fmt: ReportFormat)
    var
        TempBlob: Codeunit "Temp Blob";
        Log: Codeunit "LT P160 Po Log";
        Ok: Boolean;
        Ran: Boolean;
    begin
        Log.Take();
        ClearLastError();
        Ran := TrySave(Fmt, TempBlob, Ok);
        Observer.Observe(Tag + ' raised nothing', Format(Ran));
        Observer.Observe(Tag + ' result', Format(Ok));
        Observer.Observe(Tag + ' bytes written', Format(TempBlob.Length()));
        Observer.Observe(Tag + ' row triggers', Format(Log.Take()));
        Observer.Observe(Tag + ' last error', CopyStr(GetLastErrorText(), 1, 200));
        Observer.Observe(Tag + ' last error code', GetLastErrorCode());
        ClearLastError();
    end;

    local procedure Seed()
    var
        Row: Record "LT P160 PoRow";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
    end;

    [Test]
    procedure Xml_ProcessingOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        One(Observer, 'Xml', ReportFormat::Xml);
        Observer.Expect('Xml raised nothing', 'Yes');
        Observer.Expect('Xml result', 'No');
        Observer.Expect('Xml bytes written', '0');
        Observer.Expect('Xml row triggers', '0');
        Observer.Expect('Xml last error', 'Report 71938 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('Xml last error code', 'ReportProcessingOnly');
        Observer.Verify();
    end;

    [Test]
    procedure Pdf_ProcessingOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        One(Observer, 'Pdf', ReportFormat::Pdf);
        Observer.Expect('Pdf raised nothing', 'Yes');
        Observer.Expect('Pdf result', 'No');
        Observer.Expect('Pdf bytes written', '0');
        Observer.Expect('Pdf row triggers', '0');
        Observer.Expect('Pdf last error', 'Report 71938 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('Pdf last error code', 'ReportProcessingOnly');
        Observer.Verify();
    end;

    [Test]
    procedure Html_ProcessingOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        One(Observer, 'Html', ReportFormat::Html);
        Observer.Expect('Html raised nothing', 'Yes');
        Observer.Expect('Html result', 'No');
        Observer.Expect('Html bytes written', '0');
        Observer.Expect('Html row triggers', '0');
        Observer.Expect('Html last error', 'Report 71938 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('Html last error code', 'ReportProcessingOnly');
        Observer.Verify();
    end;

    [Test]
    procedure Word_ProcessingOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        One(Observer, 'Word', ReportFormat::Word);
        Observer.Expect('Word raised nothing', 'Yes');
        Observer.Expect('Word result', 'No');
        Observer.Expect('Word bytes written', '0');
        Observer.Expect('Word row triggers', '0');
        Observer.Expect('Word last error', 'Report 71938 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('Word last error code', 'ReportProcessingOnly');
        Observer.Verify();
    end;

    [Test]
    procedure Excel_ProcessingOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        One(Observer, 'Excel', ReportFormat::Excel);
        Observer.Expect('Excel raised nothing', 'Yes');
        Observer.Expect('Excel result', 'No');
        Observer.Expect('Excel bytes written', '0');
        Observer.Expect('Excel row triggers', '0');
        Observer.Expect('Excel last error', 'Report 71938 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('Excel last error code', 'ReportProcessingOnly');
        Observer.Verify();
    end;
}
