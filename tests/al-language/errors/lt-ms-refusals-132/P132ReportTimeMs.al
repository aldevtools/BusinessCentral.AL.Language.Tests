// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73712, reports 73710, 73740, 73741; layout file ProbeSdLayout.rdl at the app root (used by tests/al-language/handlers/TestReportSaveAsColumnDetailsContracts.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 73712 "LT P132 Time Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tm; Time) { }
        field(3; Dtm; DateTime) { }
        field(4; Dur; Duration) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 73710 "LT P132 Time Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "LT P132 Time Row")
        {
            column(IdC; Id) { }
            column(TmC; Tm) { }
            column(DtmC; Dtm) { }
            column(DurC; Dur) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './ProbeSdLayout.rdl';
            Caption = 'P132 layout';
        }
    }
}

report 73740 "LT P132 PreErr Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "LT P132 Time Row")
        {
            column(IdC; Id) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './ProbeSdLayout_2.rdl';
            Caption = 'P132 layout';
        }
    }

    trigger OnPreReport()
    begin
        Error('LT P132 pre report failed');
    end;
}

report 73741 "LT P132 RowErr Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "LT P132 Time Row")
        {
            column(IdC; Id) { }

            trigger OnAfterGetRecord()
            begin
                if Id = 2 then
                    Error('LT P132 row %1 failed', Id);
            end;
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './ProbeSdLayout_3.rdl';
            Caption = 'P132 layout';
        }
    }
}

codeunit 73711 "LT P132 Report Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ColumnLines(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
        Ok: Boolean;
    begin
        TempBlob.CreateOutStream(OutStr);
        Ok := Report.SaveAs(ReportId, '', ReportFormat::Xml, OutStr);
        if not Ok then
            exit('SaveAs false');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            if Line.StartsWith('<Column ') then
                Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure RunOne(var Observer: Codeunit "Probe Observer"; ObsName: Text; Tm: Time; Dtm: DateTime; Dur: Duration)
    var
        Row: Record "LT P132 Time Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Tm := Tm;
        Row.Dtm := Dtm;
        Row.Dur := Dur;
        Row.Insert();
        Commit();
        Observer.Observe(ObsName, ColumnLines(Report::"LT P132 Time Report"));
    end;

    [TryFunction]
    local procedure TrySaveAs(ReportId: Integer; var Ok: Boolean; var Len: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        Ok := Report.SaveAs(ReportId, '', ReportFormat::Xml, OutStr);
        Len := TempBlob.Length();
    end;

    local procedure ErrorRun(var Observer: Codeunit "Probe Observer"; ObsName: Text; ReportId: Integer)
    var
        Ok: Boolean;
        Len: Integer;
        Tried: Boolean;
    begin
        Ok := true;
        Len := -1;
        Tried := TrySaveAs(ReportId, Ok, Len);
        Observer.Observe(ObsName + '_tryfunction', Format(Tried));
        Observer.Observe(ObsName + '_saveas', Format(Ok));
        Observer.Observe(ObsName + '_length', Format(Len));
        Observer.Observe(ObsName + '_error', GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
    end;

    [Test]
    procedure P132_Dataset_Time_Milliseconds()
    var
        Observer: Codeunit "Probe Observer";
        NoDt: DateTime;
    begin
        RunOne(Observer, 'ms_123', 133000.123T, NoDt, 0);
        RunOne(Observer, 'ms_500', 133000.500T, NoDt, 0);
        RunOne(Observer, 'ms_001', 133000.001T, NoDt, 0);
        RunOne(Observer, 'ms_010', 133000.010T, NoDt, 0);
        RunOne(Observer, 'ms_999', 235959.999T, NoDt, 0);
        RunOne(Observer, 'ms_000', 133000T, NoDt, 0);
        RunOne(Observer, 'midnight_ms', 000000.001T, NoDt, 0);
        Observer.Expect('ms_123', '<Column name="IdC">1</Column>|<Column name="TmC">1:30:00 PM</Column>|<Column name="DtmC"></Column>|<Column name="DurC"></Column>|');
        Observer.Expect('ms_500', '<Column name="IdC">1</Column>|<Column name="TmC">1:30:00 PM</Column>|<Column name="DtmC"></Column>|<Column name="DurC"></Column>|');
        Observer.Expect('ms_001', '<Column name="IdC">1</Column>|<Column name="TmC">1:30:00 PM</Column>|<Column name="DtmC"></Column>|<Column name="DurC"></Column>|');
        Observer.Expect('ms_010', '<Column name="IdC">1</Column>|<Column name="TmC">1:30:00 PM</Column>|<Column name="DtmC"></Column>|<Column name="DurC"></Column>|');
        Observer.Expect('ms_999', '<Column name="IdC">1</Column>|<Column name="TmC">12:00:00 AM</Column>|<Column name="DtmC"></Column>|<Column name="DurC"></Column>|');
        Observer.Expect('ms_000', '<Column name="IdC">1</Column>|<Column name="TmC">1:30:00 PM</Column>|<Column name="DtmC"></Column>|<Column name="DurC"></Column>|');
        Observer.Expect('midnight_ms', '<Column name="IdC">1</Column>|<Column name="TmC">12:00:00 AM</Column>|<Column name="DtmC"></Column>|<Column name="DurC"></Column>|');
        Observer.Verify();
    end;

    [Test]
    procedure P132_Dataset_DateTime_Milliseconds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOne(Observer, 'dt_123', 0T, CreateDateTime(20240305D, 133000.123T), 0);
        RunOne(Observer, 'dt_500', 0T, CreateDateTime(20240305D, 133000.500T), 0);
        RunOne(Observer, 'dt_001', 0T, CreateDateTime(20240305D, 133000.001T), 0);
        RunOne(Observer, 'dt_000', 0T, CreateDateTime(20240305D, 133000T), 0);
        Observer.Expect('dt_123', '<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC">3/5/2024 1:30:00 PM</Column>|<Column name="DurC"></Column>|');
        Observer.Expect('dt_500', '<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC">3/5/2024 1:30:00 PM</Column>|<Column name="DurC"></Column>|');
        Observer.Expect('dt_001', '<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC">3/5/2024 1:30:00 PM</Column>|<Column name="DurC"></Column>|');
        Observer.Expect('dt_000', '<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC">3/5/2024 1:30:00 PM</Column>|<Column name="DurC"></Column>|');
        Observer.Verify();
    end;

    [Test]
    procedure P132_Dataset_Duration_Milliseconds()
    var
        Observer: Codeunit "Probe Observer";
        NoDt: DateTime;
    begin
        RunOne(Observer, 'dur_1500', 0T, NoDt, 1500);
        RunOne(Observer, 'dur_1', 0T, NoDt, 1);
        RunOne(Observer, 'dur_3723004', 0T, NoDt, 3723004);
        RunOne(Observer, 'dur_whole_seconds', 0T, NoDt, 5000);
        RunOne(Observer, 'dur_negative', 0T, NoDt, -1500);
        Observer.Expect('dur_1500', '<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC"></Column>|<Column name="DurC">1 second 500 milliseconds</Column>|');
        Observer.Expect('dur_1', '<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC"></Column>|<Column name="DurC">1 millisecond</Column>|');
        Observer.Expect('dur_3723004', '<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC"></Column>|<Column name="DurC">1 hour 2 minutes 3 seconds 4 milliseconds</Column>|');
        Observer.Expect('dur_whole_seconds', '<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC"></Column>|<Column name="DurC">5 seconds</Column>|');
        Observer.Expect('dur_negative', '<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC"></Column>|<Column name="DurC">-1 second 500 milliseconds</Column>|');
        Observer.Verify();
    end;

    [Test]
    procedure P132_SaveAs_ErrorInOnPreReport()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P132 Time Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
        ErrorRun(Observer, 'prereport', Report::"LT P132 PreErr Report");
        Observer.Expect('prereport_tryfunction', 'Yes');
        Observer.Expect('prereport_saveas', 'No');
        Observer.Expect('prereport_length', '0');
        Observer.Expect('prereport_error', 'LT P132 pre report failed|Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure P132_SaveAs_ErrorInOnAfterGetRecord()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P132 Time Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Commit();
        ErrorRun(Observer, 'row', Report::"LT P132 RowErr Report");
        Observer.Expect('row_tryfunction', 'Yes');
        Observer.Expect('row_saveas', 'No');
        Observer.Expect('row_length', '0');
        Observer.Expect('row_error', 'LT P132 row 2 failed|Dialog');
        Observer.Verify();
    end;

    // Writer Y38 (gap cycle 3, C3-19): the stored Time of a row (read back with Get) and its dataset column, for milliseconds near the next
    // second, to tell a rounding of the stored value from a rounding of the dataset text (ms_999 above shows 235959.999T as 12:00:00 AM).
    local procedure Y38StoredAndColumn(var Observer: Codeunit "Probe Observer"; ObsName: Text; Tm: Time)
    var
        Row: Record "LT P132 Time Row";
        NoDt: DateTime;
    begin
        RunOne(Observer, ObsName + '_col', Tm, NoDt, 0);
        Row.Get(1);
        Observer.Observe(ObsName + '_stored', Format(Row.Tm, 0, 9) + '|' + Format(Row.Tm = Tm));
    end;

    [Test]
    procedure Y38_P132_Dataset_Time_NearNextSecond()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y38StoredAndColumn(Observer, 'ms_995', 133000.995T);
        Y38StoredAndColumn(Observer, 'ms_997', 133000.997T);
        Y38StoredAndColumn(Observer, 'ms_998', 133000.998T);
        Y38StoredAndColumn(Observer, 'ms_999', 133000.999T);
        Observer.Finish();
    end;

    [Test]
    procedure Y38_P132_Dataset_Time_OtherMilliseconds()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y38StoredAndColumn(Observer, 'ms_002', 133000.002T);
        Y38StoredAndColumn(Observer, 'ms_499', 133000.499T);
        Y38StoredAndColumn(Observer, 'ms_501', 133000.501T);
        Y38StoredAndColumn(Observer, 'ms_750', 133000.750T);
        Observer.Finish();
    end;

    // The same Time values as a column bound to a global variable of the report (not stored in a table).
    local procedure Y38VarColumn(Tm: Time): Text
    var
        Rep: Report "LT Y38 Time Var Report";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        Rep.SetTime(Tm);
        TempBlob.CreateOutStream(OutStr);
        if not Rep.SaveAs('', ReportFormat::Xml, OutStr) then
            exit('SaveAs false');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            if Line.StartsWith('<Column ') then
                Result += Line + '|';
        end;
        exit(Result);
    end;

    [Test]
    procedure Y38_P132_Dataset_Time_GlobalVariable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('var_500', Y38VarColumn(133000.500T));
        Observer.Observe('var_998', Y38VarColumn(133000.998T));
        Observer.Observe('var_999', Y38VarColumn(133000.999T));
        Observer.Observe('var_235959_999', Y38VarColumn(235959.999T));
        Observer.Finish();
    end;
}

// Writer Y38 (gap cycle 3, C3-19): one row (Integer 1) with a column bound to a global Time variable. No layout: run with SaveAs Xml only.
report 92589 "LT Y38 Time Var Report"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(TmC; GlobalTm) { }
        }
    }

    var
        GlobalTm: Time;

    procedure SetTime(Tm: Time)
    begin
        GlobalTm := Tm;
    end;
}
