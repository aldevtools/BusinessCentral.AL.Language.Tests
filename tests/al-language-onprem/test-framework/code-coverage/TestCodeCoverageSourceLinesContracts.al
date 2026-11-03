// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragelog-method
// Scope: in-scope (the app states resourceExposurePolicy.includeSourceInSymbolFile = true in its app.json; the Cloud app does not)
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app; self-contained codeunit 61260
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// Pins the Code Coverage rows of an app that includes its source in the symbols (the Cloud app has none and reads the platform message,
// see codeunit/TestCodeCoverageLineTextContracts.al): "Line" is the source line exactly as written (indentation, a trailing comment, a blank line
// as an empty text). Rows exist only from the first procedure header on, and only for lines inside procedures: no row for the global var
// section, a comment between procedures, a blank line between procedures or the [Test] attribute. Inside the procedure: the header is
// Trigger/Function, var, a variable line, a blank line, begin and a comment are Empty (Non Applicable), a statement is Code (Covered with
// hits 1 when it ran, Not Covered with hits 0 when it did not), the closing end is Empty.
// BC versions: 27.5

codeunit 61260 "Test Coverage Source Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Counter: Integer;
        // a comment between variables

    // a comment line before the procedure

    local procedure DoubleIfAboveOne(Value: Integer): Integer
    var
        Local1: Integer; // trailing comment

    begin
        // comment inside
        Local1 := Value;

        if Value > 1 then
            exit(Value * 2);
        exit(Value);
    end;

    [Test]
    procedure CodeCoverageRows_OfAnAppWithSource_HoldTheSourceLines()
    var
        CodeCov: Record "Code Coverage";
        Rows: Text;
    begin
        CodeCoverageLog(false, false);
        CodeCoverageLog(false, true);
        CodeCov.DeleteAll();
        CodeCoverageLog(true, false);
        Assert.AreEqual(6, DoubleIfAboveOne(3), 'the recorded procedure runs');
        CodeCoverageLog(false, false);

        CodeCov.SetRange("Object Type", CodeCov."Object Type"::Codeunit);
        CodeCov.SetRange("Object ID", Codeunit::"Test Coverage Source Lines");
        CodeCov.SetRange("Line No.", 1, 40);
        CodeCov.FindSet();
        repeat
            Rows += Format(CodeCov."Line No.") + ' ' + Format(CodeCov."Line Type") + ' h=' + Format(CodeCov."No. of Hits") + ' ' + Format(CodeCov."Code Coverage Status") + ' [' + CodeCov.Line + ']|';
        until CodeCov.Next() = 0;

        Assert.AreEqual(
            '26 Trigger/Function h=0 Non Applicable [    local procedure DoubleIfAboveOne(Value: Integer): Integer]|' +
            '27 Empty h=0 Non Applicable [    var]|' +
            '28 Empty h=0 Non Applicable [        Local1: Integer; // trailing comment]|' +
            '29 Empty h=0 Non Applicable []|' +
            '30 Empty h=0 Non Applicable [    begin]|' +
            '31 Empty h=0 Non Applicable [        // comment inside]|' +
            '32 Code h=1 Covered [        Local1 := Value;]|' +
            '33 Empty h=0 Non Applicable []|' +
            '34 Code h=1 Covered [        if Value > 1 then]|' +
            '35 Code h=1 Covered [            exit(Value * 2);]|' +
            '36 Code h=0 Not Covered [        exit(Value);]|' +
            '37 Empty h=0 Non Applicable [    end;]|' +
            '40 Trigger/Function h=0 Non Applicable [    procedure CodeCoverageRows_OfAnAppWithSource_HoldTheSourceLines()]|',
            Rows, 'rows');
    end;
}
