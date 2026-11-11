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
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI). Observation form: every test ends in Observer.Finish().

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

    [TryFunction]
    local procedure TryInsert(var Layout: Record "Tenant Report Layout"; var Inserted: Boolean)
    begin
        Inserted := Layout.Insert();
    end;

    local procedure AddLayout(var Observer: Codeunit "Probe Observer"; Tag: Text; ReportId: Integer; LayoutName: Text[250]; Kind: Integer; AppId: Guid; Company: Text[30])
    var
        Layout: Record "Tenant Report Layout";
        InS: InStream;
        Inserted: Boolean;
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
        if TryInsert(Layout, Inserted) then
            Observer.Observe(Tag + ' insert', Format(Inserted))
        else begin
            Observer.Observe(Tag + ' insert', 'error');
            Observer.ObserveError(Tag + ' insert');
        end;
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    // A Word layout for a report of another app (Base Application 1306), and one for a report id that names no report.
    [Test]
    procedure UDA_Word_ReportOfAnotherApp_AndNoReport()
    var
        Observer: Codeunit "Probe Observer";
        Blank: Guid;
    begin
        ClearUserLayouts(1306);
        AddLayout(Observer, 'base app', 1306, GuidNameTxt, 1, Blank, '');
        Observer.Observe('base app row', Row(1306, GuidNameTxt));
        ClearUserLayouts(1306);
        ClearUserLayouts(96799);
        AddLayout(Observer, 'no report', 96799, GuidNameTxt, 1, Blank, '');
        Observer.Observe('no report rows', RowsOfReport(96799));
        Observer.Observe('no report row', Row(96799, GuidNameTxt));
        ClearUserLayouts(96799);
        Observer.Finish();
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
        Observer.Finish();
    end;
}
