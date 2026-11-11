// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-layout-list-table
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); platform tables Tenant Report Layout, Tenant Report Layout Selection and Report Layout List;
//   Base Application report 1306 "Standard Sales - Invoice" (a report of another app); own report 96760 and codeunit 96765.
// Probe: from the trial report al-runner 6924 (39 tests read the Report Layout List row of a user-defined layout whose Name is a GUID text, of a
//   report of the reporter's app, by a filter on Report ID). UserDefinedWordExcelLayoutRows.al measures a Word and an Excel row with a plain name
//   and a blank App ID; this file adds the cells it does not reach: a GUID name, the App ID and Company Name of the Tenant Report Layout row,
//   every column through a RecordRef (including Layout Status and the BC 29 columns), the declared and user-defined rows read by a filter on
//   Report ID (order and count), filters on Application ID and User Defined, a report of another app, a report id that names no report, and a
//   Tenant Report Layout Selection row that picks the user-defined layout.
// Area: Report Layout List rows of user-defined layouts (RDLC, Word, Excel) next to the RDLC, Word and Excel layouts the report declares.
// BC versions: 27.5, 28.5, 29.0. The expected values are what the corpus CI legs returned (BC28PLUS / BC29PLUS where they differ).

report 96760 "LT UDA Rpt"
{
    UsageCategory = None;
    Caption = 'LT UDA Caption';
    DefaultRenderingLayout = LtUdaWord;

    dataset
    {
        dataitem(AmRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 .. 3));
            column(AmNum; Number)
            {
            }
            column(AmReq; ReqText)
            {
            }
            column(AmMark; 'AMMARK')
            {
            }
        }
    }

    rendering
    {
        layout(LtUdaRdlc)
        {
            Type = RDLC;
            LayoutFile = './reports/layouts-saveas/LtUdaRdlc.rdlc';
            Caption = 'UDA rdlc';
        }
        layout(LtUdaWord)
        {
            Type = Word;
            LayoutFile = './reports/layouts-saveas/LtUdaWord.docx';
            Caption = 'UDA word';
        }
        layout(LtUdaExcel)
        {
            Type = Excel;
            LayoutFile = './reports/layouts-saveas/LtUdaExcel.xlsx';
            Caption = 'UDA excel';
        }
    }

    var
        ReqText: Text[30];
}

codeunit 96765 "LT UDA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GuidNameTxt: Label '{6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}', Locked = true;
        OtherAppTxt: Label '{0A1B2C3D-4E5F-4061-8273-94A5B6C7D8E9}', Locked = true;

    local procedure Show(var FRef: FieldRef): Text
    var
        Info: ModuleInfo;
        Id: Guid;
        Other: Guid;
    begin
        case FRef.Type of
            FieldType::Guid:
                begin
                    Id := FRef.Value;
                    NavApp.GetCurrentModuleInfo(Info);
                    Evaluate(Other, OtherAppTxt);
                    if IsNullGuid(Id) then
                        exit('null');
                    if Id = Info.Id() then
                        exit('this app');
                    if Id = Other then
                        exit('other app id');
                    exit('other guid');
                end;
            FieldType::Blob, FieldType::Media, FieldType::MediaSet:
                exit('not shown');
        end;
        exit(Format(FRef.Value));
    end;

    // Every column of the Report Layout List row of the report and name, as "number=value|...".
    local procedure Row(ReportId: Integer; LayoutName: Text): Text
    var
        RecRef: RecordRef;
        FRef: FieldRef;
        I: Integer;
        Result: Text;
    begin
        RecRef.Open(2000000234);
        RecRef.Field(1).SetRange(ReportId);
        RecRef.Field(2).SetRange(LayoutName);
        if not RecRef.FindFirst() then
            exit('no row');
        for I := 1 to RecRef.FieldCount() do begin
            FRef := RecRef.FieldIndex(I);
            if not (FRef.Number in [1, 2]) then
                Result += Format(FRef.Number) + '=' + Show(FRef) + '|';
        end;
        exit(Result);
    end;

    // The rows read by a filter on Report ID, in the order FindSet gives them: name, format, user defined.
    local procedure RowsOfReport(ReportId: Integer): Text
    var
        List: Record "Report Layout List";
        Result: Text;
    begin
        List.SetRange("Report ID", ReportId);
        Result := Format(List.Count()) + ':';
        if List.FindSet() then
            repeat
                Result += List.Name + '/' + Format(List."Layout Format") + '/' + Format(List."User Defined") + ';';
            until List.Next() = 0;
        exit(Result);
    end;

    local procedure ClearUserLayouts(ReportId: Integer)
    var
        Layout: Record "Tenant Report Layout";
        Selection: Record "Tenant Report Layout Selection";
    begin
        Layout.SetRange("Report ID", ReportId);
        Layout.DeleteAll();
        Selection.SetRange("Report ID", ReportId);
        Selection.DeleteAll();
    end;

    local procedure LayoutBytes(Kind: Integer; var InS: InStream)
    begin
        // Kind: 0 RDLC, 1 Word, 2 Excel.
        case Kind of
            0:
                Report.RdlcLayout(Report::"LT UDA Rpt", InS);
            1:
                Report.WordLayout(Report::"LT UDA Rpt", InS);
            2:
                Report.ExcelLayout(Report::"LT UDA Rpt", InS);
        end;
    end;

    local procedure AddLayout(var Observer: Codeunit "Probe Observer"; Tag: Text; ReportId: Integer; LayoutName: Text[250]; Kind: Integer; AppId: Guid; Company: Text[30])
    var
        Layout: Record "Tenant Report Layout";
        InS: InStream;
    begin
        Layout.Init();
        Layout."Report ID" := ReportId;
        Layout.Name := LayoutName;
        case Kind of
            0:
                Layout."Layout Format" := Layout."Layout Format"::RDLC;
            1:
                Layout."Layout Format" := Layout."Layout Format"::Word;
            2:
                Layout."Layout Format" := Layout."Layout Format"::Excel;
        end;
        Layout.Description := 'UDA ' + Tag;
        Layout."App ID" := AppId;
        Layout."Company Name" := Company;
        LayoutBytes(Kind, InS);
        Layout.Layout.ImportStream(InS, 'UDA ' + Tag);
        // An Insert inside a TryFunction is not allowed (first measurement): a failing Insert ends the test with its error.
        Observer.Observe(Tag + ' insert', Format(Layout.Insert()));
    end;

    local procedure ThisApp(): Guid
    var
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id());
    end;

    local procedure OtherApp(): Guid
    var
        Id: Guid;
    begin
        Evaluate(Id, OtherAppTxt);
        exit(Id);
    end;

    // A Word layout named with a GUID text, App ID blank, all companies: the declared rows before, every column of the user row, the rows by
    // Report ID after, and counts by Application ID and User Defined.
    [Test]
    procedure UDA_GuidName_Word_BlankAppId()
    var
        List: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
        Blank: Guid;
    begin
        ClearUserLayouts(Report::"LT UDA Rpt");
        Observer.Observe('declared', RowsOfReport(Report::"LT UDA Rpt"));
        AddLayout(Observer, 'word', Report::"LT UDA Rpt", GuidNameTxt, 1, Blank, '');
        Observer.Observe('row', Row(Report::"LT UDA Rpt", GuidNameTxt));
        Observer.Observe('after', RowsOfReport(Report::"LT UDA Rpt"));
        List.SetRange("Report ID", Report::"LT UDA Rpt");
        List.SetRange("Application ID", Blank);
        Observer.Observe('blank application id', Format(List.Count()));
        List.SetRange("Application ID", ThisApp());
        Observer.Observe('this app application id', Format(List.Count()));
        List.SetRange("Application ID");
        List.SetRange("User Defined", true);
        Observer.Observe('user defined', Format(List.Count()));
        List.SetRange("User Defined");
        List.SetRange(Name, GuidNameTxt);
        List.SetRange("Application ID", Blank);
        Observer.Observe('by name and blank app', Format(List.FindFirst()) + ' ' + List.Name);
        ClearUserLayouts(Report::"LT UDA Rpt");
        Observer.Expect('declared', '3:LtUdaExcel/Excel/No;LtUdaRdlc/RDLC/No;LtUdaWord/Word/No;');
        Observer.Expect('word insert', 'Yes');
#if BC29PLUS
        Observer.Expect('row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA word|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|19=Default|20=|21=|');
#elif BC28PLUS
        Observer.Expect('row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA word|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|');
#else
        Observer.Expect('row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA word|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|');
#endif
        Observer.Expect('after', '4:{6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}/Word/Yes;LtUdaExcel/Excel/No;LtUdaRdlc/RDLC/No;LtUdaWord/Word/No;');
        Observer.Expect('blank application id', '1');
        Observer.Expect('this app application id', '3');
        Observer.Expect('user defined', '1');
        Observer.Expect('by name and blank app', 'Yes {6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}');
        Observer.Verify();
    end;

    // The same Word layout with App ID = the id of this app, and with App ID = a GUID that names no app.
    [Test]
    procedure UDA_GuidName_Word_AppIdThisAppAndOther()
    var
        List: Record "Report Layout List";
        Observer: Codeunit "Probe Observer";
    begin
        ClearUserLayouts(Report::"LT UDA Rpt");
        AddLayout(Observer, 'this', Report::"LT UDA Rpt", GuidNameTxt, 1, ThisApp(), '');
        Observer.Observe('this row', Row(Report::"LT UDA Rpt", GuidNameTxt));
        List.SetRange("Report ID", Report::"LT UDA Rpt");
        List.SetRange("Application ID", ThisApp());
        Observer.Observe('this app application id', Format(List.Count()));
        ClearUserLayouts(Report::"LT UDA Rpt");
        AddLayout(Observer, 'other', Report::"LT UDA Rpt", GuidNameTxt, 1, OtherApp(), '');
        Observer.Observe('other row', Row(Report::"LT UDA Rpt", GuidNameTxt));
        List.SetRange("Application ID", OtherApp());
        Observer.Observe('other app application id', Format(List.Count()));
        Observer.Observe('other after', RowsOfReport(Report::"LT UDA Rpt"));
        ClearUserLayouts(Report::"LT UDA Rpt");
        Observer.Expect('this insert', 'Yes');
#if BC29PLUS
        Observer.Expect('this row', '5=this app|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA this|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|19=Default|20=|21=|');
#elif BC28PLUS
        Observer.Expect('this row', '5=this app|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA this|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|');
#else
        Observer.Expect('this row', '5=this app|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA this|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|');
#endif
        Observer.Expect('this app application id', '3');
        Observer.Expect('other insert', 'Yes');
#if BC29PLUS
        Observer.Expect('other row', '5=other app id|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA other|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|19=Default|20=|21=|');
#elif BC28PLUS
        Observer.Expect('other row', '5=other app id|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA other|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|');
#else
        Observer.Expect('other row', '5=other app id|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA other|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|');
#endif
        Observer.Expect('other app application id', '0');
        Observer.Expect('other after', '4:{6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}/Word/Yes;LtUdaExcel/Excel/No;LtUdaRdlc/RDLC/No;LtUdaWord/Word/No;');
        Observer.Verify();
    end;

    // Two rows with the same report and name, one with a blank App ID and one with this app's id: both stored? both listed?
    [Test]
    procedure UDA_GuidName_Word_SameNameTwoAppIds()
    var
        Observer: Codeunit "Probe Observer";
        Blank: Guid;
    begin
        ClearUserLayouts(Report::"LT UDA Rpt");
        AddLayout(Observer, 'blank', Report::"LT UDA Rpt", GuidNameTxt, 1, Blank, '');
        AddLayout(Observer, 'this', Report::"LT UDA Rpt", GuidNameTxt, 1, ThisApp(), '');
        Observer.Observe('after', RowsOfReport(Report::"LT UDA Rpt"));
        Observer.Observe('first row', Row(Report::"LT UDA Rpt", GuidNameTxt));
        ClearUserLayouts(Report::"LT UDA Rpt");
        Observer.Expect('blank insert', 'Yes');
        Observer.Expect('this insert', 'Yes');
        Observer.Expect('after', '5:{6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}/Word/Yes;{6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}/Word/Yes;LtUdaExcel/Excel/No;LtUdaRdlc/RDLC/No;LtUdaWord/Word/No;');
#if BC29PLUS
        Observer.Expect('first row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA blank|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|19=Default|20=|21=|');
#elif BC28PLUS
        Observer.Expect('first row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA blank|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|');
#else
        Observer.Expect('first row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA blank|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|');
#endif
        Observer.Verify();
    end;

    // An Excel layout with a GUID name for the current company only, and an RDLC layout with a GUID name and App ID = this app.
    [Test]
    procedure UDA_GuidName_ExcelCompany_RdlcThisApp()
    var
        Observer: Codeunit "Probe Observer";
        Blank: Guid;
    begin
        ClearUserLayouts(Report::"LT UDA Rpt");
        AddLayout(Observer, 'excel', Report::"LT UDA Rpt", GuidNameTxt, 2, Blank, CopyStr(CompanyName(), 1, 30));
        Observer.Observe('excel row', Row(Report::"LT UDA Rpt", GuidNameTxt));
        ClearUserLayouts(Report::"LT UDA Rpt");
        AddLayout(Observer, 'rdlc', Report::"LT UDA Rpt", GuidNameTxt, 0, ThisApp(), '');
        Observer.Observe('rdlc row', Row(Report::"LT UDA Rpt", GuidNameTxt));
        ClearUserLayouts(Report::"LT UDA Rpt");
        Observer.Expect('excel insert', 'Yes');
#if BC29PLUS
        Observer.Expect('excel row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Excel|8=null|9=|10=UDA excel|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|19=Default|20=|21=|');
#elif BC28PLUS
        Observer.Expect('excel row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Excel|8=null|9=|10=UDA excel|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|');
#else
        Observer.Expect('excel row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Excel|8=null|9=|10=UDA excel|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|');
#endif
        Observer.Expect('rdlc insert', 'Yes');
#if BC29PLUS
        Observer.Expect('rdlc row', '5=this app|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=RDLC|8=null|9=|10=UDA rdlc|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|19=Default|20=|21=|');
#elif BC28PLUS
        Observer.Expect('rdlc row', '5=this app|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=RDLC|8=null|9=|10=UDA rdlc|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|');
#else
        Observer.Expect('rdlc row', '5=this app|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=RDLC|8=null|9=|10=UDA rdlc|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|');
#endif
        Observer.Verify();
    end;

    // A Word layout for a report of another app (Base Application 1306); then one for a report id that names no report.
    [Test]
    procedure UDA_Word_ReportOfAnotherApp()
    var
        Observer: Codeunit "Probe Observer";
        Blank: Guid;
    begin
        ClearUserLayouts(1306);
        AddLayout(Observer, 'base app', 1306, GuidNameTxt, 1, Blank, '');
        Observer.Observe('base app row', Row(1306, GuidNameTxt));
        ClearUserLayouts(1306);
        Observer.Expect('base app insert', 'Yes');
#if BC29PLUS
        Observer.Expect('base app row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA base app|11=null|12=Sales - Invoice|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|19=Default|20=|21=|');
#elif BC28PLUS
        Observer.Expect('base app row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA base app|11=null|12=Sales - Invoice|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|');
#else
        Observer.Expect('base app row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA base app|11=null|12=Sales - Invoice|13=|14=Yes|15=Yes|16=No|17=Default|');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure UDA_Word_ReportIdOfNoReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // A layout for a report id that names no report: the sequence below fails (the first measurement had no Insert result before
        // the error), so it runs under asserterror and only the error is asserted.
        asserterror AddAndReadNoReport();
        Observer.Observe('no report', GetLastErrorText());
        // The Observer masks the emit version number as n.
        Observer.Expect('no report', 'You tried to invoke the Report object with the ID 96799 from the object LT UDA Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Verify();
    end;

    local procedure AddAndReadNoReport()
    var
        Observer: Codeunit "Probe Observer";
        Blank: Guid;
    begin
        ClearUserLayouts(96799);
        AddLayout(Observer, 'no report', 96799, GuidNameTxt, 1, Blank, '');
        Observer.Observe('no report rows', RowsOfReport(96799));
        Observer.Observe('no report row', Row(96799, GuidNameTxt));
    end;

    // A Tenant Report Layout Selection row (all companies, blank user) that picks the user-defined Word layout: the Report Layout List row after,
    // Report.DefaultLayout before and after.
    [Test]
    procedure UDA_GuidName_Word_PickedBySelection()
    var
        Selection: Record "Tenant Report Layout Selection";
        Observer: Codeunit "Probe Observer";
        Blank: Guid;
    begin
        ClearUserLayouts(Report::"LT UDA Rpt");
        Observer.Observe('default before', Format(Report.DefaultLayout(Report::"LT UDA Rpt")));
        AddLayout(Observer, 'word', Report::"LT UDA Rpt", GuidNameTxt, 1, Blank, '');
        Selection.Init();
        Selection."Report ID" := Report::"LT UDA Rpt";
        Selection."Company Name" := '';
        Selection."Layout Name" := GuidNameTxt;
        Selection."App ID" := Blank;
        Observer.Observe('selection insert', Format(Selection.Insert()));
        Observer.Observe('row', Row(Report::"LT UDA Rpt", GuidNameTxt));
        Observer.Observe('default after', Format(Report.DefaultLayout(Report::"LT UDA Rpt")));
        Observer.Observe('after', RowsOfReport(Report::"LT UDA Rpt"));
        ClearUserLayouts(Report::"LT UDA Rpt");
        Observer.Expect('default before', 'Word');
        Observer.Expect('word insert', 'Yes');
        Observer.Expect('selection insert', 'Yes');
#if BC29PLUS
        Observer.Expect('row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA word|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|19=Default|20=|21=|');
#elif BC28PLUS
        Observer.Expect('row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA word|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|18=Approved|');
#else
        Observer.Expect('row', '5=null|3={6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}|4=|6=not shown|7=Word|8=null|9=|10=UDA word|11=null|12=LT UDA Caption|13=|14=Yes|15=Yes|16=No|17=Default|');
#endif
        Observer.Expect('default after', 'Word');
        Observer.Expect('after', '4:{6F1C2A3B-0D4E-4F5A-8B9C-1D2E3F405162}/Word/Yes;LtUdaExcel/Excel/No;LtUdaRdlc/RDLC/No;LtUdaWord/Word/No;');
        Observer.Verify();
    end;
}
