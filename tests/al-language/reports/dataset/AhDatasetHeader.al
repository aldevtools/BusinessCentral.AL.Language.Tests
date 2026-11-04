// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own report 78602, codeunit 78603; LT QK Setup Rows (86940); writer QV: CompanyLogo tests (QV_*)
// Probe: the CompanyAddressLine1..8 elements of the report dataset header (SaveAs Xml, BC 29 and later) for several fillings of the
// Company Information address fields (Address, Address 2, City, Post Code, County, Country/Region Code). Only line 1 (= Name) was pinned before
// (corpus issue 636, item 3). The test restores the Company Information row it changed. Header_AddressLines_AsInCorpusDatabase writes its
// own row through codeunit 86940 "LT QK Setup Rows" (writer QK, 2026-10-21); the name is kept so the corpus case id stays.
// BC versions: 29+ (BC 27 and 28 write no company block in the header)

#if BC29PLUS
report 78602 "LT AH Header Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Num; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(Number; Number) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/AhDatasetHeaderLayout.rdl';
            Caption = 'LT AH layout';
        }
    }
}

codeunit 78603 "LT AH Dataset Header"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AddressLines(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
        Tag: Text;
        Index: Integer;
    begin
        TempBlob.CreateOutStream(OutStr);
        if not Report.SaveAs(Report::"LT AH Header Report", '', ReportFormat::Xml, OutStr) then
            exit('SaveAs returned false');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            for Index := 1 to 8 do begin
                Tag := 'CompanyAddressLine' + Format(Index);
                if Line.StartsWith('<' + Tag + '>') then
                    Result += Format(Index) + '=[' + Line.Substring(StrLen(Tag) + 3, StrLen(Line) - 2 * StrLen(Tag) - 5) + '] '
                else
                    if Line = '<' + Tag + ' />' then
                        Result += Format(Index) + '=[] ';
            end;
        end;
        exit(Result);
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Name: Text; Address: Text; Address2: Text; City: Text; PostCode: Text; County: Text; CountryCode: Code[10])
    var
        Info: Record "Company Information";
        Saved: Record "Company Information";
    begin
        Info.Get();
        Saved := Info;
        Info.Address := CopyStr(Address, 1, MaxStrLen(Info.Address));
        Info."Address 2" := CopyStr(Address2, 1, MaxStrLen(Info."Address 2"));
        Info.City := CopyStr(City, 1, MaxStrLen(Info.City));
        Info."Post Code" := CopyStr(PostCode, 1, MaxStrLen(Info."Post Code"));
        Info.County := CopyStr(County, 1, MaxStrLen(Info.County));
        Info."Country/Region Code" := CountryCode;
        Info.Modify();
        Observer.Observe(Name, AddressLines());
        Info.Get();
        Info.TransferFields(Saved, false);
        Info.Modify();
    end;

    [Test]
    procedure Header_AddressLines_AsInCorpusDatabase()
    var
        Observer: Codeunit "Probe Observer";
        QkRows: Codeunit "LT QK Setup Rows";
        Info: Record "Company Information";
    begin
        // Writer QK (owner 2026-10-21): the test writes its own Company Information row (QkSetupRows.al) instead of reading the demo row.
        QkRows.WriteCompanyInformation();
        Info.Get();
        Observer.Observe('db', Info.Name + '|' + Info.Address + '|' + Info."Address 2" + '|' + Info.City + '|' + Info."Post Code" + '|' + Info.County + '|' + Info."Country/Region Code");
        Observer.Observe('as_is', AddressLines());
        QkRows.RestoreCompanyInformation();
        Observer.Expect('db', 'LT QK Company|QK Street 1|QK Floor 2|QK Town|QK-1234||LTQK');
        Observer.Expect('as_is', '1=[LT QK Company] 2=[QK Street 1] 3=[QK Floor 2] 4=[QK Town, QK-1234] 5=[LT QK Land] 6=[] 7=[] 8=[] ');
        Observer.Verify();
    end;

    [Test]
    procedure Header_AddressLines_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Country: Record "Country/Region";
    begin
        if not Country.Get('AHX') then begin
            Country.Init();
            Country.Code := 'AHX';
            Country.Name := 'Ahland';
            Country.Insert();
        end;
        Run(Observer, 'all_filled_no_county', 'Street 1', 'Floor 2', 'Town', 'ZIP 12', '', '');
        Run(Observer, 'all_filled_county', 'Street 1', 'Floor 2', 'Town', 'ZIP 12', 'Countyshire', '');
        Run(Observer, 'country_code_only', 'Street 1', 'Floor 2', 'Town', 'ZIP 12', '', 'AHX');
        Run(Observer, 'all_five_filled', 'Street 1', 'Floor 2', 'Town', 'ZIP 12', 'Countyshire', 'AHX');
        Run(Observer, 'no_address2', 'Street 1', '', 'Town', 'ZIP 12', 'Countyshire', 'AHX');
        Observer.Expect('all_filled_no_county', '1=[<Company>] 2=[Street 1] 3=[Floor 2] 4=[ZIP 12 Town] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Expect('all_filled_county', '1=[<Company>] 2=[Street 1] 3=[Floor 2] 4=[ZIP 12 Town] 5=[Countyshire] 6=[] 7=[] 8=[] ');
        Observer.Expect('country_code_only', '1=[<Company>] 2=[Street 1] 3=[Floor 2] 4=[Town, ZIP 12] 5=[Ahland] 6=[] 7=[] 8=[] ');
        Observer.Expect('all_five_filled', '1=[<Company>] 2=[Street 1] 3=[Floor 2] 4=[Town, ZIP 12] 5=[Countyshire] 6=[Ahland] 7=[] 8=[] ');
        Observer.Expect('no_address2', '1=[<Company>] 2=[Street 1] 3=[Town, ZIP 12] 4=[Countyshire] 5=[Ahland] 6=[] 7=[] 8=[] ');
        Observer.Verify();
    end;

    [Test]
    procedure Header_AddressLines_PartlyFilled()
    var
        Observer: Codeunit "Probe Observer";
        Country: Record "Country/Region";
    begin
        if not Country.Get('AHX') then begin
            Country.Init();
            Country.Code := 'AHX';
            Country.Name := 'Ahland';
            Country.Insert();
        end;
        Run(Observer, 'only_city', '', '', 'Town', '', '', '');
        Run(Observer, 'only_post_code', '', '', '', 'ZIP 12', '', '');
        Run(Observer, 'only_county', '', '', '', '', 'Countyshire', '');
        Run(Observer, 'only_country', '', '', '', '', '', 'AHX');
        Run(Observer, 'all_empty', '', '', '', '', '', '');
        Country.Get('AHX');
        Country.Delete();
        Observer.Expect('only_city', '1=[<Company>] 2=[Town] 3=[] 4=[] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Expect('only_post_code', '1=[<Company>] 2=[ZIP 12 ] 3=[] 4=[] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Expect('only_county', '1=[<Company>] 2=[Countyshire] 3=[] 4=[] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Expect('only_country', '1=[<Company>] 2=[Ahland] 3=[] 4=[] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Expect('all_empty', '1=[<Company>] 2=[] 3=[] 4=[] 5=[] 6=[] 7=[] 8=[] ');
        Observer.Verify();
    end;

    // Writer QV (AL Runner issue 5681): the CompanyLogo element of the header for a Company Information row without a Picture, with the
    // reporter's 1x1 PNG, and with bytes that are no image. The raw line is read; Picture is written through Base64 Convert.FromBase64.
    local procedure QvLogoLine(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        if not Report.SaveAs(Report::"LT AH Header Report", '', ReportFormat::Xml, OutStr) then
            exit('SaveAs returned false');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Contains('CompanyLogo') then
                Result += Line.Trim() + '|';
        end;
        exit(Result);
    end;

    local procedure QvLogoNode(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Document: XmlDocument;
        Node: XmlNode;
    begin
        TempBlob.CreateOutStream(OutStr);
        if not Report.SaveAs(Report::"LT AH Header Report", '', ReportFormat::Xml, OutStr) then
            exit('SaveAs returned false');
        TempBlob.CreateInStream(InStr);
        if not XmlDocument.ReadFrom(InStr, Document) then
            exit('not XML');
        if not Document.SelectSingleNode('/ReportDataSet/BCReportInformation/CompanyMetadata/CompanyLogo', Node) then
            exit('no CompanyLogo element');
        exit('[' + Node.AsXmlElement().InnerText() + ']');
    end;

    local procedure QvSetPicture(Base64Text: Text; PlainText: Text)
    var
        Info: Record "Company Information";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
    begin
        Info.Get();
        Clear(Info.Picture);
        if (Base64Text <> '') or (PlainText <> '') then begin
            Info.Picture.CreateOutStream(OutS);
            if Base64Text <> '' then
                Base64.FromBase64(Base64Text, OutS)
            else
                OutS.WriteText(PlainText);
        end;
        Info.Modify();
    end;

    [Test]
    procedure QV_Header_CompanyLogo_PictureVariants()
    var
        Observer: Codeunit "Probe Observer";
        QkRows: Codeunit "LT QK Setup Rows";
        Base64: Codeunit "Base64 Convert";
        PngTxt: Text;
    begin
        PngTxt := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        QkRows.WriteCompanyInformation();
        QvSetPicture('', '');
        Observer.Observe('no picture line', QvLogoLine());
        Observer.Observe('no picture node', QvLogoNode());
        QvSetPicture(PngTxt, '');
        Observer.Observe('png line', QvLogoLine());
        Observer.Observe('png node equals input', Format(QvLogoNode() = '[' + PngTxt + ']'));
        QvSetPicture('', 'not an image');
        Observer.Observe('text bytes node', QvLogoNode());
        Observer.Observe('text bytes base64', Base64.ToBase64('not an image'));
        QkRows.RestoreCompanyInformation();
        Observer.Expect('no picture line', '<CompanyLogo></CompanyLogo>|');
        Observer.Expect('no picture node', '[]');
        Observer.Expect('png line', '<CompanyLogo>iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==</CompanyLogo>|');
        Observer.Expect('png node equals input', 'Yes');
        Observer.Expect('text bytes node', '[bm90IGFuIGltYWdl]');
        Observer.Expect('text bytes base64', 'bm90IGFuIGltYWdl');
        Observer.Verify();
    end;

    // Writer RB (AL Runner issues 5681 and 5666): the address lines for each "Address Format" of the Company Information's Country/Region
    // (own rows RBPC, RBCP, RBCCP (the format of the GB demo row), RBBL, RBCU), for a blank country per General Ledger Setup
    // "Local Address Format", and for a code with no Country/Region row; each with and without Name 2, Address 2, County and
    // Contact Person. The Company Information row is the one of codeunit 86940; it, the countries and General Ledger Setup are restored.
    // BC 29.0: Contact Person is never written; Blank Line+Post Code+City writes no blank line; County gets its own line except in
    // City+County+Post Code; the Country/Region Name follows; a code with no Country/Region row writes the code as the country line.
    local procedure RbCountry(CountryCode: Code[10]; AddrFormat: Enum "Country/Region Address Format")
    var
        Country: Record "Country/Region";
    begin
        if not Country.Get(CountryCode) then begin
            Country.Init();
            Country.Code := CountryCode;
            Country.Insert();
        end;
        Country.Name := 'Land ' + CountryCode;
        Country."Address Format" := AddrFormat;
        Country.Modify();
    end;

    local procedure RbDropCountry(CountryCode: Code[10])
    var
        Country: Record "Country/Region";
        CustomFormat: Record "Custom Address Format";
        CustomLine: Record "Custom Address Format Line";
    begin
        CustomLine.SetRange("Country/Region Code", CountryCode);
        CustomLine.DeleteAll();
        CustomFormat.SetRange("Country/Region Code", CountryCode);
        CustomFormat.DeleteAll();
        if Country.Get(CountryCode) then
            Country.Delete();
    end;

    local procedure RbRun(var Observer: Codeunit "Probe Observer"; CaseName: Text; Name2: Text; Address2: Text; County: Text; Contact: Text; CountryCode: Code[10])
    var
        Info: Record "Company Information";
    begin
        Info.Get();
        Info.Name := 'RB Name';
        Info."Name 2" := CopyStr(Name2, 1, MaxStrLen(Info."Name 2"));
        Info.Address := 'RB Street 1';
        Info."Address 2" := CopyStr(Address2, 1, MaxStrLen(Info."Address 2"));
        Info.City := 'RB Town';
        Info."Post Code" := 'RB-12';
        Info.County := CopyStr(County, 1, MaxStrLen(Info.County));
        Info."Contact Person" := CopyStr(Contact, 1, MaxStrLen(Info."Contact Person"));
        Info."Country/Region Code" := CountryCode;
        Info.Modify();
        Observer.Observe(CaseName, AddressLines());
    end;

    local procedure RbRunFour(var Observer: Codeunit "Probe Observer"; CountryCode: Code[10])
    begin
        RbRun(Observer, 'full', 'RB Name 2', 'RB Floor 2', 'RB County', 'RB Contact', CountryCode);
        RbRun(Observer, 'no county', 'RB Name 2', 'RB Floor 2', '', 'RB Contact', CountryCode);
        RbRun(Observer, 'no address 2', 'RB Name 2', '', 'RB County', 'RB Contact', CountryCode);
        RbRun(Observer, 'no name 2 no contact', '', 'RB Floor 2', 'RB County', '', CountryCode);
    end;

    [Test]
    procedure RB_Header_AddressFormat_PostCodeCity()
    var
        Observer: Codeunit "Probe Observer";
        QkRows: Codeunit "LT QK Setup Rows";
    begin
        QkRows.WriteCompanyInformation();
        RbCountry('RBPC', "Country/Region Address Format"::"Post Code+City");
        RbRunFour(Observer, 'RBPC');
        QkRows.RestoreCompanyInformation();
        RbDropCountry('RBPC');
        Observer.Expect('full', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB-12 RB Town] 6=[RB County] 7=[Land RBPC] 8=[] ');
        Observer.Expect('no county', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB-12 RB Town] 6=[Land RBPC] 7=[] 8=[] ');
        Observer.Expect('no address 2', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB-12 RB Town] 5=[RB County] 6=[Land RBPC] 7=[] 8=[] ');
        Observer.Expect('no name 2 no contact', '1=[RB Name] 2=[RB Street 1] 3=[RB Floor 2] 4=[RB-12 RB Town] 5=[RB County] 6=[Land RBPC] 7=[] 8=[] ');
        Observer.Verify();
    end;

    [Test]
    procedure RB_Header_AddressFormat_CityPostCode()
    var
        Observer: Codeunit "Probe Observer";
        QkRows: Codeunit "LT QK Setup Rows";
    begin
        QkRows.WriteCompanyInformation();
        RbCountry('RBCP', "Country/Region Address Format"::"City+Post Code");
        RbRunFour(Observer, 'RBCP');
        QkRows.RestoreCompanyInformation();
        RbDropCountry('RBCP');
        Observer.Expect('full', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town, RB-12] 6=[RB County] 7=[Land RBCP] 8=[] ');
        Observer.Expect('no county', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town, RB-12] 6=[Land RBCP] 7=[] 8=[] ');
        Observer.Expect('no address 2', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Town, RB-12] 5=[RB County] 6=[Land RBCP] 7=[] 8=[] ');
        Observer.Expect('no name 2 no contact', '1=[RB Name] 2=[RB Street 1] 3=[RB Floor 2] 4=[RB Town, RB-12] 5=[RB County] 6=[Land RBCP] 7=[] 8=[] ');
        Observer.Verify();
    end;

    [Test]
    procedure RB_Header_AddressFormat_CityCountyPostCode()
    var
        Observer: Codeunit "Probe Observer";
        QkRows: Codeunit "LT QK Setup Rows";
    begin
        QkRows.WriteCompanyInformation();
        RbCountry('RBCCP', "Country/Region Address Format"::"City+County+Post Code");
        RbRunFour(Observer, 'RBCCP');
        QkRows.RestoreCompanyInformation();
        RbDropCountry('RBCCP');
        Observer.Expect('full', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town, RB County RB-12] 6=[Land RBCCP] 7=[] 8=[] ');
        Observer.Expect('no county', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town, RB-12] 6=[Land RBCCP] 7=[] 8=[] ');
        Observer.Expect('no address 2', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Town, RB County RB-12] 5=[Land RBCCP] 6=[] 7=[] 8=[] ');
        Observer.Expect('no name 2 no contact', '1=[RB Name] 2=[RB Street 1] 3=[RB Floor 2] 4=[RB Town, RB County RB-12] 5=[Land RBCCP] 6=[] 7=[] 8=[] ');
        Observer.Verify();
    end;

    [Test]
    procedure RB_Header_AddressFormat_BlankLinePostCodeCity()
    var
        Observer: Codeunit "Probe Observer";
        QkRows: Codeunit "LT QK Setup Rows";
    begin
        QkRows.WriteCompanyInformation();
        RbCountry('RBBL', "Country/Region Address Format"::"Blank Line+Post Code+City");
        RbRunFour(Observer, 'RBBL');
        QkRows.RestoreCompanyInformation();
        RbDropCountry('RBBL');
        Observer.Expect('full', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB-12 RB Town] 6=[RB County] 7=[Land RBBL] 8=[] ');
        Observer.Expect('no county', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB-12 RB Town] 6=[Land RBBL] 7=[] 8=[] ');
        Observer.Expect('no address 2', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB-12 RB Town] 5=[RB County] 6=[Land RBBL] 7=[] 8=[] ');
        Observer.Expect('no name 2 no contact', '1=[RB Name] 2=[RB Street 1] 3=[RB Floor 2] 4=[RB-12 RB Town] 5=[RB County] 6=[Land RBBL] 7=[] 8=[] ');
        Observer.Verify();
    end;

    // Custom: Validate from City+Post Code creates the default Custom Address Format rows of the Base Application.
    [Test]
    procedure RB_Header_AddressFormat_CustomAndUnknownCode()
    var
        Observer: Codeunit "Probe Observer";
        QkRows: Codeunit "LT QK Setup Rows";
        Country: Record "Country/Region";
    begin
        QkRows.WriteCompanyInformation();
        RbCountry('RBCU', "Country/Region Address Format"::"City+Post Code");
        Country.Get('RBCU');
        Country.Validate("Address Format", "Country/Region Address Format"::Custom);
        Country.Modify();
        RbRunFour(Observer, 'RBCU');
        RbDropCountry('RBNONE');
        RbRun(Observer, 'unknown code full', 'RB Name 2', 'RB Floor 2', 'RB County', 'RB Contact', 'RBNONE');
        RbRun(Observer, 'unknown code no county', 'RB Name 2', 'RB Floor 2', '', 'RB Contact', 'RBNONE');
        QkRows.RestoreCompanyInformation();
        RbDropCountry('RBCU');
        Observer.Expect('full', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town RB-12] 6=[Land RBCU] 7=[] 8=[] ');
        Observer.Expect('no county', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town RB-12] 6=[Land RBCU] 7=[] 8=[] ');
        Observer.Expect('no address 2', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Town RB-12] 5=[Land RBCU] 6=[] 7=[] 8=[] ');
        Observer.Expect('no name 2 no contact', '1=[RB Name] 2=[RB Street 1] 3=[RB Floor 2] 4=[RB Town RB-12] 5=[Land RBCU] 6=[] 7=[] 8=[] ');
        Observer.Expect('unknown code full', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town, RB-12] 6=[RB County] 7=[RBNONE] 8=[] ');
        Observer.Expect('unknown code no county', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town, RB-12] 6=[RBNONE] 7=[] 8=[] ');
        Observer.Verify();
    end;

    [Test]
    procedure RB_Header_AddressFormat_BlankCountryPerLocalFormat()
    var
        Observer: Codeunit "Probe Observer";
        QkRows: Codeunit "LT QK Setup Rows";
        GLSetup: Record "General Ledger Setup";
        SavedFormat: Integer;
        Index: Integer;
    begin
        QkRows.WriteCompanyInformation();
        GLSetup.Get();
        SavedFormat := GLSetup."Local Address Format";
        for Index := 0 to 3 do begin
            GLSetup.Get();
            GLSetup."Local Address Format" := Index;
            GLSetup.Modify();
            RbRun(Observer, 'local ' + Format(Index) + ' full', 'RB Name 2', 'RB Floor 2', 'RB County', 'RB Contact', '');
            RbRun(Observer, 'local ' + Format(Index) + ' no county', 'RB Name 2', 'RB Floor 2', '', 'RB Contact', '');
        end;
        GLSetup.Get();
        GLSetup."Local Address Format" := SavedFormat;
        GLSetup.Modify();
        QkRows.RestoreCompanyInformation();
        Observer.Expect('local 0 full', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB-12 RB Town] 6=[RB County] 7=[] 8=[] ');
        Observer.Expect('local 0 no county', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB-12 RB Town] 6=[] 7=[] 8=[] ');
        Observer.Expect('local 1 full', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town, RB-12] 6=[RB County] 7=[] 8=[] ');
        Observer.Expect('local 1 no county', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town, RB-12] 6=[] 7=[] 8=[] ');
        Observer.Expect('local 2 full', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town, RB County RB-12] 6=[] 7=[] 8=[] ');
        Observer.Expect('local 2 no county', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB Town, RB-12] 6=[] 7=[] 8=[] ');
        Observer.Expect('local 3 full', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB-12 RB Town] 6=[RB County] 7=[] 8=[] ');
        Observer.Expect('local 3 no county', '1=[RB Name] 2=[RB Name 2] 3=[RB Street 1] 4=[RB Floor 2] 5=[RB-12 RB Town] 6=[] 7=[] 8=[] ');
        Observer.Verify();
    end;
}
#endif
