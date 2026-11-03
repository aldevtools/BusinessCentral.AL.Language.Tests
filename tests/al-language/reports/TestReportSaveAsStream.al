// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: RSS Sample (60871), RSS Fixture Report (60872); shared Assert (60021)
//
// Migrated from AL Runner tests/runner-extras/report-saveas-stream (ReportSaveAsTests.Codeunit.al).
// The suite's own "RSS Assert" helper (source codeunit 60700) mapped onto the shared Assert
// codeunit for IsTrue/IsFalse; its Contains(Haystack, Needle, Msg) call site was rewritten to
// the shared Assert.IsSubstring(OriginalText, Substring) — same substring-containment check,
// minus the custom message parameter the shared signature does not carry — and the private
// helper was dropped rather than migrated.
//
// LEAVE-BEHIND: the source test method SaveAsPdf_RdlcLayout_ThrowsExternalRenderingOos is
// deliberately NOT migrated — it pins a runner-specific OutOfScope-throwing contract for
// external (RDLC/Word/Excel) report rendering and stays untouched in
// tests/runner-extras/report-saveas-stream as a runner-specific behaviour test.
//
/// <summary>
/// The dataset (Xml) SaveAs path over a report that has a rendering layout but is not
/// ProcessingOnly. Real data-item iteration over the in-memory table provider, proven by
/// asserting the dataset XML contains a value the test itself inserted — never a canned or
/// empty dataset.
/// </summary>
codeunit 60873 "RSS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Sample: Record "RSS Sample";
    begin
        Sample.DeleteAll();
    end;

    // Positive: the dataset XML must contain the exact value the test inserted —
    // proving real data-item iteration, not a canned/empty dataset.
    [Test]
    procedure SaveAsXml_StreamContainsInsertedValue()
    var
        Sample: Record "RSS Sample";
        BlobRec: Record "RSS Sample";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Content: Text;
    begin
        Initialize();
        Sample."Entry No." := 1;
        Sample.Description := 'RSSMARKER-1f2a3b4c';
        Sample.Amount := 42.5;
        Sample.Insert();

        BlobRec."Blob Data".CreateOutStream(OutStr);
        Assert.IsTrue(
            Report.SaveAs(Report::"RSS Fixture Report", '', ReportFormat::Xml, OutStr),
            'Report.SaveAs(Xml) must return true');

        BlobRec."Blob Data".CreateInStream(InStr);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Content += Line;
        end;

        Assert.IsSubstring(Content, '<');
        Assert.IsSubstring(Content, 'RSSMARKER-1f2a3b4c');
    end;
}
