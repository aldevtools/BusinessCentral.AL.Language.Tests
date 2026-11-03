// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-excellayoutmultipledatasheets-property
// Scope: in-scope
// Fixtures used: Assert (60021), SRL Layout Flags Report (67500) — see SrlLayoutReport.Report.al
//
// "Report Layout List" (2000000234) lists a layout's obsolete flag and Excel sheet
// configuration for a report THIS app declares. Codeunit 60974 pins the same two columns for
// reports that ship precompiled in Base Application; this one pins them for a report compiled
// from source. BC writes both when it publishes the app: IsObsolete is true for any declared
// ObsoleteState other than No; ExcelLayoutMultipleDataSheets is Default when the layout does
// not declare the property, Single Data sheet for false and Multiple data sheets for true.

codeunit 67500 "Test Source Rpt Layout Flags"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure FindLayout(LayoutName: Text; var LayoutList: Record "Report Layout List")
    begin
        LayoutList.SetRange("Report ID", Report::"SRL Layout Flags Report");
        LayoutList.SetRange(Name, LayoutName);
        Assert.IsTrue(LayoutList.FindFirst(), 'Report 67500 declares layout ' + LayoutName + '.');
    end;

    [Test]
    procedure LayoutList_SourceReport_PendingObsoleteLayoutIsObsolete()
    var
        LayoutList: Record "Report Layout List";
    begin
        FindLayout('SrlRetiring', LayoutList);
        Assert.IsTrue(LayoutList.IsObsolete, 'SrlRetiring declares ObsoleteState = Pending.');
    end;

    [Test]
    procedure LayoutList_SourceReport_LayoutWithoutObsoleteStateIsNotObsolete()
    var
        LayoutList: Record "Report Layout List";
    begin
        FindLayout('SrlPlain', LayoutList);
        Assert.IsFalse(LayoutList.IsObsolete, 'SrlPlain declares no ObsoleteState.');
    end;

    [Test]
    procedure LayoutList_SourceReport_ExcelMultipleDataSheetsTrueIsMultiple()
    var
        LayoutList: Record "Report Layout List";
    begin
        FindLayout('SrlSheets', LayoutList);
        Assert.AreEqual(LayoutList.ExcelLayoutMultipleDataSheets::"Multiple data sheets", LayoutList.ExcelLayoutMultipleDataSheets,
            'SrlSheets declares ExcelLayoutMultipleDataSheets = true.');
    end;

    [Test]
    procedure LayoutList_SourceReport_ExcelMultipleDataSheetsFalseIsSingle()
    var
        LayoutList: Record "Report Layout List";
    begin
        FindLayout('SrlOneSheet', LayoutList);
        Assert.AreEqual(LayoutList.ExcelLayoutMultipleDataSheets::"Single Data sheet", LayoutList.ExcelLayoutMultipleDataSheets,
            'SrlOneSheet declares ExcelLayoutMultipleDataSheets = false.');
    end;

    [Test]
    procedure LayoutList_SourceReport_ExcelWithoutSheetPropertyIsDefault()
    var
        LayoutList: Record "Report Layout List";
    begin
        FindLayout('SrlPlain', LayoutList);
        Assert.AreEqual(LayoutList.ExcelLayoutMultipleDataSheets::Default, LayoutList.ExcelLayoutMultipleDataSheets,
            'SrlPlain declares no ExcelLayoutMultipleDataSheets.');
    end;
}
