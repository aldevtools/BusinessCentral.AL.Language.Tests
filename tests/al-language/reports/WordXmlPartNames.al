// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-wordxmlpart-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own tables 95740-95741, enum 95742, reports 95740-95749, report extensions 95750-95752, test codeunit 95759
// Probe: written for al-runner issues 6993 and 6994; every literal asserted below is what the BC tiers of the corpus CI matrix produced.
// Facts: the full text of Report.WordXmlPart(Id) and Report.WordXmlPart(Id, true) for
// - report, data item and column names with spaces, dashes, dots, a leading digit, underscores, non-ASCII letters, punctuation and a long name;
// - the DataType of a column of every common field type, of a variable and of a literal;
// - labels and IncludeCaption columns, sibling data items and columns not in alphabetical order;
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
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_SpacesDashDot_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Std - Order Conf.", true));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_DigitUnderscore_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"1LT WXP Digit_Under__x"));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_DigitUnderscore_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"1LT WXP Digit_Under__x", true));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_NonAscii_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Ümlaut Bericht é ß"));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_NonAscii_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Ümlaut Bericht é ß", true));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_Punctuation_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP A/B & C (x) #1,+:;"));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_Punctuation_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP A/B & C (x) #1,+:;", true));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_LongAndSameName_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Long And Same"));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_LongAndSameName_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Long And Same", true));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_TypesA_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Types A"));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_TypesA_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Types A", true));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_TypesB_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Types B"));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_TypesB_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Types B", true));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_Labels_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Labels"));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_Labels_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Labels", true));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_OneExtension_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP One Ext Base"));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_OneExtension_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP One Ext Base", true));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_TwoExtensions_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Two Ext Base"));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_TwoExtensions_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP Two Ext Base", true));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_TwoExtensions_InstanceEqualsStatic()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT WXP Two Ext Base";
    begin
        Observer.Observe('plain equal', Format(Rpt.WordXmlPart() = Report.WordXmlPart(Report::"LT WXP Two Ext Base")));
        Observer.Observe('extended equal', Format(Rpt.WordXmlPart(true) = Report.WordXmlPart(Report::"LT WXP Two Ext Base", true)));
        Observer.Finish();
    end;

    // The Probe Observer replaces the content of <BCReportInformation> by x; renaming the tag shows it.
    [Test]
    procedure WordXmlPart_ReportInformation_Plain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP One Ext Base").Replace('BCReportInformation', 'BCRI'));
        Observer.Finish();
    end;

    [Test]
    procedure WordXmlPart_ReportInformation_Extended()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('part', Report.WordXmlPart(Report::"LT WXP One Ext Base", true).Replace('BCReportInformation', 'BCRI'));
        Observer.Finish();
    end;
}
