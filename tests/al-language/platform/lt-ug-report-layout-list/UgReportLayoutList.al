// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160); report 69083 "Probe RL Report" (record/TestEventSubscriptionColumnsReportLayoutListContracts.al: layouts Rdlc and Word, and
//   ExtWord from reportextension 69084); own reports 90368 and 90369, codeunit 90370
// Probe: outside issue 6191 (a ForNAV layout selection reads column 14 of the platform table "Report Layout List" (2000000234) of a built-in layout while the app
//   installs). Every field of the row is read through a RecordRef (number, name, type, value; a Guid, a date/time and a Media/Blob value is shown as blank / set /
//   this app because the values themselves are environment data) for a report with an RDLC layout, one with a Word layout and one with no layout.
// Observed on the BC 29.0 SaaS sandbox and the CI legs: BC 27 has the columns 1 - 17, BC 28 adds 18 (Layout Status), BC 29 adds 19 - 21 (Layout Subtype, HeaderFooterPart, ThemePart).
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

// Writer Y17 (gap cycle 1 G9): a report whose Caption differs from its name, with one RDLC layout (the compiler writes the layout file at build, as for Probe RL Report;
// it is not committed).
report 91873 "LT Y17 RL Captioned"
{
    UsageCategory = None;
    Caption = 'LT Caption Differs';
    DefaultRenderingLayout = Rdl;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(EntryNo; Number) { }
            column(Description; Desc) { }
            column(Amount; Amt) { }
        }
    }

    rendering
    {
        layout(Rdl)
        {
            Type = RDLC;
            LayoutFile = './LtY17RlCaptioned.rdl';
            Caption = 'Y17 rdl';
        }
    }

    var
        Desc: Text;
        Amt: Decimal;
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
#if BC28PLUS
        Observer.Expect('rdlc 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('rdlc 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('rdlc 20 HeaderFooterPart', 'Text []');
        Observer.Expect('rdlc 21 ThemePart', 'Text []');
#endif
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
#if BC28PLUS
        Observer.Expect('word 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('word 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('word 20 HeaderFooterPart', 'Text []');
        Observer.Expect('word 21 ThemePart', 'Text []');
#endif
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

    // Writer Y17 (gap cycle 1 G9): column 12 "Report Name" and column 3 Caption of the layout row of a report whose Caption differs from its name.
    [Test]
    procedure Y17_ReportLayoutList_ReportName_WithCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'captioned', Report::"LT Y17 RL Captioned", 'Rdl');
        Observer.Expect('captioned 1 Report ID', 'Integer [91873]');
        Observer.Expect('captioned 2 Name', 'Text [Rdl]');
        Observer.Expect('captioned 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('captioned 3 Caption', 'Text [Y17 rdl]');
        Observer.Expect('captioned 4 CaptionML', 'Text []');
        Observer.Expect('captioned 6 Layout', 'Media not shown');
        Observer.Expect('captioned 7 Layout Format', 'Option [RDLC]');
        Observer.Expect('captioned 8 Custom Type', 'GUID null guid');
        Observer.Expect('captioned 9 MIME Type', 'Text []');
        Observer.Expect('captioned 10 Description', 'Text [Rdl]');
        Observer.Expect('captioned 11 Application ID', 'GUID this app');
        Observer.Expect('captioned 12 Report Name', 'Text [LT Caption Differs]');
        Observer.Expect('captioned 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('captioned 14 User Defined', 'Boolean [No]');
        Observer.Expect('captioned 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('captioned 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('captioned 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('captioned 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('captioned 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('captioned 20 HeaderFooterPart', 'Text []');
        Observer.Expect('captioned 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;

    // Column 5 "Runtime Package ID" compared with AllObj of the report and NAV App Installed App of this app (Published Application is
    // Scope OnPrem); two reads give the same value.
    [Test]
    procedure Y17_ReportLayoutList_RuntimePackageId_Matches()
    var
        Layouts: Record "Report Layout List";
        Again: Record "Report Layout List";
        AllObj: Record AllObj;
        Installed: Record "NAV App Installed App";
        Info: ModuleInfo;
        Observer: Codeunit "Probe Observer";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Layouts.SetRange("Report ID", Report::"Probe RL Report");
        Layouts.SetRange(Name, 'Rdlc');
        Layouts.FindFirst();
        Again.SetRange("Report ID", Report::"Probe RL Report");
        Again.SetRange(Name, 'Word');
        Again.FindFirst();
        AllObj.Get(AllObj."Object Type"::Report, Report::"Probe RL Report");
        Installed.Get(Info.Id());
        Observer.Observe('= AllObj App Runtime Package ID', Format(Layouts."Runtime Package ID" = AllObj."App Runtime Package ID"));
        Observer.Observe('= AllObj App Package ID', Format(Layouts."Runtime Package ID" = AllObj."App Package ID"));
        Observer.Observe('= Installed App Package ID', Format(Layouts."Runtime Package ID" = Installed."Package ID"));
        Observer.Observe('= other layout of the report', Format(Layouts."Runtime Package ID" = Again."Runtime Package ID"));
        Again.SetRange(Name, 'Rdlc');
        Again.FindFirst();
        Observer.Observe('two reads equal', Format(Layouts."Runtime Package ID" = Again."Runtime Package ID"));
        Observer.Expect('= AllObj App Runtime Package ID', 'Yes');
        Observer.Expect('= AllObj App Package ID', 'Yes');
        Observer.Expect('= Installed App Package ID', 'Yes');
        Observer.Expect('= other layout of the report', 'Yes');
        Observer.Expect('two reads equal', 'Yes');
        Observer.Verify();
    end;

    // A user-defined layout (a Tenant Report Layout row inserted for the report): its Report Layout List row, every column.
    [Test]
    procedure Y17_ReportLayoutList_UserDefinedRow()
    var
        Layout: Record "Tenant Report Layout";
        Observer: Codeunit "Probe Observer";
        InS: InStream;
    begin
        Layout.SetRange("Report ID", Report::"LT Y17 RL Captioned");
        Layout.DeleteAll();
        Layout.Reset();
        Layout.Init();
        Layout."Report ID" := Report::"LT Y17 RL Captioned";
        Layout.Name := 'LT Y17 User';
        Layout."Layout Format" := Layout."Layout Format"::RDLC;
        Layout.Description := 'Y17 user layout';
        Report.RdlcLayout(Report::"LT Y17 RL Captioned", InS);
        Layout.Layout.ImportStream(InS, 'Y17 user layout');
        Observer.Observe('insert', Format(Layout.Insert()));
        Observer.Observe('rows in report', CountOfReport(Report::"LT Y17 RL Captioned"));
        Dump(Observer, 'user', Report::"LT Y17 RL Captioned", 'LT Y17 User');
        Layout.SetRange("Report ID", Report::"LT Y17 RL Captioned");
        Layout.DeleteAll();
        Observer.Expect('insert', 'Yes');
        Observer.Expect('rows in report', '2');
        Observer.Expect('user 1 Report ID', 'Integer [91873]');
        Observer.Expect('user 2 Name', 'Text [LT Y17 User]');
        Observer.Expect('user 5 Runtime Package ID', 'GUID null guid');
        Observer.Expect('user 3 Caption', 'Text [LT Y17 User]');
        Observer.Expect('user 4 CaptionML', 'Text []');
        Observer.Expect('user 6 Layout', 'Media not shown');
        Observer.Expect('user 7 Layout Format', 'Option [RDLC]');
        Observer.Expect('user 8 Custom Type', 'GUID null guid');
        Observer.Expect('user 9 MIME Type', 'Text []');
        Observer.Expect('user 10 Description', 'Text [Y17 user layout]');
        Observer.Expect('user 11 Application ID', 'GUID null guid');
        Observer.Expect('user 12 Report Name', 'Text [LT Caption Differs]');
        Observer.Expect('user 13 Layout Publisher', 'Text []');
        Observer.Expect('user 14 User Defined', 'Boolean [Yes]');
        Observer.Expect('user 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('user 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('user 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('user 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('user 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('user 20 HeaderFooterPart', 'Text []');
        Observer.Expect('user 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;
}
