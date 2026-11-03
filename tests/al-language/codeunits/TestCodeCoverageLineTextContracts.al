// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoveragelog-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 69090
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the "Line" and "Code Coverage Status" columns of the Code Coverage table for the rows of an app compiled WITHOUT its source in the
// symbols (the default; manifest ShowMyCode / IncludeSourceInSymbolFile not set): every row's Line holds the platform's text "The extension
// that declares this object has its manifest property ShowMyCode (being deprecated) or IncludeSourceInSymbolFile set to false. This means that
// the source code cannot be viewed." instead of the source line. The procedure below sits at lines 25 to 30 of this file (header 25, begin 26, if 27,
// exit 28, exit 29, end 30; if this moves, move these numbers): header Trigger/Function, begin Empty (Non Applicable), the if and the exit it takes
// Code, Covered, hits 1, the exit it does not take Code, Not Covered, hits 0, end Empty.
// BC versions: 27.5

// BC versions: 27.5

codeunit 69090 "Probe Coverage Line Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure DoubleIfAboveOne(Value: Integer): Integer
    begin
        if Value > 1 then
            exit(Value * 2);
        exit(Value);
    end;

    [Test]
    procedure LineRows_OfAnAppWithoutSource_HoldThePlatformMessage()
    var
        CodeCov: Record "Code Coverage";
        Rows: Text;
        NoSource: Text;
    begin
        NoSource := 'The extension that declares this object has its manifest property ShowMyCode (being deprecated) or IncludeSourceInSymbolFile set to false. This means that the source code cannot be viewed.';
        CodeCoverageLog(false, false);
        CodeCoverageLog(false, true);
        CodeCov.DeleteAll();
        CodeCoverageLog(true, false);
        Assert.AreEqual(6, DoubleIfAboveOne(3), 'the recorded procedure runs');
        CodeCoverageLog(false, false);

        CodeCov.SetRange("Object Type", CodeCov."Object Type"::Codeunit);
        CodeCov.SetRange("Object ID", Codeunit::"Probe Coverage Line Text");
        CodeCov.SetRange("Line No.", 25, 30);
        CodeCov.FindSet();
        repeat
            Assert.AreEqual(NoSource, CodeCov.Line, 'Line of row ' + Format(CodeCov."Line No."));
            Rows += Format(CodeCov."Line No.") + ' ' + Format(CodeCov."Line Type") + ' hits=' + Format(CodeCov."No. of Hits") + ' ' + Format(CodeCov."Code Coverage Status") + '|';
        until CodeCov.Next() = 0;

        Assert.AreEqual(
            '25 Trigger/Function hits=0 Non Applicable|26 Empty hits=0 Non Applicable|27 Code hits=1 Covered|28 Code hits=1 Covered|29 Code hits=0 Not Covered|30 Empty hits=0 Non Applicable|',
            Rows, 'rows');
    end;
}
