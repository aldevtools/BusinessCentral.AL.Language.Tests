//sub:report
// Report.SaveAs Xml dataset: header parents (md:204), DataItems rules (md:206), element names (md:208), data item identity (md:559).
// The reports have no layout; only Xml is saved. The header is read through an XmlDocument; values that differ per run are never observed.

report 67750 "W3 Hdr Plain"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
        }
    }
}

report 67751 "W3 Hdr Caption"
{
    ProcessingOnly = false;
    Caption = 'W3 Header Caption';

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Id; Id) { }
        }
    }
}

report 67752 "W3 Rows Rpt"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Parent; "W3 Row")
        {
            column(ParentId; Id) { }

            dataitem(ChildA; "W3 Child")
            {
                DataItemLink = ParentId = field(Id);

                column(ChildAId; Id) { }
            }
        }
        dataitem(Sibling; "W3 Child")
        {
            column(SiblingId; Id) { }
        }
    }
}

report 67753 "W3 Names Cols"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "W3 Row")
        {
            column(Plain_Name1; Id) { }
            column("Café"; Id) { }
            column("Ünï"; Id) { }
            column(Trail_; Id) { }
            column(Dbl__Under; Id) { }
            column(UPPERCASE; Id) { }
            column(lowercase; Id) { }
            column(Mixed1Case2; Id) { }
            column("Ωmega"; Id) { }
            column(N123; Id) { }
        }
    }
}

report 67754 "W3 Names Items"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem("My Item (x)"; "W3 Row")
        {
            column(Id; Id) { }

            dataitem("Child-Item.1"; "W3 Child")
            {
                DataItemLink = ParentId = field(Id);

                column(Id2; Id) { }
            }
        }
        dataitem("2nd item"; "W3 Child")
        {
            column(Id3; Id) { }
        }
        dataitem("Q&A <x>/y"; "W3 Marker")
        {
            column(Id4; Id) { }
        }
        dataitem("Ünï item"; "W3 Param")
        {
            column(Id5; Id) { }
        }
    }
}

codeunit 67755 "W3 Dataset Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Dataset: Codeunit "W3 Dataset";
        Runner: Codeunit "W3 Runner";

    local procedure Seed(WithRows: Boolean; WithChildren: Boolean)
    var
        Row: Record "W3 Row";
        Child: Record "W3 Child";
    begin
        Row.DeleteAll();
        Child.DeleteAll();
        if WithRows then begin
            Row.Id := 1;
            Row.Name := 'one';
            Row.Insert();
            Row.Id := 2;
            Row.Name := 'two';
            Row.Insert();
        end;
        if WithChildren then begin
            Child.Id := 1;
            Child.ParentId := 1;
            Child.Insert();
            Child.Id := 2;
            Child.ParentId := 1;
            Child.Insert();
        end;
        Commit();
    end;

    [TryFunction]
    local procedure TrySave(var Xml: Text)
    begin
        Dataset.Save(Report::"W3 Hdr Plain", '', Xml);
    end;

    // md:204: parents of the header elements (the order of the names is pinned elsewhere), and the stable values.
    [Test]
    procedure Header_Values_ReportWithCaption()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed(true, false);
        Observer.Observe('saved', Format(Dataset.Save(Report::"W3 Hdr Caption", '', Xml)));
        Observer.Observe('ReportName', Dataset.HeaderValue(Xml, 'ReportName'));
        Observer.Observe('ReportCaption', Dataset.HeaderValue(Xml, 'ReportCaption'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('ReportName', 'W3 Hdr Caption');
#if BC29PLUS
        Observer.Expect('ReportCaption', 'W3 Header Caption');
#else
        Observer.Expect('ReportCaption', '<absent>');
#endif
        Observer.Verify();
    end;

    // md:204: a company information record. The record is changed and put back; the session company stays the same.
    [Test]
    procedure Header_CompanyInformation_NameAndAddress()
    var
        Observer: Codeunit "Probe Observer";
        CompanyInformation: Record "Company Information";
        OldName: Text[100];
        OldAddress: Text[100];
        Existed: Boolean;
        Ok: Boolean;
        Xml: Text;
    begin
        Seed(true, false);
        Existed := CompanyInformation.Get();
        if not Existed then
            CompanyInformation.Insert();
        OldName := CompanyInformation.Name;
        OldAddress := CompanyInformation.Address;
        CompanyInformation.Name := 'W3 Probe Company';
        CompanyInformation.Address := 'W3 Probe Street 1';
        CompanyInformation.Modify();
        Ok := TrySave(Xml);
        Observer.Observe('saved without an error', Format(Ok));
        Observer.ObserveError('save');
        Observer.Observe('CompanyName is the session company', Format(Dataset.HeaderValue(Xml, 'CompanyName') = CompanyName()));
        Observer.Observe('CompanyName is the information name', Format(Dataset.HeaderValue(Xml, 'CompanyName') = 'W3 Probe Company'));
        Observer.Observe('CompanyDisplayName is the information name', Format(Dataset.HeaderValue(Xml, 'CompanyDisplayName') = 'W3 Probe Company'));
        Observer.Observe('CompanyAddressLine1', Dataset.HeaderValue(Xml, 'CompanyAddressLine1'));
        CompanyInformation.Name := OldName;
        CompanyInformation.Address := OldAddress;
        CompanyInformation.Modify();
        Observer.Expect('saved without an error', 'Yes');
        Observer.Expect('save|text', '');
        Observer.Expect('save|code', '');
        Observer.Expect('CompanyName is the session company', 'Yes');
        Observer.Expect('CompanyName is the information name', 'No');
        Observer.Expect('CompanyDisplayName is the information name', 'No');
#if BC29PLUS
        Observer.Expect('CompanyAddressLine1', 'W3 Probe Company');
#else
        Observer.Expect('CompanyAddressLine1', '<absent>');
#endif
        Observer.Verify();
    end;

    // md:204: line ends, indentation and the empty element form of the raw text.
    [Test]
    procedure Header_RawText_LineEndsAndIndentation()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        B: Byte;
        Count: Integer;
        Crs: Integer;
        Lfs: Integer;
        LastByte: Byte;
        Xml: Text;
        Line: Text;
        Lines: List of [Text];
        Shown: Text;
        Index: Integer;
        Indent: Integer;
        QkRows: Codeunit "LT QK Setup Rows";
    begin
        Seed(true, false);
        // Writer QK (owner 2026-10-21): the header's company block (and so where the first 4000 bytes end) comes from a Company
        // Information row the test writes (QkSetupRows.al), not from the demo row.
        QkRows.WriteCompanyInformation();
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"W3 Hdr Plain", '', ReportFormat::Xml, OutS);
        QkRows.RestoreCompanyInformation();
        TempBlob.CreateInStream(InS);
        while (not InS.EOS()) and (Count < 4000) do begin
            InS.Read(B);
            Count += 1;
            if B = 13 then
                Crs += 1;
            if B = 10 then
                Lfs += 1;
        end;
        Observer.Observe('CR bytes in the first 4000', Format(Crs));
        Observer.Observe('LF bytes in the first 4000 > 0', Format(Lfs > 0));
        Xml := Dataset.ReadAll(TempBlob);
        Lines := Xml.Split(Dataset.Lf());
        for Index := 2 to 9 do begin
            Line := Lines.Get(Index);
            Indent := StrLen(Line) - StrLen(Line.TrimStart());
            Shown += Format(Indent) + ':' + CopyStr(Line.TrimStart(), 1, Line.TrimStart().IndexOf('>')) + '|';
        end;
        Observer.Observe('indent and tag of lines 2 to 9', Shown);
#if BC29PLUS
        Observer.Expect('CR bytes in the first 4000', '75');
#else
        Observer.Expect('CR bytes in the first 4000', '46');
#endif
        Observer.Expect('LF bytes in the first 4000 > 0', 'Yes');
        Observer.Ignore('indent and tag of lines 2 to 9'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    // md:206: DataItems with no rows at all, a parent without child rows, and the attribute names of DataItem.
    [Test]
    procedure Rows_NoRowsAtAll()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed(false, false);
        Observer.Observe('saved', Format(Dataset.Save(Report::"W3 Rows Rpt", '', Xml)));
        Observer.Observe('structure', Dataset.Tokens(Xml));
        Observer.Observe('attributes', Dataset.ItemAttributes(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('structure', 'DIs');
        Observer.Expect('attributes', '');
        Observer.Verify();
    end;

    [Test]
    procedure Rows_ParentsWithoutChildRows()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed(true, false);
        Observer.Observe('saved', Format(Dataset.Save(Report::"W3 Rows Rpt", '', Xml)));
        Observer.Observe('structure', Dataset.Tokens(Xml));
        Observer.Observe('attributes', Dataset.ItemAttributes(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('structure', 'DIs DI c:ParentId DIs /DI DI c:ParentId DIs /DI /DIs');
#if BC28PLUS
        Observer.Expect('attributes', '[language,formatRegion,name,tableId,systemId] [language,formatRegion,name,tableId,systemId]');
#else
        Observer.Expect('attributes', '[language,formatRegion,name] [language,formatRegion,name]');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Rows_ParentsWithChildRowsAndSiblingItem()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
    begin
        Seed(true, true);
        Observer.Observe('saved', Format(Dataset.Save(Report::"W3 Rows Rpt", '', Xml)));
        Observer.Observe('structure', Dataset.Tokens(Xml));
        Observer.Observe('attributes', Dataset.ItemAttributes(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('structure', 'DIs DI c:ParentId DIs DI c:ChildAId /DI DI c:ChildAId /DI /DIs /DI DI c:ParentId DIs /DI DI c:SiblingId /DI DI c:SiblingId /DI /DIs');
#if BC28PLUS
        Observer.Expect('attributes', '[language,formatRegion,name,tableId,systemId] [name,tableId,systemId] [name,tableId,systemId] [language,formatRegion,name,tableId,systemId] [language,formatRegion,name,tableId,systemId] [language,formatRegion,name,tableId,systemId]');
#else
        Observer.Expect('attributes', '[language,formatRegion,name] [name] [name] [language,formatRegion,name] [language,formatRegion,name] [language,formatRegion,name]');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Rows_OnlyTheSiblingItemHasRows()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "W3 Child";
        Xml: Text;
    begin
        Seed(false, false);
        Child.Id := 7;
        Child.ParentId := 99;
        Child.Insert();
        Commit();
        Observer.Observe('saved', Format(Dataset.Save(Report::"W3 Rows Rpt", '', Xml)));
        Observer.Observe('structure', Dataset.Tokens(Xml));
        Observer.Observe('attributes', Dataset.ItemAttributes(Xml));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('structure', 'DIs DI c:SiblingId /DI /DIs');
#if BC28PLUS
        Observer.Expect('attributes', '[language,formatRegion,name,tableId,systemId]');
#else
        Observer.Expect('attributes', '[language,formatRegion,name]');
#endif
        Observer.Verify();
    end;

    // md:208: names of columns and data items.
    [Test]
    procedure Names_ColumnsWithSpacesPunctuationAndLetters()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Line: Text;
        Names: Text;
    begin
        Seed(true, false);
        Observer.Observe('saved', Format(Dataset.Save(Report::"W3 Names Cols", '', Xml)));
        foreach Line in Xml.Split(Dataset.Lf()) do begin
            Line := Line.Trim();
            if Line.StartsWith('<Column name="') then
                Names += Dataset.Between(Line, 'name="', '"') + '|';
        end;
        Observer.Observe('names', Names);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('names', 'Plain_Name1|Café|Ünï|Trail_|Dbl__Under|UPPERCASE|lowercase|Mixed1Case2|Ωmega|N123|Plain_Name1|Café|Ünï|Trail_|Dbl__Under|UPPERCASE|lowercase|Mixed1Case2|Ωmega|N123|');
        Observer.Verify();
    end;

    [Test]
    procedure Names_DataItemsWithSpacesAndPunctuation()
    var
        Observer: Codeunit "Probe Observer";
        Xml: Text;
        Line: Text;
        Names: Text;
    begin
        Seed(true, true);
        Observer.Observe('saved', Format(Dataset.Save(Report::"W3 Names Items", '', Xml)));
        foreach Line in Xml.Split(Dataset.Lf()) do begin
            Line := Line.Trim();
            if Line.StartsWith('<DataItem ') then
                Names += Dataset.Between(Line, 'name="', '"') + '|';
        end;
        Observer.Observe('data item names', Names);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('data item names', 'My_Item_x|Child_Item_1|Child_Item_1|My_Item_x|_x0032_nd_item|_x0032_nd_item|');
        Observer.Verify();
    end;

    // md:559: tableId and the GUID of each DataItem against the table id and the SystemId of the row.
    [Test]
    procedure Identity_DataItemGuid_IsTheSystemIdOfTheRow()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W3 Row";
        Child: Record "W3 Child";
        Xml: Text;
        Guid1: Text;
        Guid2: Text;
        Guid3: Text;
        Guid4: Text;
    begin
        Seed(true, true);
        Dataset.Save(Report::"W3 Rows Rpt", '', Xml);
        Observer.Observe('attributes', Dataset.ItemAttributes(Xml));
        Row.Get(1);
        Guid1 := LowerCase(DelChr(Format(Row.SystemId), '=', '{}'));
        Child.Get(1);
        Guid2 := LowerCase(DelChr(Format(Child.SystemId), '=', '{}'));
        Child.Get(2);
        Guid3 := LowerCase(DelChr(Format(Child.SystemId), '=', '{}'));
        Row.Get(2);
        Guid4 := LowerCase(DelChr(Format(Row.SystemId), '=', '{}'));
        Observer.Observe('item 1 tableId is the table', Format(Dataset.ItemAttribute(Xml, 1, 'tableId') = Format(Database::"W3 Row")));
        Observer.Observe('item 1 GUID is the SystemId of row 1', Format(Dataset.ItemAttribute(Xml, 1, 'systemId') = Guid1));
        Observer.Observe('item 2 GUID is the SystemId of child 1', Format(Dataset.ItemAttribute(Xml, 2, 'systemId') = Guid2));
        Observer.Observe('item 3 GUID is the SystemId of child 2', Format(Dataset.ItemAttribute(Xml, 3, 'systemId') = Guid3));
        Observer.Observe('item 4 GUID is the SystemId of row 2', Format(Dataset.ItemAttribute(Xml, 4, 'systemId') = Guid4));
#if BC28PLUS
        Observer.Expect('attributes', '[language,formatRegion,name,tableId,systemId] [name,tableId,systemId] [name,tableId,systemId] [language,formatRegion,name,tableId,systemId] [language,formatRegion,name,tableId,systemId] [language,formatRegion,name,tableId,systemId]');
#else
        Observer.Expect('attributes', '[language,formatRegion,name] [name] [name] [language,formatRegion,name] [language,formatRegion,name] [language,formatRegion,name]');
#endif
#if BC28PLUS
        Observer.Expect('item 1 tableId is the table', 'Yes');
#else
        Observer.Expect('item 1 tableId is the table', 'No');
#endif
#if BC28PLUS
        Observer.Expect('item 1 GUID is the SystemId of row 1', 'Yes');
#else
        Observer.Expect('item 1 GUID is the SystemId of row 1', 'No');
#endif
#if BC28PLUS
        Observer.Expect('item 2 GUID is the SystemId of child 1', 'Yes');
#else
        Observer.Expect('item 2 GUID is the SystemId of child 1', 'No');
#endif
#if BC28PLUS
        Observer.Expect('item 3 GUID is the SystemId of child 2', 'Yes');
#else
        Observer.Expect('item 3 GUID is the SystemId of child 2', 'No');
#endif
#if BC28PLUS
        Observer.Expect('item 4 GUID is the SystemId of row 2', 'Yes');
#else
        Observer.Expect('item 4 GUID is the SystemId of row 2', 'No');
#endif
        Observer.Verify();
    end;
#if BC29PLUS
    // Writer PW: the raw text of the "W3 Hdr Plain" dataset split at line feeds (a CR shows as \r), the lines Header_RawText_LineEndsAndIndentation
    // counts CR bytes in. failure-triage "dataset raw line counts" (67755 Header_RawText_LineEndsAndIndentation).
    // A line longer than 200 characters (the base64 company logo) is shown as its first 40 characters and its length.
    local procedure PwShort(Line: Text): Text
    begin
        if StrLen(Line) <= 200 then
            exit(Line);
        exit(CopyStr(Line, 1, 40) + '...<length ' + Format(StrLen(Line)) + '>');
    end;

    local procedure PwDumpPlain(First: Integer; Last: Integer; var Observer: Codeunit "Probe Observer")
    var
        Xml: Text;
        Lines: List of [Text];
        i: Integer;
        QkRows: Codeunit "LT QK Setup Rows";
    begin
        Seed(true, false);
        // Writer QK (owner 2026-10-21): the company block comes from a Company Information row the test writes (QkSetupRows.al).
        QkRows.WriteCompanyInformation();
        Dataset.Save(Report::"W3 Hdr Plain", '', Xml);
        QkRows.RestoreCompanyInformation();
        Lines := Xml.Split(Dataset.Lf());
        Observer.Observe('lines', Format(Lines.Count()));
        for i := First to Last do
            if i <= Lines.Count() then
                Observer.Observe('l' + Format(i), PwShort(Lines.Get(i)));
    end;

    [Test]
    procedure PW_DumpPlain_Lines01To18()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwDumpPlain(1, 18, Observer);
        Observer.Expect('lines', '88');
        Observer.Expect('l1', '<?xml version="1.0" standalone="yes"?>');
        Observer.Expect('l2', '<ReportDataSet name="W3 Hdr Plain" id="67750" language="en-US" formatRegion="en-US">');
        Observer.Expect('l3', '  <BCReportInformation>x');
        Observer.Expect('l4', '    <ReportMetadata>');
        Observer.Expect('l5', '      <ExtensionId>a1b2c3d4-e5f6-7890-abcd-ef1234567890</ExtensionId>');
        Observer.Expect('l6', '      <ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>');
        Observer.Expect('l7', '      <ExtensionPublisher>AL Language</ExtensionPublisher>');
        Observer.Expect('l8', '      <ExtensionVersion>x</ExtensionVersion>');
        Observer.Expect('l9', '      <ReportId>67750</ReportId>');
        Observer.Expect('l10', '      <ReportName>W3 Hdr Plain</ReportName>');
        Observer.Expect('l11', '      <ReportCaption>W3 Hdr Plain</ReportCaption>');
        Observer.Expect('l12', '      <AboutThisReportTitle></AboutThisReportTitle>');
        Observer.Expect('l13', '      <AboutThisReportText></AboutThisReportText>');
        Observer.Expect('l14', '      <ReportHelpLink></ReportHelpLink>');
        Observer.Expect('l15', '    </ReportMetadata>');
        Observer.Expect('l16', '    <ReportRequest>');
        Observer.Expect('l17', '      <TenantEntraId>x</TenantEntraId>');
        Observer.Expect('l18', '      <EnvironmentName>x</EnvironmentName>');
        Observer.Verify();
    end;

    [Test]
    procedure PW_DumpPlain_Lines19To36()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwDumpPlain(19, 36, Observer);
        Observer.Expect('lines', '88');
        Observer.Expect('l19', '      <EnvironmentType>x</EnvironmentType>');
        Observer.Expect('l20', '      <CompanyName>x</CompanyName>');
        Observer.Expect('l21', '      <CompanyDisplayName>x</CompanyDisplayName>');
        Observer.Expect('l22', '      <CompanyId>x</CompanyId>');
        Observer.Expect('l23', '      <UserName>x</UserName>');
        Observer.Expect('l24', '      <DateAndTime>x</DateAndTime>');
        Observer.Expect('l25', '      <Language>en-US</Language>');
        Observer.Expect('l26', '      <FormatRegion>en-US</FormatRegion>');
        Observer.Expect('l27', '      <DateTimeValues>');
        Observer.Expect('l28', '        <Year>x</Year>');
        Observer.Expect('l29', '        <MonthNumber>x</MonthNumber>');
        Observer.Expect('l30', '        <DayNumber>x</DayNumber>');
        Observer.Expect('l31', '        <Hour>x</Hour>');
        Observer.Expect('l32', '        <Minute>x</Minute>');
        Observer.Expect('l33', '      </DateTimeValues>');
        Observer.Expect('l34', '    </ReportRequest>');
        Observer.Expect('l35', '    <CompanyMetadata>');
        Observer.Expect('l36', '      <CompanyName>x</CompanyName>');
        Observer.Verify();
    end;

    [Test]
    procedure PW_DumpPlain_Lines37To54()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwDumpPlain(37, 54, Observer);
        Observer.Expect('lines', '88');
        Observer.Expect('l37', '      <CompanyDisplayName>x</CompanyDisplayName>');
        Observer.Expect('l38', '      <CompanyAddressLines>');
        Observer.Expect('l39', '        <CompanyAddressLine1>LT QK Company</CompanyAddressLine1>');
        Observer.Expect('l40', '        <CompanyAddressLine2>QK Street 1</CompanyAddressLine2>');
        Observer.Expect('l41', '        <CompanyAddressLine3>QK Floor 2</CompanyAddressLine3>');
        Observer.Expect('l42', '        <CompanyAddressLine4>QK Town, QK-1234</CompanyAddressLine4>');
        Observer.Expect('l43', '        <CompanyAddressLine5>LT QK Land</CompanyAddressLine5>');
        Observer.Expect('l44', '        <CompanyAddressLine6></CompanyAddressLine6>');
        Observer.Expect('l45', '        <CompanyAddressLine7></CompanyAddressLine7>');
        Observer.Expect('l46', '        <CompanyAddressLine8></CompanyAddressLine8>');
        Observer.Expect('l47', '      </CompanyAddressLines>');
        Observer.Expect('l48', '      <CompanyPhone>0111-222-3333</CompanyPhone>');
        Observer.Expect('l49', '      <CompanyPhoneCaption>Phone No.</CompanyPhoneCaption>');
        Observer.Expect('l50', '      <CompanyFaxNo>0111-222-3334</CompanyFaxNo>');
        Observer.Expect('l51', '      <CompanyFaxNoCaption>Fax No.</CompanyFaxNoCaption>');
        Observer.Expect('l52', '      <CompanyEmail>qk@example.com</CompanyEmail>');
        Observer.Expect('l53', '      <CompanyEmailCaption>Email</CompanyEmailCaption>');
        Observer.Expect('l54', '      <CompanyHomePage>www.example.com/qk</CompanyHomePage>');
        Observer.Verify();
    end;

    [Test]
    procedure PW_DumpPlain_Lines55To72()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PwDumpPlain(55, 72, Observer);
        Observer.Expect('lines', '88');
        Observer.Expect('l55', '      <CompanyHomePageCaption>Home Page</CompanyHomePageCaption>');
        Observer.Expect('l56', '      <CompanyLogo>iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==</CompanyLogo>');
        Observer.Expect('l57', '      <CompanyVATRegistrationNo>QK123456789</CompanyVATRegistrationNo>');
        Observer.Expect('l58', '      <CompanyVATRegistrationNoCaption>VAT Registration No.</CompanyVATRegistrationNoCaption>');
        Observer.Expect('l59', '      <CompanyRegistrationNo>QKREG42</CompanyRegistrationNo>');
        Observer.Expect('l60', '      <CompanyRegistrationNoCaption>Registration No.</CompanyRegistrationNoCaption>');
        Observer.Expect('l61', '      <CompanyBankName>LT QK Bank</CompanyBankName>');
        Observer.Expect('l62', '      <CompanyBankNameCaption>Bank Name</CompanyBankNameCaption>');
        Observer.Expect('l63', '      <CompanyBankAccountNo>11-22-333</CompanyBankAccountNo>');
        Observer.Expect('l64', '      <CompanyBankAccountNoCaption>Bank Account No.</CompanyBankAccountNoCaption>');
        Observer.Expect('l65', '      <CompanyBankBranchNo>QKB777</CompanyBankBranchNo>');
        Observer.Expect('l66', '      <CompanyBankBranchNoCaption>Bank Branch No.</CompanyBankBranchNoCaption>');
        Observer.Expect('l67', '      <CompanyIBAN>QK 11 BANK 22223333444455</CompanyIBAN>');
        Observer.Expect('l68', '      <CompanyIBANCaption>IBAN</CompanyIBANCaption>');
        Observer.Expect('l69', '      <CompanyBankSWIFT>QKBKXX22</CompanyBankSWIFT>');
        Observer.Expect('l70', '      <CompanyBankSWIFTCaption>SWIFT Code</CompanyBankSWIFTCaption>');
        Observer.Expect('l71', '      <CompanyGiroNo>123-4567</CompanyGiroNo>');
        Observer.Expect('l72', '      <CompanyGiroNoCaption>Giro No.</CompanyGiroNoCaption>');
        Observer.Verify();
    end;
#endif

}
