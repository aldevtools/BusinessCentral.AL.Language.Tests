// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveasxml-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath)
// Fixtures used: Probe Observer (codeunit 69160); own table 98695, reports 98696-98698, test codeunit 98699 (writer Y51, gap cycle 5 spec G5-13)
// Probe: the report data file of TestRequestPage.SaveAsXml (a .NET DataSet) for column types report/lt-aq/AqSaveAsXml.al does not cover:
//        a Time report global in a column of an Integer data item (the Bank Deposit report shape, column(TIME; Time)), Time, DateTime,
//        Duration, BigInteger, Guid table fields with values and blank values, the system Time (only the schema line and the shape of
//        the value: digits replaced by 9), and the schema when no row is written.
//        Not repeated: errors/lt-ms-refusals-132/P132ReportTimeMs.al (Time in the Report.SaveAs XML dataset, not the SaveAsXml data file).
// Values: every literal asserted is what BC 27.5, 28.5 and 29.0 (Linux CI containers) produced; #if BC29PLUS where 29.0 differs.
// BC versions: 27, 28, 29

table 98695 "LT Y51 OP Time Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tm; Time) { }
        field(3; Dtm; DateTime) { }
        field(4; Dur; Duration) { }
        field(5; Big; BigInteger) { }
        field(6; G; Guid) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 98696 "LT Y51 OP Time Fields"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "LT Y51 OP Time Row")
        {
            column(IdC; Id) { }
            column(TmC; Tm) { }
            column(DtmC; Dtm) { }
            column(DurC; Dur) { }
            column(BigC; Big) { }
            column(GC; G) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; Ctl) { ApplicationArea = All; }
            }
        }
    }

    var
        Ctl: Integer;
}

report 98697 "LT Y51 OP Time Global"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Hdr; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(IdC; Number) { }
            column(TimeC; MyTime) { }
            column(UserC; UserTxt) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; Ctl) { ApplicationArea = All; }
            }
        }
    }

    trigger OnPreReport()
    begin
        MyTime := 143015.123T;
        UserTxt := 'U';
    end;

    var
        Ctl: Integer;
        MyTime: Time;
        UserTxt: Text;
}

report 98698 "LT Y51 OP Time System"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Hdr; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(IdC; Number) { }
            column(SysTimeC; Time) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Ctl; Ctl) { ApplicationArea = All; }
            }
        }
    }

    var
        Ctl: Integer;
}

codeunit 98699 "LT Y51 OP SaveAsXml Time"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ParametersFile: Text;
        DataFile: Text;

    local procedure Prepare()
    begin
        Commit();
        ParametersFile := TemporaryPath() + 'lt-y51-params.xml';
        DataFile := TemporaryPath() + 'lt-y51-data.xml';
        if Exists(ParametersFile) then
            Erase(ParametersFile);
        if Exists(DataFile) then
            Erase(DataFile);
    end;

    local procedure SeedRows()
    var
        Row: Record "LT Y51 OP Time Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Tm := 143015.123T;
        Row.Dtm := CreateDateTime(DMY2Date(15, 3, 2024), 143015.123T);
        Row.Dur := 1234567;
        Row.Big := 9007199254740993L;
        Row.G := '{0B3E2C7A-1D4F-4E5A-9C6B-7D8E9F0A1B2C}';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Tm := 000000.001T;
        Row.Insert();
        Row.Init();
        Row.Id := 3;
        Row.Tm := 235959.999T;
        Row.Insert();
        Row.Init();
        Row.Id := 4;
        Row.Insert();
    end;

    // The file as text, lines joined by |, without the byte order mark.
    local procedure FileText(Name: Text): Text
    var
        SaveFile: File;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        SaveFile.Open(Name);
        SaveFile.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        SaveFile.Close();
        exit(CopyStr(Result, 4));
    end;

    local procedure Columns(Content: Text): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Content.Split('|') do
            if Line.Contains(' type="') then
                Result += Line.Trim().Replace(' minOccurs="0" />', '') + '|';
        exit(Result);
    end;

    local procedure Rows(Content: Text): Text
    var
        Line: Text;
        Result: Text;
        After: Boolean;
    begin
        foreach Line in Content.Split('|') do begin
            if After then
                Result += Line.Trim() + '|';
            if Line.Contains('</xs:schema>') then
                After := true;
        end;
        exit(Result);
    end;

    // The lines that hold Name, with every digit replaced by 9.
    local procedure Shape(Content: Text; Name: Text): Text
    var
        Line: Text;
        Result: Text;
        I: Integer;
        C: Char;
    begin
        foreach Line in Content.Split('|') do
            if Line.Contains('<' + Name + '>') then begin
                for I := 1 to StrLen(Line) do begin
                    C := Line[I];
                    if (C >= '0') and (C <= '9') then
                        Result += '9'
                    else
                        Result += Format(C);
                end;
                Result := Result.Trim() + '|';
            end;
        exit(Result);
    end;

    [Test]
    [HandlerFunctions('GlobalHandler')]
    procedure SaveAsXml_TimeColumn_Global()
    var
        Observer: Codeunit "Probe Observer";
        Content: Text;
    begin
        Prepare();
        Report.Run(Report::"LT Y51 OP Time Global");
        Content := FileText(DataFile);
        Observer.Observe('schema', Columns(Content));
        Observer.Observe('rows', Rows(Content));
        Observer.Expect('schema', '<xs:element name="IdC" type="xs:int"|<xs:element name="TimeC" msdata:DateTimeMode="Local" type="xs:dateTime"|<xs:element name="UserC" type="xs:string"|');
        Observer.Expect('rows', '<Result>|<IdC>1</IdC>|<TimeC>1899-12-30T14:30:15+00:00</TimeC>|<UserC>U</UserC>|</Result>|</DataSet>||');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('FieldsHandler')]
    procedure SaveAsXml_TimeColumn_Field()
    var
        Observer: Codeunit "Probe Observer";
        Content: Text;
    begin
        SeedRows();
        Prepare();
        Report.Run(Report::"LT Y51 OP Time Fields");
        Content := FileText(DataFile);
        Observer.Observe('schema', Columns(Content));
        Observer.Observe('rows', Rows(Content));
#if BC29PLUS
        Observer.Expect('schema', '<xs:element name="IdC" type="xs:int"|<xs:element name="TmC" msdata:DateTimeMode="Local" type="xs:dateTime"|<xs:element name="DtmC" msdata:DateTimeMode="Local" type="xs:dateTime"|<xs:element name="DurC" type="xs:string"|<xs:element name="BigC" type="xs:long"|<xs:element name="GC" msdata:DataType="System.Guid, System.Private.CoreLib, Version=10.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e" type="xs:string"|');
        Observer.Expect('rows', '<Result>|<IdC>1</IdC>|<TmC>1899-12-30T14:30:15+00:00</TmC>|<DtmC>2024-03-15T14:30:15.123+00:00</DtmC>|<DurC>20 minutes 34 seconds 567 milliseconds</DurC>|<BigC>9007199254740993</BigC>|<GC>0b3e2c7a-1d4f-4e5a-9c6b-7d8e9f0a1b2c</GC>|</Result>|<Result>|<IdC>2</IdC>|<TmC>1899-12-30T00:00:00+00:00</TmC>|<DurC />|<BigC>0</BigC>|<GC>00000000-0000-0000-0000-000000000000</GC>|</Result>|<Result>|<IdC>3</IdC>|<TmC>1899-12-30T00:00:00+00:00</TmC>|<DurC />|<BigC>0</BigC>|<GC>00000000-0000-0000-0000-000000000000</GC>|</Result>|<Result>|<IdC>4</IdC>|<DurC />|<BigC>0</BigC>|<GC>00000000-0000-0000-0000-000000000000</GC>|</Result>|</DataSet>||');
#else
        Observer.Expect('schema', '<xs:element name="IdC" type="xs:int"|<xs:element name="TmC" msdata:DateTimeMode="Local" type="xs:dateTime"|<xs:element name="DtmC" msdata:DateTimeMode="Local" type="xs:dateTime"|<xs:element name="DurC" type="xs:string"|<xs:element name="BigC" type="xs:long"|<xs:element name="GC" msdata:DataType="System.Guid, System.Private.CoreLib, Version=8.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e" type="xs:string"|');
        Observer.Expect('rows', '<Result>|<IdC>1</IdC>|<TmC>1899-12-30T14:30:15+00:00</TmC>|<DtmC>2024-03-15T14:30:15.123+00:00</DtmC>|<DurC>20 minutes 34 seconds 567 milliseconds</DurC>|<BigC>9007199254740993</BigC>|<GC>0b3e2c7a-1d4f-4e5a-9c6b-7d8e9f0a1b2c</GC>|</Result>|<Result>|<IdC>2</IdC>|<TmC>1899-12-30T00:00:00+00:00</TmC>|<DurC />|<BigC>0</BigC>|<GC>00000000-0000-0000-0000-000000000000</GC>|</Result>|<Result>|<IdC>3</IdC>|<TmC>1899-12-30T00:00:00+00:00</TmC>|<DurC />|<BigC>0</BigC>|<GC>00000000-0000-0000-0000-000000000000</GC>|</Result>|<Result>|<IdC>4</IdC>|<DurC />|<BigC>0</BigC>|<GC>00000000-0000-0000-0000-000000000000</GC>|</Result>|</DataSet>||');
#endif
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SystemHandler')]
    procedure SaveAsXml_TimeColumn_System()
    var
        Observer: Codeunit "Probe Observer";
        Content: Text;
    begin
        Prepare();
        Report.Run(Report::"LT Y51 OP Time System");
        Content := FileText(DataFile);
        Observer.Observe('systime_schema', Columns(Content));
        Observer.Observe('systime_shape', Shape(Content, 'SysTimeC'));
        Observer.Expect('systime_schema', '<xs:element name="IdC" type="xs:int"|<xs:element name="SysTimeC" msdata:DateTimeMode="Local" type="xs:dateTime"|');
        Observer.Expect('systime_shape', '<SysTimeC>9999-99-99T99:99:99+99:99</SysTimeC>|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('FieldsHandler')]
    procedure SaveAsXml_TimeColumn_NoRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y51 OP Time Row";
        Content: Text;
    begin
        Row.DeleteAll();
        Prepare();
        Report.Run(Report::"LT Y51 OP Time Fields");
        Content := FileText(DataFile);
        Observer.Observe('schema', Columns(Content));
        Observer.Observe('rows', Rows(Content));
#if BC29PLUS
        Observer.Expect('schema', '<xs:element name="IdC" type="xs:int"|<xs:element name="TmC" msdata:DateTimeMode="Local" type="xs:dateTime"|<xs:element name="DtmC" msdata:DateTimeMode="Local" type="xs:dateTime"|<xs:element name="DurC" type="xs:string"|<xs:element name="BigC" type="xs:long"|<xs:element name="GC" msdata:DataType="System.Guid, System.Private.CoreLib, Version=10.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e" type="xs:string"|');
        Observer.Expect('rows', '</DataSet>||');
#else
        Observer.Expect('schema', '<xs:element name="IdC" type="xs:int"|<xs:element name="TmC" msdata:DateTimeMode="Local" type="xs:dateTime"|<xs:element name="DtmC" msdata:DateTimeMode="Local" type="xs:dateTime"|<xs:element name="DurC" type="xs:string"|<xs:element name="BigC" type="xs:long"|<xs:element name="GC" msdata:DataType="System.Guid, System.Private.CoreLib, Version=8.0.0.0, Culture=neutral, PublicKeyToken=7cec85d7bea7798e" type="xs:string"|');
        Observer.Expect('rows', '</DataSet>||');
#endif
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure GlobalHandler(var RP: TestRequestPage "LT Y51 OP Time Global")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [RequestPageHandler]
    procedure FieldsHandler(var RP: TestRequestPage "LT Y51 OP Time Fields")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [RequestPageHandler]
    procedure SystemHandler(var RP: TestRequestPage "LT Y51 OP Time System")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;
}
