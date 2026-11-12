// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope (Cloud-compatible)
// Fixtures used: XApp A report, XApp B owner, XApp C consumer
// BC versions: 27.5+

codeunit 50898 "RPT Dependency Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Report_SaveAs_DependencyExtension_UsesOwnedDataItem()
    // CLAIM: A dependent extension sees the introducing extension's data item in triggers and in the XML dataset.
    var
        Trace: Codeunit "RPT Dependency Trace";
        Data: Codeunit "Temp Blob";
        DataOut: OutStream;
        DataIn: InStream;
        Line: Text;
        FoundColumn: Boolean;
    begin
        Initialize();
        Data.CreateOutStream(DataOut);
        if not Report.SaveAs(Report::"RPT Dependency Base", '', ReportFormat::Xml, DataOut) then
            Error('Report.SaveAs failed: %1', GetLastErrorText());
        if Trace.Read() <> 'owner=2|dependent=2|before|footer|after=2|' then
            Error('Cross report observation: %1', Trace.Read());
        Data.CreateInStream(DataIn, TextEncoding::UTF8);
        while not DataIn.EOS() do begin
            DataIn.ReadText(Line);
            if StrPos(Line, '<Column name="DependentNo">2</Column>') > 0 then
                FoundColumn := true;
        end;
        if not FoundColumn then
            Error('The dependent column did not contain the owner row value.');
    end;

    local procedure Initialize()
    var
        Trace: Codeunit "RPT Dependency Trace";
    begin
        Trace.Reset();
    end;
}
