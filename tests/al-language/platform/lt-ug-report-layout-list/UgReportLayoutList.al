// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160); report 69083 "Probe RL Report" (record/TestEventSubscriptionColumnsReportLayoutListContracts.al: layouts Rdlc and Word, and
//   ExtWord from reportextension 69084); own reports 90368 and 90369, codeunit 90370
// Probe: outside issue 6191 (a ForNAV layout selection reads column 14 of the platform table "Report Layout List" (2000000234) of a built-in layout while the app
//   installs). Every field of the row is read through a RecordRef (number, name, type, value; a Guid, a date/time and a Media/Blob value is shown as blank / set /
//   this app because the values themselves are environment data) for a report with an RDLC layout, one with a Word layout and one with no layout.
// Observed on the BC 29.0 SaaS sandbox; the CI legs 27.5 and 28.5 decide the versions.
// BC versions: 27 - 29

report 90368 "LT UG Report No Layout"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Num; Number) { }
        }
    }
}

report 90369 "LT UG Report Processing Only"
{
    UsageCategory = None;
    ProcessingOnly = true;
}

codeunit 90370 "LT UG Report Layout List"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(var FRef: FieldRef): Text
    var
        Info: ModuleInfo;
        Id: Guid;
    begin
        if FRef.Class = FieldClass::FlowField then
            FRef.CalcField();
        case FRef.Type of
            FieldType::Guid:
                begin
                    Id := FRef.Value;
                    NavApp.GetCurrentModuleInfo(Info);
                    if IsNullGuid(Id) then
                        exit('null guid');
                    if Id = Info.Id() then
                        exit('this app');
                    exit('other guid');
                end;
            FieldType::DateTime, FieldType::Date, FieldType::Time:
                if Format(FRef.Value) = '' then
                    exit('blank')
                else
                    exit('set');
            FieldType::Blob, FieldType::Media, FieldType::MediaSet:
                exit('not shown');
        end;
        exit('[' + Format(FRef.Value) + ']');
    end;

    // Observes the row column by column, in field index order, under the name "<Label> <field number> <field name>".
    local procedure Dump(var Observer: Codeunit "Probe Observer"; Label: Text; ReportId: Integer; LayoutName: Text)
    var
        RecRef: RecordRef;
        FRef: FieldRef;
        I: Integer;
    begin
        RecRef.Open(2000000234);
        RecRef.Field(1).SetRange(ReportId);
        RecRef.Field(2).SetRange(LayoutName);
        if not RecRef.FindFirst() then begin
            Observer.Observe(Label, 'no row, rows in report=' + CountOfReport(ReportId));
            exit;
        end;
        for I := 1 to RecRef.FieldCount() do begin
            FRef := RecRef.FieldIndex(I);
            Observer.Observe(Label + ' ' + Format(FRef.Number) + ' ' + FRef.Name, Format(FRef.Type) + ' ' + Show(FRef));
        end;
    end;

    local procedure CountOfReport(ReportId: Integer): Text
    var
        Layouts: Record "Report Layout List";
    begin
        Layouts.SetRange("Report ID", ReportId);
        exit(Format(Layouts.Count()));
    end;

    [Test]
    procedure ReportLayoutList_AllColumns_RdlcLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'rdlc', Report::"Probe RL Report", 'Rdlc');
        Observer.Expect('rdlc 1 Report ID', 'Integer [69083]');
        Observer.Expect('rdlc 2 Name', 'Text [Rdlc]');
        Observer.Expect('rdlc 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('rdlc 3 Caption', 'Text [RL rdlc]');
        Observer.Expect('rdlc 4 CaptionML', 'Text []');
        Observer.Expect('rdlc 6 Layout', 'Media not shown');
        Observer.Expect('rdlc 7 Layout Format', 'Option [RDLC]');
        Observer.Expect('rdlc 8 Custom Type', 'GUID null guid');
        Observer.Expect('rdlc 9 MIME Type', 'Text []');
        Observer.Expect('rdlc 10 Description', 'Text [rdlc summary]');
        Observer.Expect('rdlc 11 Application ID', 'GUID this app');
        Observer.Expect('rdlc 12 Report Name', 'Text [Probe RL Report]');
        Observer.Expect('rdlc 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('rdlc 14 User Defined', 'Boolean [No]');
        Observer.Expect('rdlc 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('rdlc 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('rdlc 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
        Observer.Expect('rdlc 18 Layout Status', 'Option [Approved]');
        Observer.Expect('rdlc 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('rdlc 20 HeaderFooterPart', 'Text []');
        Observer.Expect('rdlc 21 ThemePart', 'Text []');
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_AllColumns_WordLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'word', Report::"Probe RL Report", 'Word');
        Observer.Expect('word 1 Report ID', 'Integer [69083]');
        Observer.Expect('word 2 Name', 'Text [Word]');
        Observer.Expect('word 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('word 3 Caption', 'Text [RL word]');
        Observer.Expect('word 4 CaptionML', 'Text []');
        Observer.Expect('word 6 Layout', 'Media not shown');
        Observer.Expect('word 7 Layout Format', 'Option [Word]');
        Observer.Expect('word 8 Custom Type', 'GUID null guid');
        Observer.Expect('word 9 MIME Type', 'Text []');
        Observer.Expect('word 10 Description', 'Text [Word]');
        Observer.Expect('word 11 Application ID', 'GUID this app');
        Observer.Expect('word 12 Report Name', 'Text [Probe RL Report]');
        Observer.Expect('word 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('word 14 User Defined', 'Boolean [No]');
        Observer.Expect('word 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('word 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('word 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
        Observer.Expect('word 18 Layout Status', 'Option [Approved]');
        Observer.Expect('word 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('word 20 HeaderFooterPart', 'Text []');
        Observer.Expect('word 21 ThemePart', 'Text []');
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_ReportsWithoutLayout_AndMissingName()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'no layout report', Report::"LT UG Report No Layout", 'Rdlc');
        Observer.Observe('rows of the report without layout', CountOfReport(Report::"LT UG Report No Layout"));
        Observer.Observe('rows of the processing only report', CountOfReport(Report::"LT UG Report Processing Only"));
        Dump(Observer, 'missing name', Report::"Probe RL Report", 'NoSuchLayout');
        Observer.Expect('no layout report', 'no row, rows in report=0');
        Observer.Expect('rows of the report without layout', '0');
        Observer.Expect('rows of the processing only report', '0');
        Observer.Expect('missing name', 'no row, rows in report=3');
        Observer.Verify();
    end;
}
