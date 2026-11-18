// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-json-files#appjson-file
// Scope: in-scope
// Fixtures used: Test Codeunit Metadata Virt T (60962)
//
// The app declares two idRanges: 60000..60999 and 67000..69999. This codeunit is the first
// object in the second range. It proves two things:
//   1. CI runs test codeunits from the second range. ci.yml's codeunit_range must list both
//      ranges; if it did not, this codeunit would be missing from every leg's PASS lines.
//   2. BC treats objects from both ranges as one app: CodeUnit Metadata lists them together,
//      and one id filter spanning both ranges returns rows from both.

codeunit 67000 "Test Second Id Range"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Codeunit_SecondIdRange_TestCodeunit_IsListedInCodeunitMetadata()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        Assert.IsTrue(
            CodeunitMetadata.Get(Codeunit::"Test Second Id Range"),
            'CodeUnit Metadata has no row for a codeunit declared in the second idRange.');
        Assert.AreEqual(67000, CodeunitMetadata.ID, 'Unexpected ID for Test Second Id Range.');
        Assert.AreEqual('Test Second Id Range', CodeunitMetadata.Name, 'Unexpected Name for Test Second Id Range.');
        Assert.AreEqual(
            CodeunitMetadata.Subtype::Test, CodeunitMetadata.Subtype,
            'Test Second Id Range declares Subtype = Test.');
    end;

    [Test]
    procedure Codeunit_SecondIdRange_FilterAcrossBothRanges_ReturnsRowsFromBoth()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        // 60962 is in the first range and 67000 is in the second. A filter from one to the
        // other, restricted to test codeunits, starts at 60962 and ends at 67000.
        CodeunitMetadata.SetRange(Subtype, CodeunitMetadata.Subtype::Test);
        CodeunitMetadata.SetRange(ID, Codeunit::"Test Codeunit Metadata Virt T", Codeunit::"Test Second Id Range");

        Assert.IsTrue(CodeunitMetadata.FindFirst(), 'FindFirst must find a test codeunit in 60962..67000.');
        Assert.AreEqual(
            Codeunit::"Test Codeunit Metadata Virt T", CodeunitMetadata.ID,
            'FindFirst must return the first-range codeunit 60962.');

        Assert.IsTrue(CodeunitMetadata.FindLast(), 'FindLast must find a test codeunit in 60962..67000.');
        Assert.AreEqual(
            Codeunit::"Test Second Id Range", CodeunitMetadata.ID,
            'FindLast must return the second-range codeunit 67000.');
    end;

    [Test]
    procedure Codeunit_SecondIdRange_NormalSubtypeFilter_ExcludesThisTestCodeunit()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        CodeunitMetadata.SetRange(ID, Codeunit::"Test Second Id Range");
        CodeunitMetadata.SetRange(Subtype, CodeunitMetadata.Subtype::Normal);
        Assert.IsTrue(
            CodeunitMetadata.IsEmpty(),
            'A Subtype = Normal filter must not return codeunit 67000, which is a test codeunit.');
    end;
}
