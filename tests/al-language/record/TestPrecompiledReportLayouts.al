// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-defaultlayout-method
// Scope: in-scope
// Fixtures used: Assert (60021)
//
// Layout RESOLUTION for reports that ship precompiled inside Base Application, which this app
// depends on — no rendering. Two surfaces, both read before any renderer is involved:
//
//   Report.DefaultLayout   reads the report's own metadata. RDLC is the platform's fallback
//                          for a report stating no default, so both reports below are chosen
//                          to declare Word.
//   "Report Layout List"   (2000000234) is where by-name layout selection looks. An empty
//                          answer here is what makes a by-name selection fail with
//                          "Report N does not have a valid layout".
//
// Report 1306 "Standard Sales - Invoice" uses the rendering syntax: six layouts,
// DefaultRenderingLayout = StandardSalesInvoice.docx (Word). Report 1320 "Notification Email"
// uses the legacy syntax: WordLayout plus DefaultLayout = Word. Both are stated identically in
// Base Application 27.0 and 28.4. No layout COUNT is asserted, so a layout Microsoft adds does
// not break this.
//
// A layout's obsolete flag and Excel sheet configuration are also listed. Report 107
// "Customer - Order Summary" declares three layouts, of which only RDLC states
// ObsoleteState = Pending; report 99000763 "Prod. Order - List" declares ProdOrderListExcel
// with ExcelLayoutMultipleDataSheets = true. Both are stated identically in Base Application
// 27.0 through 28.4.

codeunit 60974 "Test Precompiled Rpt Layouts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DefaultLayout_PrecompiledRenderingSyntaxReport_IsWord()
    begin
        Assert.AreEqual('Word', Format(Report.DefaultLayout(Report::"Standard Sales - Invoice")),
            'Report 1306 declares DefaultRenderingLayout = StandardSalesInvoice.docx, a Word layout.');
    end;

    [Test]
    procedure DefaultLayout_PrecompiledLegacySyntaxReport_IsWord()
    begin
        Assert.AreEqual('Word', Format(Report.DefaultLayout(Report::"Notification Email")),
            'Report 1320 declares DefaultLayout = Word.');
    end;

    [Test]
    procedure LayoutList_PrecompiledReport_ListsDeclaredRdlcLayout()
    var
        LayoutList: Record "Report Layout List";
    begin
        LayoutList.SetRange("Report ID", Report::"Standard Sales - Invoice");
        LayoutList.SetRange(Name, 'StandardSalesInvoice.rdlc');
        Assert.IsTrue(LayoutList.FindFirst(), 'Report 1306 declares layout StandardSalesInvoice.rdlc.');
        Assert.AreEqual(LayoutList."Layout Format"::RDLC, LayoutList."Layout Format",
            'StandardSalesInvoice.rdlc is declared Type = RDLC.');
    end;

    [Test]
    procedure LayoutList_PrecompiledReport_ListsDeclaredWordLayout()
    var
        LayoutList: Record "Report Layout List";
    begin
        LayoutList.SetRange("Report ID", Report::"Standard Sales - Invoice");
        LayoutList.SetRange(Name, 'StandardSalesInvoice.docx');
        Assert.IsTrue(LayoutList.FindFirst(), 'Report 1306 declares layout StandardSalesInvoice.docx.');
        Assert.AreEqual(LayoutList."Layout Format"::Word, LayoutList."Layout Format",
            'StandardSalesInvoice.docx is declared Type = Word.');
    end;

    [Test]
    procedure LayoutList_PrecompiledReport_UndeclaredNameIsAbsent()
    var
        LayoutList: Record "Report Layout List";
    begin
        LayoutList.SetRange("Report ID", Report::"Standard Sales - Invoice");
        LayoutList.SetRange(Name, 'NoSuchLayout.docx');
        Assert.IsTrue(LayoutList.IsEmpty(), 'A name report 1306 does not declare must not be listed.');
    end;

    [Test]
    procedure LayoutList_PrecompiledReport_PendingObsoleteLayoutIsObsolete()
    var
        LayoutList: Record "Report Layout List";
    begin
        LayoutList.SetRange("Report ID", Report::"Customer - Order Summary");
        LayoutList.SetRange(Name, 'RDLC');
        Assert.IsTrue(LayoutList.FindFirst(), 'Report 107 declares layout RDLC.');
        Assert.IsTrue(LayoutList.IsObsolete, 'Report 107 layout RDLC declares ObsoleteState = Pending.');
    end;

    [Test]
    procedure LayoutList_PrecompiledReport_LayoutWithoutObsoleteStateIsNotObsolete()
    var
        LayoutList: Record "Report Layout List";
    begin
        LayoutList.SetRange("Report ID", Report::"Customer - Order Summary");
        LayoutList.SetRange(Name, 'Word');
        Assert.IsTrue(LayoutList.FindFirst(), 'Report 107 declares layout Word.');
        Assert.IsFalse(LayoutList.IsObsolete, 'Report 107 layout Word declares no ObsoleteState.');
    end;

    [Test]
    procedure LayoutList_PrecompiledReport_ExcelMultipleDataSheetsIsListed()
    var
        LayoutList: Record "Report Layout List";
    begin
        LayoutList.SetRange("Report ID", Report::"Prod. Order - List");
        LayoutList.SetRange(Name, 'ProdOrderListExcel');
        Assert.IsTrue(LayoutList.FindFirst(), 'Report 99000763 declares layout ProdOrderListExcel.');
        Assert.AreEqual(LayoutList.ExcelLayoutMultipleDataSheets::"Multiple data sheets", LayoutList.ExcelLayoutMultipleDataSheets,
            'ProdOrderListExcel declares ExcelLayoutMultipleDataSheets = true.');
    end;

    [Test]
    procedure LayoutList_PrecompiledReport_ExcelWithoutSheetPropertyIsDefault()
    var
        LayoutList: Record "Report Layout List";
    begin
        LayoutList.SetRange("Report ID", Report::"Customer - Order Summary");
        LayoutList.SetRange(Name, 'Excel');
        Assert.IsTrue(LayoutList.FindFirst(), 'Report 107 declares layout Excel.');
        Assert.AreEqual(LayoutList.ExcelLayoutMultipleDataSheets::Default, LayoutList.ExcelLayoutMultipleDataSheets,
            'Report 107 layout Excel declares no ExcelLayoutMultipleDataSheets.');
    end;
}
