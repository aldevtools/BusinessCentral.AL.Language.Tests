// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testrequestpage/testrequestpage-saveasxml-method
// Scope: in-scope, but ONLY for a Target = OnPrem app (File, TemporaryPath)
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app; self-contained table 61240,
//                codeunit 61241 (log), report 61242, codeunit 61243 (tests)
//                Writer TO: tests TO_SaveAsXml_* on tables 98060-98061 and reports 98062-98063 (ToRpSaveAsXmlDataItems.al): nested and sibling data items.
// Probe: written against a real BC 27.5 service tier started by bc-linux; every literal below is what
// that tier produced. Other BC versions and other hosts were not measured.
// BC versions: 27.5
//
// Pins TestRequestPage.SaveAsXml(ParametersFileName, ReportDataFileName) called from a request page
// handler:
//  - It runs the report there and then, with the request page's values: OnInitReport, OnPreReport, the data
//    item (filter set on the request page applied), OnPostReport. Report.Run does not run it a second time.
//  - It writes two files. The parameters file is UTF-8 with a byte order mark: an ArrayOfReportParameter
//    element with a ReportParameter for the user id (Values: the user name) and one for the execution time.
//    The report data file is a .NET DataSet: the schema of the rows (one element per column, in
//    column order, with the .NET type of the column) and a Result element per row.
//  - The parameters file has line feeds only (no carriage return), no line feed after the last element, the parameter names
//    NavUserId and ExecutionTime followed by a fixed 32 digit hexadecimal GUID (AE6AEB42076449B78A3E78A5EE366751 and
//    7587CE19257C4965B7E6066BDFF21EE3) and an execution time like 2026-10-14T16:34:09.4490000+00:00. TemporaryPath() on this tier
//    ends with TEMP and a backslash.
//  - The request page is closed by it: every later use of the handler's page raises
//    "The TestPage is not open." / TestPageNotOpened.

table 61240 "Probe RP Save Table"
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

codeunit 61241 "Probe RP Save Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

report 61242 "Probe RP Save Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(T; "Probe RP Save Table")
        {
            column(Id; Id) { }
            column(Txt; Txt) { }

            trigger OnPreDataItem()
            begin
                SaveLog.Add('PreDataItem');
                T.SetFilter(Id, '>=%1', Threshold);
            end;

            trigger OnAfterGetRecord()
            begin
                SaveLog.Add('Row' + Format(T.Id));
            end;

            trigger OnPostDataItem()
            begin
                SaveLog.Add('PostDataItem');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(ThresholdField; Threshold) { ApplicationArea = All; }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './ProbeRpSaveLayout.rdl';
            Caption = 'Probe layout';
        }
    }

    var
        Threshold: Integer;
        SaveLog: Codeunit "Probe RP Save Log";

    trigger OnInitReport()
    begin
        SaveLog.Add('InitReport');
    end;

    trigger OnPreReport()
    begin
        SaveLog.Add('PreReport');
    end;

    trigger OnPostReport()
    begin
        SaveLog.Add('PostReport');
    end;
}

codeunit 61243 "Probe RP SaveAsXml"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SaveLog: Codeunit "Probe RP Save Log";
        ParametersFile: Text;
        DataFile: Text;
        AfterCancelText: Text;
        AfterCancelCode: Text;
        AfterSecondSaveText: Text;
        AfterFieldText: Text;

    local procedure Seed()
    var
        SaveRec: Record "Probe RP Save Table";
    begin
        SaveRec.DeleteAll();
        SaveRec.Id := 1;
        SaveRec.Txt := 'a';
        SaveRec.Insert();
        SaveRec.Id := 2;
        SaveRec.Txt := 'b';
        SaveRec.Insert();
        SaveRec.Id := 3;
        SaveRec.Txt := 'c';
        SaveRec.Insert();
        Commit();
        ParametersFile := TemporaryPath() + 'probe-rp-params.xml';
        DataFile := TemporaryPath() + 'probe-rp-data.xml';
        if Exists(ParametersFile) then
            Erase(ParametersFile);
        if Exists(DataFile) then
            Erase(DataFile);
        SaveLog.Take();
    end;

    local procedure FileText(Name: Text; var HadBom: Boolean): Text
    var
        SaveFile: File;
        InStr: InStream;
        Line: Text;
        Result: Text;
        Bom: Text[3];
    begin
        SaveFile.Open(Name);
        SaveFile.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        SaveFile.Close();
        // The byte order mark is read as three characters (the stream is read as a single-byte text in the OEM code page: EF BB BF
        // are U+00D9, U+2039 and U+008F, as on the Windows tier).
        Bom[1] := 217;
        Bom[2] := 8249;
        Bom[3] := 143;
        HadBom := Result.StartsWith(Bom);
        if HadBom then
            Result := CopyStr(Result, 4);
        exit(Result);
    end;

    [RequestPageHandler]
    procedure SaveAsXmlHandler(var RP: TestRequestPage "Probe RP Save Report")
    begin
        RP.ThresholdField.SetValue(2);
        RP.SaveAsXml(ParametersFile, DataFile);
        asserterror RP.Cancel().Invoke();
        AfterCancelText := GetLastErrorText();
        AfterCancelCode := GetLastErrorCode();
        asserterror RP.SaveAsXml(ParametersFile, DataFile);
        AfterSecondSaveText := GetLastErrorText();
        asserterror RP.ThresholdField.SetValue(1);
        AfterFieldText := GetLastErrorText();
    end;

    [Test]
    [HandlerFunctions('SaveAsXmlHandler')]
    procedure SaveAsXml_RunsTheReportOnce_AndClosesTheRequestPage()
    begin
        Seed();

        Report.Run(Report::"Probe RP Save Report");

        Assert.AreEqual('InitReport;PreReport;PreDataItem;Row2;Row3;PostDataItem;PostReport;', SaveLog.Take(), 'one run, with the request page value');
        Assert.AreEqual('The TestPage is not open.', AfterCancelText, 'Cancel after SaveAsXml');
        Assert.AreEqual('TestPageNotOpened', AfterCancelCode, 'code');
        Assert.AreEqual('The TestPage is not open.', AfterSecondSaveText, 'second SaveAsXml');
        Assert.AreEqual('The TestPage is not open.', AfterFieldText, 'a field after SaveAsXml');
        Assert.IsTrue(Exists(ParametersFile), 'parameters file');
        Assert.IsTrue(Exists(DataFile), 'data file');
    end;

    [Test]
    [HandlerFunctions('SaveAsXmlHandler')]
    procedure SaveAsXml_ReportDataFile_IsADataSet()
    var
        Content: Text;
        HadBom: Boolean;
    begin
        Seed();

        Report.Run(Report::"Probe RP Save Report");

        Content := FileText(DataFile, HadBom);
        Assert.IsTrue(HadBom, 'byte order mark');
        Assert.AreEqual(
            '<?xml version="1.0" standalone="yes"?>|' +
            '<DataSet>|' +
            '  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">|' +
            '    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:MainDataTable="Result" msdata:Locale="en-US">|' +
            '      <xs:complexType>|' +
            '        <xs:choice minOccurs="0" maxOccurs="unbounded">|' +
            '          <xs:element name="Result" msdata:Locale="en-US">|' +
            '            <xs:complexType>|' +
            '              <xs:sequence>|' +
            '                <xs:element name="Id" type="xs:int" minOccurs="0" />|' +
            '                <xs:element name="Txt" type="xs:string" minOccurs="0" />|' +
            '              </xs:sequence>|' +
            '            </xs:complexType>|' +
            '          </xs:element>|' +
            '        </xs:choice>|' +
            '      </xs:complexType>|' +
            '    </xs:element>|' +
            '  </xs:schema>|' +
            '  <Result>|' +
            '    <Id>2</Id>|' +
            '    <Txt>b</Txt>|' +
            '  </Result>|' +
            '  <Result>|' +
            '    <Id>3</Id>|' +
            '    <Txt>c</Txt>|' +
            '  </Result>|' +
            '</DataSet>|',
            Content, 'data file text');
    end;

    [Test]
    [HandlerFunctions('SaveAsXmlHandler')]
    procedure SaveAsXml_ParametersFile_ListsTheUserAndTheExecutionTime()
    var
        Text: Text;
        HadBom: Boolean;
    begin
        Seed();

        Report.Run(Report::"Probe RP Save Report");

        Text := FileText(ParametersFile, HadBom);
        Assert.IsTrue(HadBom, 'byte order mark');
        Assert.IsTrue(Text.StartsWith('<?xml version="1.0" encoding="utf-8"?>|<ArrayOfReportParameter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">|  <ReportParameter>|    <Name>NavUserId'), 'start');
        Assert.IsTrue(Text.Contains('    <Values>|      <string>' + UserId() + '</string>|    </Values>|    <Visible>true</Visible>|  </ReportParameter>|  <ReportParameter>|    <Name>ExecutionTime'), 'user id value, then the execution time');
        Assert.IsTrue(Text.EndsWith('</string>|    </Values>|    <Visible>true</Visible>|  </ReportParameter>|</ArrayOfReportParameter>|'), 'end');
        Assert.IsFalse(Text.Contains('Threshold'), 'a request page field is not listed');
    end;

    local procedure RawText(Name: Text): Text
    var
        SaveFile: File;
        InStr: InStream;
        Value: Byte;
        One: Text[1];
        Result: Text;
    begin
        SaveFile.Open(Name);
        SaveFile.CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.Read(Value);
            One[1] := Value;
            Result += One;
        end;
        SaveFile.Close();
        exit(Result);
    end;

    [Test]
    [HandlerFunctions('SaveAsXmlHandler')]
    procedure SaveAsXml_ParametersFile_RawForm()
    var
        Raw: Text;
        Cr: Text[1];
        ExecutionTime: Text;
        StartAt: Integer;
    begin
        Seed();
        Cr[1] := 13;

        Report.Run(Report::"Probe RP Save Report");

        Raw := RawText(ParametersFile);
        Assert.IsTrue(Raw.Contains(Cr), 'lines end with a carriage return and a line feed');
        Assert.IsTrue(Raw.EndsWith('</ArrayOfReportParameter>'), 'no line feed after the last element');
        Assert.IsTrue(Raw.Contains('    <Name>NavUserIdAE6AEB42076449B78A3E78A5EE366751</Name>'), 'user id parameter name');
        Assert.IsTrue(Raw.Contains('    <Name>ExecutionTime7587CE19257C4965B7E6066BDFF21EE3</Name>'), 'execution time parameter name');
        StartAt := Raw.IndexOf('<string>2');
        ExecutionTime := Raw.Substring(StartAt + 8, 33);
        Assert.AreEqual('T', CopyStr(ExecutionTime, 11, 1), 'ISO date and time');
        Assert.AreEqual('.', CopyStr(ExecutionTime, 20, 1), 'seven fraction digits');
        Assert.AreEqual('+00:00', CopyStr(ExecutionTime, 28, 6), 'UTC offset');
        Assert.IsTrue(Raw.Contains(ExecutionTime + '</string>'), 'closing');
    end;

    [Test]
    procedure TemporaryPath_EndsWithTheTempFolderAndABackslash()
    begin
        Assert.IsTrue(TemporaryPath().EndsWith('TEMP\'), 'TemporaryPath');
    end;

    local procedure ToSeed()
    var
        P: Record "LT TO RP Parent";
        C: Record "LT TO RP Child";
    begin
        P.DeleteAll();
        C.DeleteAll();
        P.Id := 1;
        P.Name := 'a';
        P.Insert();
        P.Id := 2;
        P.Name := '';
        P.Insert();
        P.Id := 3;
        P.Name := 'c';
        P.Insert();
        C.ParentId := 1;
        C.LineNo := 10;
        C.Qty := 1.5;
        C.Insert();
        C.ParentId := 1;
        C.LineNo := 20;
        C.Qty := 2;
        C.Insert();
        C.ParentId := 3;
        C.LineNo := 10;
        C.Qty := 0;
        C.Insert();
        Commit();
        ParametersFile := TemporaryPath() + 'probe-to-params.xml';
        DataFile := TemporaryPath() + 'probe-to-data.xml';
        if Exists(ParametersFile) then
            Erase(ParametersFile);
        if Exists(DataFile) then
            Erase(DataFile);
    end;

    local procedure ToSplit(Content: Text; var Schema: Text; var Rows: Text)
    var
        At: Integer;
    begin
        At := StrPos(Content, '</xs:schema>|');
        if At = 0 then begin
            Schema := Content;
            Rows := '';
            exit;
        end;
        Schema := CopyStr(Content, 1, At + StrLen('</xs:schema>|') - 1);
        Rows := CopyStr(Content, At + StrLen('</xs:schema>|'));
    end;

    [RequestPageHandler]
    procedure ToNestedHandler(var RP: TestRequestPage "LT TO RP Nested")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [RequestPageHandler]
    procedure ToSiblingsHandler(var RP: TestRequestPage "LT TO RP Siblings")
    begin
        RP.SaveAsXml(ParametersFile, DataFile);
    end;

    [Test]
    [HandlerFunctions('ToNestedHandler')]
    procedure TO_SaveAsXml_Nested_Schema()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        // Writer TO: a parent data item with a linked child data item below it.
        ToSeed();
        Report.Run(Report::"LT TO RP Nested");
        ToSplit(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('bom', Format(HadBom));
        Observer.Observe('schema', Schema);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ToNestedHandler')]
    procedure TO_SaveAsXml_Nested_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        ToSeed();
        Report.Run(Report::"LT TO RP Nested");
        ToSplit(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ToSiblingsHandler')]
    procedure TO_SaveAsXml_Siblings_Schema()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        // Writer TO: two data items side by side at the top level.
        ToSeed();
        Report.Run(Report::"LT TO RP Siblings");
        ToSplit(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('bom', Format(HadBom));
        Observer.Observe('schema', Schema);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ToSiblingsHandler')]
    procedure TO_SaveAsXml_Siblings_Rows()
    var
        Observer: Codeunit "Probe Observer";
        Schema: Text;
        Rows: Text;
        HadBom: Boolean;
    begin
        ToSeed();
        Report.Run(Report::"LT TO RP Siblings");
        ToSplit(FileText(DataFile, HadBom), Schema, Rows);
        Observer.Observe('rows', Rows);
        Observer.Finish();
    end;
}
