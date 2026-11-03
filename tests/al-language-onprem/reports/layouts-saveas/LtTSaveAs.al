// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveaspdf-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath, Report.SaveAs* are Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160); layout ./report/lt-t-saveas/LtTSave1.rdl of the app root; self-contained table 98100, report 98101, test codeunit 98102; writer QV: log codeunit 98970, report 98971 (CurrReport.Preview under SaveAsXml)
// Facts: Report.SaveAsExcel, SaveAsHtml, SaveAsPdf, SaveAsWord and SaveAsXml, static (report id, file name, record) and on a Report variable: the return value, whether the file exists, and the Record filter the data comes from.
// BC versions: 27.0 and later

table 98100 "LT T Save Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 98101 "LT T Save Report"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(T; "LT T Save Row")
        {
            column(Id; Id) { }
            column(Txt; Txt) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './reports/layouts-saveas/LtTSave1.rdl';
            Caption = 'LT T layout';
        }
    }
}

// Writer QV (AL Runner issue 5666): CurrReport.Preview in a dataset column and in the report triggers when Report.SaveAsXml (static and on
// a Report variable) runs the report. Log 98970 is used by test codeunit 98102 only.
codeunit 98970 "LT QV OnPrem Preview Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 98971 "LT QV OnPrem Preview Rpt"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(T; "LT T Save Row")
        {
            DataItemTableView = where(Id = const(1));
            column(Id; Id) { }
            column(PreviewValue; CurrReport.Preview()) { }

            trigger OnAfterGetRecord()
            begin
                L.Add('get preview=' + Format(CurrReport.Preview()));
            end;
        }
    }

    var
        L: Codeunit "LT QV OnPrem Preview Log";

    trigger OnPreReport()
    begin
        L.Add('pre preview=' + Format(CurrReport.Preview()));
    end;
}

codeunit 98102 "LT T Save As Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        Row: Record "LT T Save Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 4 do begin
            Row.Id := Index;
            Row.Txt := 'row' + Format(Index);
            Row.Insert();
        end;
        Commit();
    end;

    local procedure FileName(Ext: Text): Text
    var
        Name: Text;
    begin
        Name := TemporaryPath() + 'lt-t-save.' + Ext;
        if Exists(Name) then
            Erase(Name);
        exit(Name);
    end;

    local procedure Describe(Tag: Text; Ok: Boolean; Name: Text)
    var
        SaveFile: File;
        InStr: InStream;
        Value: Byte;
        One: Text[1];
        Head: Text;
        Count: Integer;
        Full: Text;
    begin
        Observer.Observe(Tag + ' ok', Format(Ok));
        Observer.ObserveError(Tag + ' last error');
        Observer.Observe(Tag + ' exists', Format(Exists(Name)));
        if Exists(Name) then begin
            SaveFile.Open(Name);
            SaveFile.CreateInStream(InStr);
            while (not InStr.EOS()) and (Count < 5) do begin
                InStr.Read(Value);
                One[1] := Value;
                Head += One;
                Count += 1;
            end;
            Observer.Observe(Tag + ' length>0', Format(SaveFile.Len() > 0));
            SaveFile.Close();
            if Name.EndsWith('.xml') then begin
                SaveFile.Open(Name);
                SaveFile.CreateInStream(InStr);
                while not InStr.EOS() do begin
                    InStr.ReadText(Head);
                    Full += Head + '|';
                end;
                SaveFile.Close();
                Observer.Observe(Tag + ' xml declaration', Format(Full.Contains('<?xml version="1.0" standalone="yes"?>')));
                Observer.Observe(Tag + ' ids', ColumnValues(Full, 'Id'));
                Observer.Observe(Tag + ' txts', ColumnValues(Full, 'Txt'));
            end;
            Erase(Name);
        end;
    end;

    local procedure ColumnValues(Source: Text; ColumnName: Text): Text
    var
        StartTag: Text;
        StartAt: Integer;
        EndAt: Integer;
        Result: Text;
    begin
        StartTag := '<Column name="' + ColumnName + '">';
        while true do begin
            StartAt := Source.IndexOf(StartTag);
            if StartAt = 0 then
                break;
            Source := Source.Substring(StartAt + StrLen(StartTag));
            EndAt := Source.IndexOf('</Column>');
            Result += Source.Substring(1, EndAt - 1) + ',';
            Source := Source.Substring(EndAt);
        end;
        exit(Result);
    end;

    local procedure FilterRows(var Row: Record "LT T Save Row")
    begin
        Row.SetFilter(Id, '>=%1', 3);
    end;

    [Test]
    procedure Static_Xml()
    var
        Row: Record "LT T Save Row";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('xml');
        Ok := Report.SaveAsXml(Report::"LT T Save Report", Name);
        Describe('xml', Ok, Name);
        FilterRows(Row);
        Name := FileName('xml');
        Ok := Report.SaveAsXml(Report::"LT T Save Report", Name, Row);
        Describe('xml filtered', Ok, Name);
        Observer.Expect('xml ok', 'Yes');
        Observer.Expect('xml last error|text', '');
        Observer.Expect('xml last error|code', '');
        Observer.Expect('xml exists', 'Yes');
        Observer.Expect('xml length>0', 'Yes');
        Observer.Expect('xml xml declaration', 'Yes');
        Observer.Expect('xml ids', '1,2,3,4,');
        Observer.Expect('xml txts', 'row1,row2,row3,row4,');
        Observer.Expect('xml filtered ok', 'Yes');
        Observer.Expect('xml filtered last error|text', '');
        Observer.Expect('xml filtered last error|code', '');
        Observer.Expect('xml filtered exists', 'Yes');
        Observer.Expect('xml filtered length>0', 'Yes');
        Observer.Expect('xml filtered xml declaration', 'Yes');
        Observer.Expect('xml filtered ids', '3,4,');
        Observer.Expect('xml filtered txts', 'row3,row4,');
        Observer.Verify();
    end;

// Linux suspects (RDLC rendering is stubbed on the Linux tier; Html is refused with an unverified text): kept as source, not compiled.
#if LT_T_LINUX_SUSPECT
    [Test]
    procedure Static_Pdf()
    var
        Row: Record "LT T Save Row";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('pdf');
        Ok := Report.SaveAsPdf(Report::"LT T Save Report", Name);
        Describe('pdf', Ok, Name);
        FilterRows(Row);
        Name := FileName('pdf');
        Ok := Report.SaveAsPdf(Report::"LT T Save Report", Name, Row);
        Describe('pdf filtered', Ok, Name);
        Observer.Finish();
    end;

    [Test]
    procedure Static_Html()
    var
        Row: Record "LT T Save Row";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('html');
        Ok := Report.SaveAsHtml(Report::"LT T Save Report", Name);
        Describe('html', Ok, Name);
        FilterRows(Row);
        Name := FileName('html');
        Ok := Report.SaveAsHtml(Report::"LT T Save Report", Name, Row);
        Describe('html filtered', Ok, Name);
        Observer.Finish();
    end;

    [Test]
    procedure Static_Excel()
    var
        Row: Record "LT T Save Row";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('xlsx');
        Ok := Report.SaveAsExcel(Report::"LT T Save Report", Name);
        Describe('excel', Ok, Name);
        FilterRows(Row);
        Name := FileName('xlsx');
        Ok := Report.SaveAsExcel(Report::"LT T Save Report", Name, Row);
        Describe('excel filtered', Ok, Name);
        Observer.Finish();
    end;

    [Test]
    procedure Static_Word()
    var
        Row: Record "LT T Save Row";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('docx');
        Ok := Report.SaveAsWord(Report::"LT T Save Report", Name);
        Describe('word', Ok, Name);
        FilterRows(Row);
        Name := FileName('docx');
        Ok := Report.SaveAsWord(Report::"LT T Save Report", Name, Row);
        Describe('word filtered', Ok, Name);
        Observer.Finish();
    end;

#endif

    local procedure InstanceOne(Tag: Text; Ext: Text; Filtered: Boolean)
    var
        Row: Record "LT T Save Row";
        Rpt: Report "LT T Save Report";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        if Filtered then begin
            FilterRows(Row);
            Rpt.SetTableView(Row);
        end;
        Name := FileName(Ext);
        case Ext of
            'xml':
                Ok := Rpt.SaveAsXml(Name);
            'pdf':
                Ok := Rpt.SaveAsPdf(Name);
            'html':
                Ok := Rpt.SaveAsHtml(Name);
            'xlsx':
                Ok := Rpt.SaveAsExcel(Name);
            'docx':
                Ok := Rpt.SaveAsWord(Name);
        end;
        Describe(Tag, Ok, Name);
    end;

    [Test]
    procedure Instance_Xml()
    begin
        InstanceOne('i xml', 'xml', false);
        InstanceOne('i xml filtered', 'xml', true);
        Observer.Expect('i xml ok', 'Yes');
        Observer.Expect('i xml last error|text', '');
        Observer.Expect('i xml last error|code', '');
        Observer.Expect('i xml exists', 'Yes');
        Observer.Expect('i xml length>0', 'Yes');
        Observer.Expect('i xml xml declaration', 'Yes');
        Observer.Expect('i xml ids', '1,2,3,4,');
        Observer.Expect('i xml txts', 'row1,row2,row3,row4,');
        Observer.Expect('i xml filtered ok', 'Yes');
        Observer.Expect('i xml filtered last error|text', '');
        Observer.Expect('i xml filtered last error|code', '');
        Observer.Expect('i xml filtered exists', 'Yes');
        Observer.Expect('i xml filtered length>0', 'Yes');
        Observer.Expect('i xml filtered xml declaration', 'Yes');
        Observer.Expect('i xml filtered ids', '3,4,');
        Observer.Expect('i xml filtered txts', 'row3,row4,');
        Observer.Verify();
    end;

#if LT_T_LINUX_SUSPECT
    [Test]
    procedure Instance_Html()
    begin
        InstanceOne('i html', 'html', false);
        Observer.Finish();
    end;

    [Test]
    procedure Instance_Pdf()
    begin
        InstanceOne('i pdf', 'pdf', false);
        InstanceOne('i pdf filtered', 'pdf', true);
        Observer.Finish();
    end;

    [Test]
    procedure Instance_Excel()
    begin
        InstanceOne('i excel', 'xlsx', false);
        Observer.Finish();
    end;

    [Test]
    procedure Instance_Word()
    begin
        InstanceOne('i word', 'docx', false);
        Observer.Finish();
    end;

#endif

    [Test]
    procedure Instance_SecondUse()
    var
        Rpt: Report "LT T Save Report";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := FileName('xml');
        Ok := Rpt.SaveAsXml(Name);
        Observer.Observe('first ok', Format(Ok));
        Erase(Name);
        Ok := Rpt.SaveAsXml(Name);
        Observer.Observe('second same format ok', Format(Ok));
        Observer.Observe('second same format exists', Format(Exists(Name)));
        ClearLastError();
        Ok := Rpt.SaveAsPdf(FileName('pdf'));
        Observer.Observe('other format ok', Format(Ok));
        Observer.ObserveError('other format');
        Clear(Rpt);
        Ok := Rpt.SaveAsXml(Name);
        Observer.Observe('after clear ok', Format(Ok));
        Observer.Expect('first ok', 'Yes');
        Observer.Expect('second same format ok', 'No');
        Observer.Expect('second same format exists', 'No');
        Observer.Expect('other format ok', 'No');
        Observer.Expect('other format|text', 'The object has been run. Use the function CLEAR(Report).');
        Observer.Expect('other format|code', 'ObjectHasAlreadyBeenRun');
        Observer.Expect('after clear ok', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QV_Preview_SaveAsXml_StaticAndInstance()
    var
        PreviewLog: Codeunit "LT QV OnPrem Preview Log";
        Rpt: Report "LT QV OnPrem Preview Rpt";
        SaveFile: File;
        InStr: InStream;
        Line: Text;
        Full: Text;
        Name: Text;
    begin
        Seed();
        PreviewLog.Take();
        Name := FileName('xml');
        ClearLastError();
        Observer.Observe('static ok', Format(Report.SaveAsXml(Report::"LT QV OnPrem Preview Rpt", Name)));
        Observer.ObserveError('static error');
        Observer.Observe('static log', PreviewLog.Take());
        if Exists(Name) then begin
            SaveFile.Open(Name);
            SaveFile.CreateInStream(InStr);
            while not InStr.EOS() do begin
                InStr.ReadText(Line);
                Full += Line + '|';
            end;
            SaveFile.Close();
            Erase(Name);
        end;
        Observer.Observe('static column', ColumnValues(Full, 'PreviewValue'));
        Name := FileName('xml');
        Full := '';
        ClearLastError();
        Observer.Observe('instance ok', Format(Rpt.SaveAsXml(Name)));
        Observer.ObserveError('instance error');
        Observer.Observe('instance log', PreviewLog.Take());
        if Exists(Name) then begin
            SaveFile.Open(Name);
            SaveFile.CreateInStream(InStr);
            while not InStr.EOS() do begin
                InStr.ReadText(Line);
                Full += Line + '|';
            end;
            SaveFile.Close();
            Erase(Name);
        end;
        Observer.Observe('instance column', ColumnValues(Full, 'PreviewValue'));
        Observer.Expect('static ok', 'Yes');
        Observer.Expect('static error|text', '');
        Observer.Expect('static error|code', '');
        Observer.Expect('static log', 'pre preview=No;get preview=No;');
        Observer.Expect('static column', 'False,');
        Observer.Expect('instance ok', 'Yes');
        Observer.Expect('instance error|text', '');
        Observer.Expect('instance error|code', '');
        Observer.Expect('instance log', 'pre preview=No;get preview=No;');
        Observer.Expect('instance column', 'False,');
        Observer.Verify();
    end;
}
