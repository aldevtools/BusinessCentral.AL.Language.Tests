// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: ALTFixtureCleanup (60019), shared Assert (60021); self-contained tables 68300, 68301,
//                report 68302 and codeunit 68303
// Probe: written against a real BC 27.5 service tier on Linux (en-US); every literal below is what that
// tier produced. Other BC versions were not measured.
//
// Pins the dataset XML that Report.SaveAs(.., ReportFormat::Xml, ..) writes for a report with two nested
// data items: the byte order mark and declaration, the order of the header elements (their values depend
// on the app, the company, the user and the clock and are not compared), and the exact DataItems block
// (column elements in order, text escaped, Decimal with a decimalformatter attribute, Date as m/d/yyyy,
// Boolean as True, a nested item repeated once per child). Also pins that a parameters string with a
// filter narrows the dataset and the text RunRequestPage returns, and the Html refusal.
//
// NOT pinned on purpose: Pdf, Word and Excel. On this Linux container every one of them returns false
// with an empty stream and the error text "RDLC report rendering is not implemented on Linux BC ...",
// which is a limit of the container and not BC behaviour. "Report_SaveAs_Pdf_ReturnValueAgreesWithTheBytesInTheStream"
// (handlers/TestReportSaveAsPdfContent.al) accepts both outcomes.
// BC 29.0 adds ReportCaption and a company information block to the header (see the header test).
// BC 28.5 adds ` tableId="<table id>" systemId="<guid>"` to every DataItem element (27.5 does not). The exact-text
// test removes that pair before comparing; one test checks the pair's shape where it is present.
// BC versions: 27.5, 28.5, 29.0

table 68300 "Probe Rep Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
        field(5; B; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 68301 "Probe Rep Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ParentId; Integer) { }
        field(3; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 68302 "Probe SaveAs Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(P; "Probe Rep Parent")
        {
            column(PNo; Id) { }
            column(PName; Name) { }
            column(PAmt; Amt) { }
            column(PDate; D) { }
            column(PBool; B) { }

            dataitem(C; "Probe Rep Child")
            {
                DataItemLink = ParentId = field(Id);

                column(CNo; Id) { }
                column(CCode; Code) { }
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(Prefix; Prefix) { ApplicationArea = All; }
                }
            }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSaveAsDatasetLayout.rdl';
            Caption = 'Probe layout';
        }
    }

    var
        Prefix: Text;
}

codeunit 68303 "Probe Report SaveAs Dataset"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    var
        Parent: Record "Probe Rep Parent";
        Child: Record "Probe Rep Child";
    begin
        Cleanup.Initialize();
        Child.DeleteAll();
        Parent.DeleteAll();
        Parent.Init();
        Parent.Id := 1;
        Parent.Name := 'one <&>';
        Parent.Amt := 12.5;
        Parent.D := DMY2Date(5, 3, 2024);
        Parent.B := true;
        Parent.Insert();
        Parent.Init();
        Parent.Id := 2;
        Parent.Name := 'two';
        Parent.Insert();
        Child.Init();
        Child.Id := 10;
        Child.ParentId := 1;
        Child.Code := 'a';
        Child.Insert();
        Child.Id := 11;
        Child.Insert();
        Child.Id := 12;
        Child.ParentId := 2;
        Child.Code := 'c';
        Child.Insert();
        Commit();
    end;

    local procedure DatasetLines(Parameters: Text; var Lines: List of [Text]; var HasBom: Boolean): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        First: Byte;
        Second: Byte;
        Third: Byte;
        Saved: Boolean;
    begin
        TempBlob.CreateOutStream(OutStr);
        Saved := Report.SaveAs(Report::"Probe SaveAs Report", Parameters, ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr);
        InStr.Read(First);
        InStr.Read(Second);
        InStr.Read(Third);
        HasBom := (First = 239) and (Second = 187) and (Third = 191);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Lines.Add(Line);
        end;
        exit(Saved);
    end;

    local procedure StripIdentity(Block: Text; var Identities: List of [Text]): Text
    var
        StartAt: Integer;
        EndAt: Integer;
        Marker: Text;
        Rest: Text;
        Result: Text;
    begin
        // BC 28.5 writes ` tableId="<table id>" systemId="<guid>"` after name="..." on every
        // DataItem element; BC 27.5 does not. The GUID differs per record, so the exact-text test removes
        // the pair (remembering it) and a separate test checks what the pair says.
        Marker := ' tableId="';
        Rest := Block;
        while Rest.Contains(Marker) do begin
            StartAt := Rest.IndexOf(Marker);
            EndAt := Rest.IndexOf('" systemId="');
            EndAt := EndAt + StrLen('" systemId="');
            EndAt := EndAt + Rest.Substring(EndAt).IndexOf('"') - 1;
            Identities.Add(Rest.Substring(StartAt + 1, EndAt - StartAt));
            Result += Rest.Substring(1, StartAt - 1);
            Rest := Rest.Substring(EndAt + 1);
        end;
        exit(Result + Rest);
    end;

    local procedure TailFrom(Lines: List of [Text]; Marker: Text): Text
    var
        Line: Text;
        Result: Text;
        Started: Boolean;
    begin
        foreach Line in Lines do begin
            if Line.Trim() = Marker then
                Started := true;
            if Started then
                Result += Line + '|';
        end;
        exit(Result);
    end;

    [Test]
    procedure SaveAs_Xml_WritesAByteOrderMarkDeclarationAndHeader()
    var
        Lines: List of [Text];
        HasBom: Boolean;
        Tags: Text;
        Line: Text;
    begin
        Initialize();

        Assert.IsTrue(DatasetLines('', Lines, HasBom), 'SaveAs returns true');

        Assert.IsTrue(HasBom, 'UTF-8 byte order mark');
        Assert.AreEqual('<?xml version="1.0" standalone="yes"?>', Lines.Get(1).TrimStart(), 'declaration');
        Assert.AreEqual('<ReportDataSet name="Probe SaveAs Report" id="68302" language="en-US" formatRegion="en-US">', Lines.Get(2), 'root');
        foreach Line in Lines do begin
            if Line.Trim() = '<DataItems>' then
                break;
            if Line.Trim().StartsWith('<') and not Line.Trim().StartsWith('</') and Line.Contains('</') then
                Tags += Line.Trim().Substring(2, Line.Trim().IndexOf('>') - 2) + ' ';
        end;
#if BC29PLUS
        // BC 29.0 adds ReportCaption after ReportName and, after Minute, the whole company information block.
        Assert.AreEqual('ExtensionId ExtensionName ExtensionPublisher ExtensionVersion ReportId ReportName ReportCaption AboutThisReportTitle AboutThisReportText ReportHelpLink TenantEntraId EnvironmentName EnvironmentType CompanyName CompanyDisplayName CompanyId UserName DateAndTime Language FormatRegion Year MonthNumber DayNumber Hour Minute CompanyName CompanyDisplayName CompanyAddressLine1 CompanyAddressLine2 CompanyAddressLine3 CompanyAddressLine4 CompanyAddressLine5 CompanyAddressLine6 CompanyAddressLine7 CompanyAddressLine8 CompanyPhone CompanyPhoneCaption CompanyFaxNo CompanyFaxNoCaption CompanyEmail CompanyEmailCaption CompanyHomePage CompanyHomePageCaption CompanyLogo CompanyVATRegistrationNo CompanyVATRegistrationNoCaption CompanyRegistrationNo CompanyRegistrationNoCaption CompanyBankName CompanyBankNameCaption CompanyBankAccountNo CompanyBankAccountNoCaption CompanyBankBranchNo CompanyBankBranchNoCaption CompanyIBAN CompanyIBANCaption CompanyBankSWIFT CompanyBankSWIFTCaption CompanyGiroNo CompanyGiroNoCaption ', Tags, 'header elements in order');
#else
        Assert.AreEqual('ExtensionId ExtensionName ExtensionPublisher ExtensionVersion ReportId ReportName AboutThisReportTitle AboutThisReportText ReportHelpLink TenantEntraId EnvironmentName EnvironmentType CompanyName CompanyDisplayName CompanyId UserName DateAndTime Language FormatRegion Year MonthNumber DayNumber Hour Minute ', Tags, 'header elements in order');
#endif
        Assert.IsTrue(TailFrom(Lines, '<ReportName>Probe SaveAs Report</ReportName>') <> '', 'report name element');
        Assert.IsTrue(TailFrom(Lines, '<CompanyName>' + CompanyName() + '</CompanyName>') <> '', 'company name element');
    end;

    [Test]
    procedure SaveAs_Xml_DataItemIdentity_IsAbsentOrAPairOfTableIdAndGuid()
    // CLAIM: where the dataset carries tableId and systemId on a DataItem (the 28.5 run does, the 27.5 run does not), all five data items have the pair, in document order parent, child, child, parent, child; the tableId is the id of the table and the systemId is a 36 character GUID in lower case, different for every item. Whether it equals the SystemId of the record is NOT pinned (not measured).
    var
        Lines: List of [Text];
        Identities: List of [Text];
        HasBom: Boolean;
        Identity: Text;
        Seen: Text;
        TableIds: Text;
        Guid: Text;
    begin
        Initialize();

        DatasetLines('', Lines, HasBom);
        StripIdentity(TailFrom(Lines, '<DataItems>'), Identities);

        if Identities.Count() = 0 then
            exit;
        Assert.AreEqual(5, Identities.Count(), 'two parents and three children');
        foreach Identity in Identities do begin
            Assert.IsTrue(Identity.StartsWith('tableId="'), 'starts with the table id');
            Guid := Identity.Substring(Identity.IndexOf('systemId="') + StrLen('systemId="'));
            Guid := CopyStr(Guid, 1, StrLen(Guid) - 1);
            Assert.AreEqual(36, StrLen(Guid), 'GUID length');
            Assert.AreEqual(LowerCase(Guid), Guid, 'lower case');
            Assert.IsFalse(Seen.Contains(Guid), 'different per item');
            Seen += Guid + ';';
            TableIds += Identity.Substring(10, 5) + ';';
        end;
        Assert.AreEqual('68300;68301;68301;68300;68301;', TableIds, 'table ids in document order');
    end;

    [Test]
    procedure SaveAs_Xml_DataItemIdentity_PresenceFollowsTheVersion()
    // CLAIM: the tableId/systemId pair is on every DataItem (five here) where BC28PLUS is defined and on none below. Measured: absent on 27.5, present on 28.5 and 29.0; 28.0 to 28.4 were not measured, so a failure there says where the change came in.
    var
        Lines: List of [Text];
        Identities: List of [Text];
        HasBom: Boolean;
    begin
        Initialize();

        DatasetLines('', Lines, HasBom);
        StripIdentity(TailFrom(Lines, '<DataItems>'), Identities);

#if BC28PLUS
        Assert.AreEqual(5, Identities.Count(), 'a pair on each of the five data items');
#else
        Assert.AreEqual(0, Identities.Count(), 'no pair before BC 28');
#endif
    end;

    [Test]
    procedure SaveAs_Xml_StripIdentity_RemovesThePairAndKeepsTheRest()
    var
        Identities: List of [Text];
    begin
        Assert.AreEqual('<DataItem name="P"><DataItem name="C">|', StripIdentity('<DataItem name="P" tableId="68300" systemId="8ce4b684-f247-43d2-dbc5-d26d1287b536"><DataItem name="C" tableId="68301" systemId="989abfd4-0121-21b3-4c6d-ae779cc56594">|', Identities), 'text');
        Assert.AreEqual(2, Identities.Count(), 'count');
        Assert.AreEqual('tableId="68301" systemId="989abfd4-0121-21b3-4c6d-ae779cc56594"', Identities.Get(2), 'second pair');
    end;

    [Test]
    procedure SaveAs_Xml_DataItemsBlock_ExactText()
    var
        Lines: List of [Text];
        HasBom: Boolean;
        Block: Text;
        Part1Text: Text;
        Part2Text: Text;
        Identities: List of [Text];
    begin
        Initialize();

        DatasetLines('', Lines, HasBom);

        Block := StripIdentity(TailFrom(Lines, '<DataItems>'), Identities);
        Part1Text := '  <DataItems>|' +
            '    <DataItem language="en-US" formatRegion="en-US" name="P">|' +
            '      <Columns>|' +
            '        <Column name="PNo">1</Column>|' +
            '        <Column name="PName">one &lt;&amp;&gt;</Column>|' +
            '        <Column name="PAmt" decimalformatter="#,##0.00">12.5</Column>|' +
            '        <Column name="PDate">3/5/2024</Column>|' +
            '        <Column name="PBool">True</Column>|' +
            '      </Columns>|' +
            '      <DataItems>|' +
            '        <DataItem name="C">|' +
            '          <Columns>|' +
            '            <Column name="CNo">10</Column>|' +
            '            <Column name="CCode">A</Column>|' +
            '          </Columns>|' +
            '        </DataItem>|' +
            '        <DataItem name="C">|' +
            '          <Columns>|' +
            '            <Column name="CNo">11</Column>|' +
            '            <Column name="CCode">A</Column>|' +
            '          </Columns>|' +
            '        </DataItem>|' +
            '      </DataItems>|' +
            '    </DataItem>|';
        Assert.AreEqual(Part1Text, CopyStr(Block, 1, StrLen(Part1Text)), 'first parent');
        Part2Text := '    <DataItem language="en-US" formatRegion="en-US" name="P">|' +
            '      <Columns>|' +
            '        <Column name="PNo">2</Column>|' +
            '        <Column name="PName">two</Column>|' +
            '        <Column name="PAmt" decimalformatter="#,##0.00">0</Column>|' +
            '        <Column name="PDate"></Column>|' +
            '        <Column name="PBool">False</Column>|' +
            '      </Columns>|' +
            '      <DataItems>|' +
            '        <DataItem name="C">|' +
            '          <Columns>|' +
            '            <Column name="CNo">12</Column>|' +
            '            <Column name="CCode">C</Column>|' +
            '          </Columns>|' +
            '        </DataItem>|' +
            '      </DataItems>|' +
            '    </DataItem>|' +
            '  </DataItems>|' +
            '</ReportDataSet>|';
        Assert.AreEqual(Part2Text, CopyStr(Block, StrLen(Part1Text) + 1), 'second parent and the end');
    end;

    [Test]
    [HandlerFunctions('RequestPageFiltersParent2')]
    procedure RunRequestPage_ReturnsTheParametersString_AndSaveAsHonoursItsFilter()
    var
        Lines: List of [Text];
        HasBom: Boolean;
        Parameters: Text;
        Block: Text;
    begin
        Initialize();

        Parameters := Report.RunRequestPage(Report::"Probe SaveAs Report");

        Assert.AreEqual('<?xml version="1.0" standalone="yes"?><ReportParameters name="Probe SaveAs Report" id="68302"><Options><Field name="Prefix">PFX</Field></Options><DataItems><DataItem name="P">VERSION(1) SORTING(Field1) WHERE(Field1=1(2))</DataItem><DataItem name="C">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>', Parameters, 'parameters string');

        Assert.IsTrue(DatasetLines(Parameters, Lines, HasBom), 'SaveAs with parameters returns true');
        Block := TailFrom(Lines, '<DataItems>');
        Assert.IsTrue(Block.Contains('<Column name="PNo">2</Column>'), 'parent 2 is in the dataset');
        Assert.IsFalse(Block.Contains('<Column name="PNo">1</Column>'), 'parent 1 is filtered out');
        Assert.IsTrue(Block.Contains('<Column name="CNo">12</Column>'), 'its child');
        Assert.IsFalse(Block.Contains('<Column name="CNo">10</Column>'), 'the other children are not there');
    end;

    [RequestPageHandler]
    procedure RequestPageFiltersParent2(var RequestPage: TestRequestPage "Probe SaveAs Report")
    begin
        RequestPage.Prefix.SetValue('PFX');
        RequestPage.P.SetFilter(Id, '2');
        RequestPage.OK().Invoke();
    end;

    [Test]
    procedure SaveAs_Html_WithAnRdlcLayout_IsRefused()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Initialize();
        TempBlob.CreateOutStream(OutStr);
        ClearLastError();

        Assert.IsFalse(Report.SaveAs(Report::"Probe SaveAs Report", '', ReportFormat::Html, OutStr), 'returns false');

        Assert.AreEqual('The Html output format is not supported by the current report layout format.', GetLastErrorText(), 'text');
        Assert.AreEqual(0, TempBlob.Length(), 'nothing written');
    end;
}
