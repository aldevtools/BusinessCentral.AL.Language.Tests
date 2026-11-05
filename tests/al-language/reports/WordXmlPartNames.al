// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-wordxmlpart-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 95740-95741, enum 95742, reports 95740-95749 and 95753-95754, report extensions 95750-95752, test codeunit 95759
// Probe: written for al-runner issues 6993 and 6994; every literal asserted below is what the BC tiers of the corpus CI matrix produced.
// Facts: the full text of Report.WordXmlPart(Id) and Report.WordXmlPart(Id, true) for
// - report, data item and column names with spaces, dashes, dots, a leading digit, underscores, non-ASCII letters, punctuation and a long name;
// - the DataType of a column of every common field type, of a variable and of a literal;
// - labels and IncludeCaption columns, sibling data items and columns not in alphabetical order, names whose order differs
//   between an ordinal and a case-insensitive comparison;
// - a report changed by one report extension and a report changed by two (added columns and added data items);
// - the content of the BCReportInformation element (the Probe Observer replaces it by x, so it is observed with the tag renamed).
// BC versions: 27-29

table 95740 "LT WXP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Amount; Decimal) { }
        field(4; Qty; Integer) { }
        field(5; Flag; Boolean) { }
        field(6; Day; Date) { }
        field(7; At; Time) { }
        field(8; Stamp; DateTime) { }
        field(9; Kind; Option) { OptionMembers = " ",Alpha,Beta; }
        field(10; Status; Enum "LT WXP Status") { }
        field(11; Id; Guid) { }
        field(12; Big; BigInteger) { }
        field(13; Dur; Duration) { }
        field(14; Formula; DateFormula) { }
        field(15; Pic; Blob) { Subtype = Bitmap; }
        field(16; Photo; Media) { }
        field(17; Ref; RecordId) { }
        field(18; "Unit Price (LCY)"; Decimal) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 95741 "LT WXP Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; RowCode; Code[20]) { }
        field(2; LineNo; Integer) { }
        field(3; Qty; Decimal) { }
    }

    keys
    {
        key(PK; RowCode, LineNo) { Clustered = true; }
    }
}

enum 95742 "LT WXP Status"
{
    Extensible = true;
    value(0; Open) { }
    value(1; Released) { }
}

// Spaces, a dash and a dot (the shape of "Standard Sales - Order Conf.").
report 95740 "LT WXP Std - Order Conf."
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem("Sales Hdr. - No/1"; "LT WXP Row")
        {
            column(Hdr_No; "Code") { }
            dataitem("Line-Item.2"; "LT WXP Line")
            {
                DataItemLink = RowCode = field("Code");
                column(Line_Qty; Qty) { }
            }
        }
    }
}

// A leading digit and underscores.
report 95741 "1LT WXP Digit_Under__x"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem("2nd_Item"; "LT WXP Row")
        {
            column(Lead__2; "Code") { }
            column(Trail_; Name) { }
        }
    }
}

// Non-ASCII letters.
report 95742 "LT WXP Ümlaut Bericht é ß"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem("Kopf Ä"; "LT WXP Row")
        {
            column(Größe; Qty) { }
            column(Café; Name) { }
        }
    }
}

// Punctuation.
report 95743 "LT WXP A/B & C (x) #1,+:;"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem("It's % 50 *"; "LT WXP Row")
        {
            column(No; "Code") { }
        }
    }
}

// A data item name longer than 30 characters and a data item name with a space (column names must be CLS identifiers; two data item names with the same metadata name, "Same X" and Same_X, are AL0757).
report 95744 "LT WXP Long And Same"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(ADataItemNameThatIsLongerThanThirtyCharacters; "LT WXP Row")
        {
            column(LongCode; "Code") { }
        }
        dataitem("Same X"; "LT WXP Line")
        {
            column(SameSpace; Qty) { }
        }

    }
}

// The DataType of columns of the first group of types, in an order that is not alphabetical.
report 95745 "LT WXP Types A"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "LT WXP Row")
        {
            column(ZCode; "Code") { }
            column(YName; Name) { }
            column(XAmount; Amount) { }
            column(WQty; Qty) { }
            column(VFlag; Flag) { }
            column(UDay; Day) { }
            column(TAt; At) { }
            column(SStamp; Stamp) { }
            column(RPrice; "Unit Price (LCY)") { }
        }
    }
}

// The DataType of columns of the second group of types, of a variable and of a literal.
report 95746 "LT WXP Types B"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "LT WXP Row")
        {
            column(Kind; Kind) { }
            column(Status; Status) { }
            column(Id; Id) { }
            column(Big; Big) { }
            column(Dur; Dur) { }
            column(Formula; Formula) { }
            column(Pic; Pic) { }
            column(Photo; Photo) { }
            column(Total; Total) { }
            column(Lit; 'abc') { }
        }
    }

    var
        Total: Decimal;
}

// Labels, IncludeCaption columns, two sibling data items and a nested one between columns.
report 95747 "LT WXP Labels"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(First; "LT WXP Row")
        {
            column(FName; Name) { IncludeCaption = true; }
            column(FCode; "Code") { }
            dataitem(Nested; "LT WXP Line")
            {
                DataItemLink = RowCode = field("Code");
                column(NQty; Qty) { IncludeCaption = true; }
            }
        }
        dataitem(Second; "LT WXP Line")
        {
            column(SLine; LineNo) { }
        }
    }

    labels
    {
        ZLabel = 'Last label';
        ALabel = 'First label', Comment = 'a comment';
    }
}

// Changed by one report extension.
report 95748 "LT WXP One Ext Base"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Base; "LT WXP Row")
        {
            column(BCode; "Code") { }
        }
    }
}

// Changed by two report extensions.
report 95749 "LT WXP Two Ext Base"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Head; "LT WXP Row")
        {
            column(HCode; "Code") { }
            column(HQty; Qty) { }
        }
        dataitem(Tail; "LT WXP Line")
        {
            column(TLine; LineNo) { }
        }
    }
}

reportextension 95750 "LT WXP One Ext" extends "LT WXP One Ext Base"
{
    dataset
    {
        add(Base)
        {
            column(AName; Name) { }
        }
        addlast(Base)
        {
            dataitem(ELines; "LT WXP Line")
            {
                DataItemLink = RowCode = field("Code");
                column(ELineQty; Qty) { }
            }
        }
    }
}

reportextension 95751 "LT WXP Two Ext A" extends "LT WXP Two Ext Base"
{
    dataset
    {
        add(Head)
        {
            column(AAmount; Amount) { }
        }
        addfirst(Head)
        {
            dataitem(ALines; "LT WXP Line")
            {
                DataItemLink = RowCode = field("Code");
                column(ALineQty; Qty) { }
            }
        }
    }

    labels
    {
        ExtLabel = 'Extension label';
    }
}

reportextension 95752 "LT WXP Two Ext B" extends "LT WXP Two Ext Base"
{
    dataset
    {
        add(Head)
        {
            column(BFlag; Flag) { IncludeCaption = true; }
        }
        add(Tail)
        {
            column(BQty; Qty) { }
        }
        addlast(Tail)
        {
            dataitem(BNested; "LT WXP Row")
            {
                column(BMidCode; "Code") { }
            }
        }
    }
}

// Sibling data items not in alphabetical order, and column and label names whose order differs between an ordinal and a
// case-insensitive comparison.
report 95753 "LT WXP Order"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Zulu; "LT WXP Row")
        {
            column(beta; Name) { }
            column(Alpha; "Code") { }
            column(A_B; Qty) { }
            column(AB; Amount) { }
            column(zed2; Flag) { IncludeCaption = true; }
            column(Zed; Day) { }
            dataitem(Yank; "LT WXP Line")
            {
                DataItemLink = RowCode = field("Code");
                column(YQty; Qty) { }
            }
            dataitem(Bravo; "LT WXP Line")
            {
                DataItemLink = RowCode = field("Code");
                column(BQty; Qty) { }
            }
        }
        dataitem(Alpha2; "LT WXP Line")
        {
            column(A2Line; LineNo) { }
        }
    }

    labels
    {
        bLow = 'b';
        Bz = 'B';
        A_Label = 'A';
    }
}

// The DataType of expression columns: variables of several types, Format, a Label, a procedure and a RecordId field.
report 95754 "LT WXP Types C"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Rows; "LT WXP Row")
        {
            column(TextVar; TextVar) { }
            column(CodeVar; CodeVar) { }
            column(IntVar; IntVar) { }
            column(BoolVar; BoolVar) { }
            column(DateVar; DateVar) { }
            column(FmtCol; Format(Amount)) { }
            column(LblCol; LblVar) { }
            column(ProcCol; TextProc()) { }
            column(IntLit; 7) { }
            column(RefCol; Ref) { }
            column(QualCol; Rows.Amount) { }
        }
    }

    var
        TextVar: Text;
        CodeVar: Code[10];
        IntVar: Integer;
        BoolVar: Boolean;
        DateVar: Date;
        LblVar: Label 'A label';

    local procedure TextProc(): Text
    begin
        exit('p');
    end;
}

codeunit 95759 "LT WXP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WordXmlPart_SpacesDashDot_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Std - Order Conf."));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_WXP_Std_Order_Conf/95740/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Sales_Hdr_No_1>\r\n    <Hdr_No>Hdr_No</Hdr_No>\r\n    <Line_Item_2>\r\n      <Line_Qty>Line_Qty</Line_Qty>\r\n    </Line_Item_2>\r\n  </Sales_Hdr_No_1>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_SpacesDashDot_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Std - Order Conf.", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_WXP_Std_Order_Conf/95740/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Tooltips />\r\n  <Sales_Hdr_No_1 ElementType="DataItem" ElementId="2125348297">\r\n    <Hdr_No ElementType="Column" ElementId="331048043" DataType="Code">Hdr_No</Hdr_No>\r\n    <Line_Item_2 ElementType="DataItem" ElementId="666712983">\r\n      <Line_Qty ElementType="Column" ElementId="83512728" DataType="Decimal">Line_Qty</Line_Qty>\r\n    </Line_Item_2>\r\n  </Sales_Hdr_No_1>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_DigitUnderscore_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"1LT WXP Digit_Under__x"));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/_x0031_LT_WXP_Digit_Under__x/95741/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <_x0032_nd_Item>\r\n    <Lead__2>Lead__2</Lead__2>\r\n    <Trail_>Trail_</Trail_>\r\n  </_x0032_nd_Item>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_DigitUnderscore_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"1LT WXP Digit_Under__x", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/_x0031_LT_WXP_Digit_Under__x/95741/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Tooltips />\r\n  <_x0032_nd_Item ElementType="DataItem" ElementId="152506855">\r\n    <Lead__2 ElementType="Column" ElementId="1845277795" DataType="Code">Lead__2</Lead__2>\r\n    <Trail_ ElementType="Column" ElementId="233829816" DataType="Text">Trail_</Trail_>\r\n  </_x0032_nd_Item>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_NonAscii_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Ümlaut Bericht é ß"));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_WXP_Ümlaut_Bericht_é_ß/95742/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Kopf_Ä>\r\n    <Café>Café</Café>\r\n    <Größe>Größe</Größe>\r\n  </Kopf_Ä>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_NonAscii_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Ümlaut Bericht é ß", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_WXP_Ümlaut_Bericht_é_ß/95742/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Tooltips />\r\n  <Kopf_Ä ElementType="DataItem" ElementId="26383963">\r\n    <Café ElementType="Column" ElementId="687817576" DataType="Text">Café</Café>\r\n    <Größe ElementType="Column" ElementId="1062207292" DataType="Integer">Größe</Größe>\r\n  </Kopf_Ä>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_Punctuation_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP A/B & C (x) #1,+:;"));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_WXP_A_B__x0026__C_x__x0023_1_x002C__x002B___x003B_/95743/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <It_x0027_s_Percent_50__x002A_>\r\n    <No>No</No>\r\n  </It_x0027_s_Percent_50__x002A_>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_Punctuation_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP A/B & C (x) #1,+:;", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_WXP_A_B__x0026__C_x__x0023_1_x002C__x002B___x003B_/95743/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Tooltips />\r\n  <It_x0027_s_Percent_50__x002A_ ElementType="DataItem" ElementId="1742776786">\r\n    <No ElementType="Column" ElementId="1198268340" DataType="Code">No</No>\r\n  </It_x0027_s_Percent_50__x002A_>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_LongAndSameName_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Long And Same"));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_WXP_Long_And_Same/95744/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <ADataItemNameThatIsLongerThanThirtyCharacters>\r\n    <LongCode>LongCode</LongCode>\r\n  </ADataItemNameThatIsLongerThanThirtyCharacters>\r\n  <Same_X>\r\n    <SameSpace>SameSpace</SameSpace>\r\n  </Same_X>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_LongAndSameName_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Long And Same", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_WXP_Long_And_Same/95744/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Tooltips />\r\n  <ADataItemNameThatIsLongerThanThirtyCharacters ElementType="DataItem" ElementId="1861245605">\r\n    <LongCode ElementType="Column" ElementId="115893134" DataType="Code">LongCode</LongCode>\r\n  </ADataItemNameThatIsLongerThanThirtyCharacters>\r\n  <Same_X ElementType="DataItem" ElementId="1381979815">\r\n    <SameSpace ElementType="Column" ElementId="1268538357" DataType="Decimal">SameSpace</SameSpace>\r\n  </Same_X>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_TypesA_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Types A"));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_WXP_Types_A/95745/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Rows>\r\n    <RPrice>RPrice</RPrice>\r\n    <SStamp>SStamp</SStamp>\r\n    <TAt>TAt</TAt>\r\n    <UDay>UDay</UDay>\r\n    <VFlag>VFlag</VFlag>\r\n    <WQty>WQty</WQty>\r\n    <XAmount>XAmount</XAmount>\r\n    <YName>YName</YName>\r\n    <ZCode>ZCode</ZCode>\r\n  </Rows>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_TypesA_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Types A", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_WXP_Types_A/95745/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Tooltips />\r\n  <Rows ElementType="DataItem" ElementId="578941028">\r\n    <RPrice ElementType="Column" ElementId="366123210" DataType="Decimal">RPrice</RPrice>\r\n    <SStamp ElementType="Column" ElementId="381244893" DataType="DateTime">SStamp</SStamp>\r\n    <TAt ElementType="Column" ElementId="642154132" DataType="Time">TAt</TAt>\r\n    <UDay ElementType="Column" ElementId="399714692" DataType="Date">UDay</UDay>\r\n    <VFlag ElementType="Column" ElementId="1459118273" DataType="Boolean">VFlag</VFlag>\r\n    <WQty ElementType="Column" ElementId="1254702462" DataType="Integer">WQty</WQty>\r\n    <XAmount ElementType="Column" ElementId="767587047" DataType="Decimal">XAmount</XAmount>\r\n    <YName ElementType="Column" ElementId="2109778619" DataType="Text">YName</YName>\r\n    <ZCode ElementType="Column" ElementId="336516762" DataType="Code">ZCode</ZCode>\r\n  </Rows>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_TypesB_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Types B"));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_WXP_Types_B/95746/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Rows>\r\n    <Big>Big</Big>\r\n    <Dur>Dur</Dur>\r\n    <Formula>Formula</Formula>\r\n    <Id>Id</Id>\r\n    <Kind>Kind</Kind>\r\n    <Lit>Lit</Lit>\r\n    <Photo>Photo</Photo>\r\n    <Pic />\r\n    <Status>Status</Status>\r\n    <Total>Total</Total>\r\n  </Rows>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_TypesB_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Types B", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_WXP_Types_B/95746/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Tooltips />\r\n  <Rows ElementType="DataItem" ElementId="578941028">\r\n    <Big ElementType="Column" ElementId="1915598679" DataType="BigInteger">Big</Big>\r\n    <Dur ElementType="Column" ElementId="104994878" DataType="Duration">Dur</Dur>\r\n    <Formula ElementType="Column" ElementId="1157393955" DataType="DateFormula">Formula</Formula>\r\n    <Id ElementType="Column" ElementId="1731978936" DataType="GUID">Id</Id>\r\n    <Kind ElementType="Column" ElementId="735108757" DataType="Option">Kind</Kind>\r\n    <Lit ElementType="Column" ElementId="182398796" DataType="String">Lit</Lit>\r\n    <Photo ElementType="Column" ElementId="775198353" DataType="Media">Photo</Photo>\r\n    <Pic ElementType="Column" ElementId="559402575" DataType="BLOB" />\r\n    <Status ElementType="Column" ElementId="1634144551" DataType="Option">Status</Status>\r\n    <Total ElementType="Column" ElementId="1902056945" DataType="Decimal">Total</Total>\r\n  </Rows>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_Labels_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Labels"));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_WXP_Labels/95747/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Labels>\r\n    <ALabel>ALabel</ALabel>\r\n    <FNameCaption>FNameCaption</FNameCaption>\r\n    <NQtyCaption>NQtyCaption</NQtyCaption>\r\n    <ZLabel>ZLabel</ZLabel>\r\n  </Labels>\r\n  <First>\r\n    <FCode>FCode</FCode>\r\n    <FName>FName</FName>\r\n    <Nested>\r\n      <NQty>NQty</NQty>\r\n    </Nested>\r\n  </First>\r\n  <Second>\r\n    <SLine>SLine</SLine>\r\n  </Second>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_Labels_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Labels", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_WXP_Labels/95747/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Labels>\r\n    <ALabel ElementType="Parameter" ElementId="1949206914" DataType="String">ALabel</ALabel>\r\n    <FNameCaption ElementType="Parameter" ElementId="1486599940" DataType="String">FNameCaption</FNameCaption>\r\n    <NQtyCaption ElementType="Parameter" ElementId="1857757097" DataType="String">NQtyCaption</NQtyCaption>\r\n    <ZLabel ElementType="Parameter" ElementId="1660052375" DataType="String">ZLabel</ZLabel>\r\n  </Labels>\r\n  <Tooltips />\r\n  <First ElementType="DataItem" ElementId="2008383545">\r\n    <FCode ElementType="Column" ElementId="1300742378" DataType="Code">FCode</FCode>\r\n    <FName ElementType="Column" ElementId="1486599940" DataType="Text">FName</FName>\r\n    <Nested ElementType="DataItem" ElementId="1510830432">\r\n      <NQty ElementType="Column" ElementId="1857757097" DataType="Decimal">NQty</NQty>\r\n    </Nested>\r\n  </First>\r\n  <Second ElementType="DataItem" ElementId="1425916523">\r\n    <SLine ElementType="Column" ElementId="312178264" DataType="Integer">SLine</SLine>\r\n  </Second>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_OneExtension_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP One Ext Base"));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_WXP_One_Ext_Base/95748/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Base>\r\n    <AName>AName</AName>\r\n    <BCode>BCode</BCode>\r\n    <ELines>\r\n      <ELineQty>ELineQty</ELineQty>\r\n    </ELines>\r\n  </Base>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_OneExtension_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP One Ext Base", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_WXP_One_Ext_Base/95748/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Tooltips />\r\n  <Base ElementType="DataItem" ElementId="440217728">\r\n    <AName ElementType="Column" ElementId="2069068611" DataType="Text">AName</AName>\r\n    <BCode ElementType="Column" ElementId="1669706382" DataType="Code">BCode</BCode>\r\n    <ELines ElementType="DataItem" ElementId="1035308699">\r\n      <ELineQty ElementType="Column" ElementId="169230578" DataType="Decimal">ELineQty</ELineQty>\r\n    </ELines>\r\n  </Base>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_TwoExtensions_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Two Ext Base"));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-nav/reports/LT_WXP_Two_Ext_Base/95749/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Labels>\r\n    <BFlagCaption>BFlagCaption</BFlagCaption>\r\n    <ExtLabel>ExtLabel</ExtLabel>\r\n  </Labels>\r\n  <Head>\r\n    <AAmount>AAmount</AAmount>\r\n    <BFlag>BFlag</BFlag>\r\n    <HCode>HCode</HCode>\r\n    <HQty>HQty</HQty>\r\n    <ALines>\r\n      <ALineQty>ALineQty</ALineQty>\r\n    </ALines>\r\n  </Head>\r\n  <Tail>\r\n    <BQty>BQty</BQty>\r\n    <TLine>TLine</TLine>\r\n    <BNested>\r\n      <BMidCode>BMidCode</BMidCode>\r\n    </BNested>\r\n  </Tail>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_TwoExtensions_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Two Ext Base", true));
        Observer.Expect('part', '<?xml version="1.0" encoding="utf-16"?>\r\n<NavWordReportXmlPart xmlns="urn:microsoft-dynamics-businesscentral/internal/extended/reports/LT_WXP_Two_Ext_Base/95749/">\r\n  <BCReportInformation>x</BCReportInformation>\r\n  <Labels>\r\n    <BFlagCaption ElementType="Parameter" ElementId="912455157" DataType="String">BFlagCaption</BFlagCaption>\r\n    <ExtLabel ElementType="Parameter" ElementId="813550006" DataType="String">ExtLabel</ExtLabel>\r\n  </Labels>\r\n  <Tooltips />\r\n  <Head ElementType="DataItem" ElementId="1681204005">\r\n    <AAmount ElementType="Column" ElementId="1596937016" DataType="Decimal">AAmount</AAmount>\r\n    <BFlag ElementType="Column" ElementId="912455157" DataType="Boolean">BFlag</BFlag>\r\n    <HCode ElementType="Column" ElementId="818886184" DataType="Code">HCode</HCode>\r\n    <HQty ElementType="Column" ElementId="1419468113" DataType="Integer">HQty</HQty>\r\n    <ALines ElementType="DataItem" ElementId="1527077537">\r\n      <ALineQty ElementType="Column" ElementId="277159434" DataType="Decimal">ALineQty</ALineQty>\r\n    </ALines>\r\n  </Head>\r\n  <Tail ElementType="DataItem" ElementId="2041416573">\r\n    <BQty ElementType="Column" ElementId="1096574501" DataType="Decimal">BQty</BQty>\r\n    <TLine ElementType="Column" ElementId="1902278759" DataType="Integer">TLine</TLine>\r\n    <BNested ElementType="DataItem" ElementId="1904151690">\r\n      <BMidCode ElementType="Column" ElementId="1503903634" DataType="Code">BMidCode</BMidCode>\r\n    </BNested>\r\n  </Tail>\r\n</NavWordReportXmlPart>');
        Observer.Verify();
    end;

    [Test]
    procedure WordXmlPart_TwoExtensions_InstanceEqualsStatic()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT WXP Two Ext Base";
    begin
        Observer.Observe('plain equal', Format(Rpt.WordXmlPart() = Report.WordXmlPart(Report::"LT WXP Two Ext Base")));
        Observer.Observe('extended equal', Format(Rpt.WordXmlPart(true) = Report.WordXmlPart(Report::"LT WXP Two Ext Base", true)));
        Observer.Expect('plain equal', 'Yes');
        Observer.Expect('extended equal', 'Yes');
        Observer.Verify();
    end;

    // The Probe Observer replaces the content of <BCReportInformation> by x; renaming the tag shows it.
    [Test]
    procedure WordXmlPart_ReportInformation_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Part: Text;
    begin
        Part := Report.WordXmlPart(Report::"LT WXP One Ext Base").Replace('BCReportInformation', 'BCRI');
        Observer.Observe('head', Part.Substring(1, Part.IndexOf('<CompanyMetadata>') - 1));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_ReportInformation_Extended()
    var
        Observer: Codeunit "Probe Observer";
        Part: Text;
    begin
        Part := Report.WordXmlPart(Report::"LT WXP One Ext Base", true).Replace('BCReportInformation', 'BCRI');
        Observer.Observe('head', Part.Substring(1, Part.IndexOf('<CompanyMetadata>') - 1));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_Order_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Order"));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_TypesC_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Types C", true));
        Observer.Finish();
    end;

    // The rest of the report information, from CompanyMetadata on (the first part is in WordXmlPart_ReportInformation_*).
    [Test]
    procedure WordXmlPart_ReportInformationTail_Plain()
    var
        Observer: Codeunit "Probe Observer";
        Part: Text;
    begin
        Part := Report.WordXmlPart(Report::"LT WXP One Ext Base").Replace('BCReportInformation', 'BCRI');
        Observer.Observe('tail', Part.Substring(Part.IndexOf('<CompanyMetadata>')));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_ReportInformationTail_Extended()
    var
        Observer: Codeunit "Probe Observer";
        Part: Text;
    begin
        Part := Report.WordXmlPart(Report::"LT WXP One Ext Base", true).Replace('BCReportInformation', 'BCRI');
        Observer.Observe('tail', Part.Substring(Part.IndexOf('<CompanyMetadata>')));
        Observer.Finish();
    end;
}
