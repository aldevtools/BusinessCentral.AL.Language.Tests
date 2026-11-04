// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveasxml-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath; EnableExternalAssemblies is Scope OnPrem)
// Fixtures used: Probe Observer (codeunit 69160, AL Language Coverage Tests app); own tables 98300-98301, reports 98302-98305, test codeunit 98306
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced (corpus issue 646, items 1, 2 and 23).
// Facts: the report data file of TestRequestPage.SaveAsXml (a .NET DataSet) for Decimal, Date, Boolean, Code, Option and empty Text columns,
// for a parent with a nested child data item and for two top-level data items; a report with EnableExternalAssemblies = true compiles in an
// OnPrem app and runs (the Cloud app refuses it: must-not-compile case 0806).
// BC versions: 27-29

table 98300 "LT AQ OP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Amount; Decimal) { }
        field(3; Day; Date) { }
        field(4; Flag; Boolean) { }
        field(5; Kind; Option) { OptionMembers = Alpha,Beta,Gamma; }
        field(6; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 98301 "LT AQ OP Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; RowCode; Code[20]) { }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 98302 "LT AQ OP Types"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "LT AQ OP Row")
        {
            column(CodeC; Code) { }
            column(AmountC; Amount) { }
            column(DayC; Day) { }
            column(FlagC; Flag) { }
            column(KindC; Kind) { }
            column(NameC; Name) { }
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

report 98303 "LT AQ OP Nested"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Par; "LT AQ OP Row")
        {
            column(ParCode; Code) { }
            dataitem(Chi; "LT AQ OP Child")
            {
                DataItemLink = RowCode = field(Code);
                column(ChiId; Id) { }
                column(ChiNote; Note) { }
            }
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

report 98304 "LT AQ OP Siblings"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Par; "LT AQ OP Row")
        {
            column(ParCode; Code) { }
        }
        dataitem(Oth; "LT AQ OP Child")
        {
            column(OthId; Id) { }
            column(OthNote; Note) { }
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

report 98305 "LT AQ OP Ext Assemblies"
{
    UsageCategory = None;
    UseRequestPage = false;
    EnableExternalAssemblies = true;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(N; Number) { }
        }
    }
}

codeunit 98306 "LT AQ OP SaveAsXml Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ParametersFile: Text;
        DataFile: Text;

    local procedure Seed()
    var
        Row: Record "LT AQ OP Row";
        Child: Record "LT AQ OP Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        Row.Code := 'R1';
        Row.Amount := 1234.5;
        Row.Day := DMY2Date(25, 12, 2024);
        Row.Flag := true;
        Row.Kind := Row.Kind::Gamma;
        Row.Name := 'n1';
        Row.Insert();
        Row.Init();
        Row.Code := 'R2';
        Row.Insert();
        Child.Id := 10; Child.RowCode := 'R1'; Child.Note := 'c10'; Child.Insert();
        Child.Id := 11; Child.RowCode := 'R1'; Child.Note := 'c11'; Child.Insert();
        Commit();
        ParametersFile := TemporaryPath() + 'lt-aq-params.xml';
        DataFile := TemporaryPath() + 'lt-aq-data.xml';
        if Exists(ParametersFile) then
            Erase(ParametersFile);
        if Exists(DataFile) then
            Erase(DataFile);
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

    // The xs:element lines of the schema that name a column (name="..." type="..."), then the rows after </xs:schema>, spaces at line starts removed.
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

    [Test]
    [HandlerFunctions('TypesHandler')]
    procedure SaveAsXml_ColumnTypes_DataFile()
    var
        Observer: Codeunit "Probe Observer";
        Content: Text;
    begin
        Seed();
        Report.Run(Report::"LT AQ OP Types");
        Content := FileText(DataFile);
        Observer.Observe('schema', Columns(Content));
        Observer.Observe('rows', Rows(Content));
        Observer.Expect('schema', '<xs:element name="CodeC" type="xs:string"|<xs:element name="AmountC" type="xs:decimal"|<xs:element name="AmountCFormat" type="xs:string"|<xs:element name="DayC" msdata:DateTimeMode="Local" type="xs:dateTime"|<xs:element name="FlagC" type="xs:boolean"|<xs:element name="KindC" type="xs:string"|<xs:element name="NameC" type="xs:string"|');
        Observer.Expect('rows', '<Result>|<CodeC>R1</CodeC>|<AmountC>1234.5</AmountC>|<AmountCFormat>#,##0.00</AmountCFormat>|<DayC>2024-12-25T00:00:00+00:00</DayC>|<FlagC>true</FlagC>|<KindC>Gamma</KindC>|<NameC>n1</NameC>|</Result>|<Result>|<CodeC>R2</CodeC>|<AmountC>0</AmountC>|<AmountCFormat>#,##0.00</AmountCFormat>|<FlagC>false</FlagC>|<KindC>Alpha</KindC>|<NameC />|</Result>|</DataSet>||');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('NestedHandler')]
    procedure SaveAsXml_NestedDataItems_DataFile()
    var
        Observer: Codeunit "Probe Observer";
        Content: Text;
    begin
        Seed();
        Report.Run(Report::"LT AQ OP Nested");
        Content := FileText(DataFile);
        Observer.Observe('schema', Columns(Content));
        Observer.Observe('rows', Rows(Content));
        Observer.Observe('full', Content);
        Observer.Expect('schema', '<xs:element name="ParCode" type="xs:string"|<xs:element name="ChiId" type="xs:int"|<xs:element name="ChiNote" type="xs:string"|');
        Observer.Expect('rows', '<Result>|<ParCode>R1</ParCode>|<ChiId>10</ChiId>|<ChiNote>c10</ChiNote>|</Result>|<Result>|<ParCode>R1</ParCode>|<ChiId>11</ChiId>|<ChiNote>c11</ChiNote>|</Result>|<Result>|<ParCode>R2</ParCode>|</Result>|</DataSet>||');
        Observer.Expect('full', '<?xml version="1.0" standalone="yes"?>|<DataSet>|  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">|    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:MainDataTable="Result" msdata:Locale="en-US">|      <xs:complexType>|        <xs:choice minOccurs="0" maxOccurs="unbounded">|          <xs:element name="Result" msdata:Locale="en-US">|            <xs:complexType>|              <xs:sequence>|                <xs:element name="ParCode" type="xs:string" minOccurs="0" />|                <xs:element name="ChiId" type="xs:int" minOccurs="0" />|                <xs:element name="ChiNote" type="xs:string" minOccurs="0" />|              </xs:sequence>|            </xs:complexType>|          </xs:element>|        </xs:choice>|      </xs:complexType>|    </xs:element>|  </xs:schema>|  <Result>|    <ParCode>R1</ParCode>|    <ChiId>10</ChiId>|    <ChiNote>c10</ChiNote>|  </Result>|  <Result>|    <ParCode>R1</ParCode>|    <ChiId>11</ChiId>|    <ChiNote>c11</ChiNote>|  </Result>|  <Result>|    <ParCode>R2</ParCode>|  </Result>|</DataSet>|');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SiblingsHandler')]
    procedure SaveAsXml_TwoTopLevelDataItems_DataFile()
    var
        Observer: Codeunit "Probe Observer";
        Content: Text;
    begin
        Seed();
        Report.Run(Report::"LT AQ OP Siblings");
        Content := FileText(DataFile);
        Observer.Observe('schema', Columns(Content));
        Observer.Observe('rows', Rows(Content));
        Observer.Expect('schema', '<xs:element name="ParCode" type="xs:string"|<xs:element name="OthId" type="xs:int"|<xs:element name="OthNote" type="xs:string"|');
        Observer.Expect('rows', '<Result>|<ParCode>R1</ParCode>|</Result>|<Result>|<ParCode>R2</ParCode>|</Result>|<Result>|<OthId>10</OthId>|<OthNote>c10</OthNote>|</Result>|<Result>|<OthId>11</OthId>|<OthNote>c11</OthNote>|</Result>|</DataSet>||');
        Observer.Verify();
    end;

    [Test]
    procedure EnableExternalAssemblies_OnPrem_CompilesAndRuns()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Xml: Text;
        Line: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT AQ OP Ext Assemblies", '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        Observer.Observe('column', CopyStr(Xml, StrPos(Xml, '<Column '), 30));
        Observer.Expect('column', '<Column name="N">1</Column>|  ');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure TypesHandler(var RP: TestRequestPage "LT AQ OP Types")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [RequestPageHandler]
    procedure NestedHandler(var RP: TestRequestPage "LT AQ OP Nested")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [RequestPageHandler]
    procedure SiblingsHandler(var RP: TestRequestPage "LT AQ OP Siblings")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;
}
