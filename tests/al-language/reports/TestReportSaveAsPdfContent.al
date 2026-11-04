// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: RSS Sample (60871), RSS Fixture Report (60872); shared Assert (60021)
//
// WHAT THIS MEASURES.
//
// What Report.SaveAs(..., Pdf, ...) actually PUTS IN THE STREAM, on both tiers. Before this
// file the corpus asserted only the RETURN VALUE and never read the blob back, so
// "Windows renders RDLC" rested on a boolean -- and a boolean cannot distinguish a rendered
// PDF from an empty or truncated one. Issue #238.
//
// WHAT HAPPENED TO THE PREDECESSOR, cu 60878 (#250, corrected by #256).
//
// cu 60878 was deleted, correctly: it asserted a flat "SaveAs returned false", which is red on
// a Windows tier by construction, and this file covers on BOTH tiers what that covered on one.
//
// But 60878 carried TWO assertions and only the first was superseded. Its return-value
// assertion is subsumed by the branch below. Its SECOND -- the error TEXT the refusing tier
// reports -- was not asserted anywhere in this file, and deleting the codeunit dropped it: for
// the span between #250 and #256 nothing in the corpus pinned that string. It was a real,
// passing measurement when it was removed (run 34099499973, PASS on all 8 cloud legs), so it
// is restored here, in the false arm, rather than left to a codeunit that was red on Windows.
//
// The claim it restores is a claim about the PLATFORM, not the harness: the string appears
// nowhere in MsDyn365Bc.On.Linux, so it comes from BC's own path under StartupHook Patch #19.
//
// WHY ONE TEST BRANCHING ON THE RETURN VALUE, RATHER THAN TWO PLATFORM-GUARDED TESTS.
//
// The two tiers disagree today: on a Windows container SaveAs returns true; on
// MsDyn365Bc.On.Linux (StartupHook Patch #19) it returns false. A test that flatly asserted
// "the blob is a PDF" would be red by construction on Linux -- which is the exact problem
// #213 is trying to get OUT of, so adding a second permanently-red test would make the
// situation worse rather than measure it.
//
// The corpus has no preprocessor symbol for the tier. #if BC27PLUS/BC28PLUS are BC VERSION
// symbols set from the matrix (CONTRIBUTING.md), not platform symbols -- both tiers run the
// same version set, so neither can express "Windows" or "Linux". Nor should this file invent
// one: the tier is not a property AL can read, and a guard keyed on anything else would be a
// guess. What AL CAN read is what SaveAs returned, and BC's own contract makes that the right
// discriminator -- SaveReportAsFormatCoreAsync returns `result == ReportExecutionResult.Success`
// and throws nothing for a rendering failure, so the boolean IS the platform's own report of
// whether it rendered.
//
// So the assertion is a correlation, and the correlation is the finding:
//
//     SaveAs returned TRUE  -> the blob must be a plausible PDF (non-empty, and its first
//                              bytes are the "%PDF-" signature).
//     SaveAs returned FALSE -> the blob must be EMPTY. A tier that refuses to render must
//                              not leave a partial or garbage payload behind.
//
// Both branches assert something falsifiable, so neither is a free pass. The test cannot go
// green by SaveAs doing nothing at all: "returned false" is only accepted together with an
// empty blob, and "returned true" is only accepted together with PDF bytes.
//
// WHAT IT REPORTS ON EACH TIER (stated up front so a reader need not run it to know):
//
//   * Linux CI (ci.yml, the 8 required legs): SaveAs returns false, so the false branch runs
//     and asserts the blob is empty. Expected GREEN. If it goes red, the finding is that the
//     Linux tier writes bytes into the stream while reporting failure -- worth knowing, and
//     currently unmeasured.
//   * Windows (nightly-windows.yml / a real SaaS tier): SaveAs returns true, so the true
//     branch runs and asserts %PDF-. Expected GREEN, and THAT green is the new evidence --
//     it is the first time the corpus will have established that the Windows RDLC path
//     produces actual PDF bytes rather than merely returning true.
//
//   Both arms are now MEASURED, not anticipated:
//     Linux   -- corpus PR #239, green on all 8 cloud legs: SaveAs false, blob EMPTY.
//     Windows -- nightly run 34094539603, official MS container, BC 28.4: SaveAs true and
//                the %PDF- arm green. The first time the corpus established that the
//                Windows RDLC path emits real PDF bytes rather than merely returning true.
//
//   The negative arm is the half most likely to be assumed rather than checked: a tier that
//   refuses to render leaves the stream UNTOUCHED, not partially written.
//
// WHY BASE64 AND NOT ReadText.
//
// The sibling Xml test (TestReportSaveAsStream.al) loops InStr.ReadText -- correct there,
// because a dataset is text. A PDF is binary: byte 5 of a real PDF is a version digit but
// bytes further in are arbitrary, including NUL and 0x0A/0x0D, and ReadText is line- and
// encoding-oriented. Rather than assume ReadText survives that intact, this file converts
// the blob to Base64 (System App codeunit "Base64 Convert", already used in the corpus by
// TestMediaPngImport.al) and inspects the encoded prefix. Base64 is lossless over arbitrary
// bytes, so the assertion is about what SaveAs actually wrote, not about what a text reader
// could recover from it.
//
// "%PDF-" is the 5-byte signature at offset 0 of every PDF (ISO 32000-1 7.5.2). Base64 packs
// 3 input bytes into 4 output characters on a fixed grid, and the exact cut matters -- the
// first draft of this file got it wrong and a check falsified it before it was ever pushed:
//
//   * Characters 1-6 are determined by bytes 0-3 plus the HIGH 4 BITS of byte 4. So
//     'JVBERi' proves bytes 0-3 are exactly '%PDF', but on its own it admits any byte 4 in
//     0x20..0x2F -- '%PDF.' and '%PDF/' also encode to 'JVBERi'. Not exact.
//   * Character 7 carries the LOW 2 BITS of byte 4 (plus the high 2 of byte 5), and its
//     value set is disjoint per byte 4: byte 4 = '-' gives exactly {'0','1','2','3'},
//     '.' gives {'4'..'7'}, ' ' gives {'A'..'D'}. Verified by enumerating all 256 values of
//     byte 4 and all 256 of byte 5.
//
// So the pair of assertions below -- first 6 characters equal 'JVBERi', AND character 7 is
// one of '0'..'3' -- pins bytes 0-4 to exactly '%PDF-' while depending on NOTHING from byte
// 5 onward. A single 7-character comparison would NOT do this: character 7 varies with byte
// 5, so it would reject real PDFs.
//
// WHAT EACH ASSERTION SEPARATES (per #238's "make it discriminate" requirement):
//   Length > 0                   separates EMPTY from non-empty.
//   first 6 chars = 'JVBERi'     separates '%PDF' at offset 0 from non-PDF content
//                                (an error page, an HTML body, a dataset XML, zero-fill).
//   char 7 in '0'..'3'           completes the signature: byte 4 is '-' and not one of the
//                                other 15 bytes the 6-char prefix alone would admit.
//   Length = 0 on the false path separates "refused cleanly" from "refused but wrote junk".
//   error text on the false path separates "refused for the RDLC reason this tier documents"
//                                from "refused silently, or for some other reason" -- the
//                                assertion restored from cu 60878 (#256).

codeunit 60774 "Test Report SaveAs Pdf Body"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        // Base64 of bytes 0-3 ('%','P','D','F') plus the high nibble of byte 4. Determined
        // entirely by bytes 0-4; carries nothing from byte 5 onward.
        PdfHeaderBase64Prefix: Label 'JVBERi', Locked = true;
        // The character-7 values that mean byte 4 is exactly '-' (0x2D). Disjoint from the
        // sets produced by every other byte 4, so together with the prefix above this pins
        // the full 5-byte '%PDF-' signature.
        PdfHeaderBase64Char7Set: Label '0123', Locked = true;

    local procedure Initialize()
    var
        Sample: Record "RSS Sample";
    begin
        Sample.DeleteAll();
    end;

    [Test]
    procedure Report_SaveAs_Pdf_ReturnValueAgreesWithTheBytesInTheStream()
    // CLAIM: Report.SaveAs(..., ReportFormat::Pdf, ...) leaves the stream in a state that
    // matches what it returned -- a PDF-signed, non-empty payload when it returned true, and
    // nothing at all when it returned false. Neither branch is satisfiable by a SaveAs that
    // writes nothing and returns true, nor by one that writes garbage and returns false.
    var
        Sample: Record "RSS Sample";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStr: OutStream;
        InStr: InStream;
        Encoded: Text;
        BlobLength: Integer;
        Ok: Boolean;
    begin
        Initialize();
        Sample."Entry No." := 1;
        Sample.Description := 'RSSPDF-9f1c2b3a';
        Sample.Amount := 42.5;
        Sample.Insert();

        TempBlob.CreateOutStream(OutStr);
        Ok := Report.SaveAs(Report::"RSS Fixture Report", '', ReportFormat::Pdf, OutStr);

        BlobLength := TempBlob.Length();

        if Ok then begin
            // The rendering tier (Windows / SaaS). Returning true must mean bytes were
            // produced -- this is the assertion #238 says the corpus is missing.
            Assert.IsTrue(BlobLength > 0,
                'Report.SaveAs(Pdf) returned true but wrote 0 bytes -- the return value claims a render that did not reach the stream.');

            TempBlob.CreateInStream(InStr);
            Encoded := Base64Convert.ToBase64(InStr);

            // Guard the CopyStr calls below and make a too-short payload fail as itself
            // rather than as a confusing prefix mismatch.
            Assert.IsTrue(StrLen(Encoded) >= StrLen(PdfHeaderBase64Prefix) + 1,
                StrSubstNo('Report.SaveAs(Pdf) returned true but wrote only %1 bytes -- too short to carry even a PDF header.', BlobLength));

            // Bytes 0-3 are exactly '%PDF'.
            Assert.AreEqual(
                PdfHeaderBase64Prefix,
                CopyStr(Encoded, 1, StrLen(PdfHeaderBase64Prefix)),
                StrSubstNo('Report.SaveAs(Pdf) returned true and wrote %1 bytes, but they do not begin with "%%PDF" -- the stream holds something other than a PDF.', BlobLength));

            // ...and byte 4 is exactly '-', completing the 5-byte signature.
            Assert.IsTrue(
                StrPos(PdfHeaderBase64Char7Set, CopyStr(Encoded, StrLen(PdfHeaderBase64Prefix) + 1, 1)) > 0,
                StrSubstNo('Report.SaveAs(Pdf) returned true and wrote %1 bytes beginning "%%PDF", but the 5th byte is not "-" -- not a PDF signature.', BlobLength));
        end else begin
            // The non-rendering tier (BC-on-Linux, StartupHook Patch #19). Returning false
            // must mean the stream was left alone. BC's own SaveReportAsFormatCoreAsync
            // erases the target on a non-Success result, so "false" is meant to be a clean
            // refusal; this pins that it is one for the stream overload too.
            Assert.AreEqual(0, BlobLength,
                'Report.SaveAs(Pdf) returned false but still wrote bytes into the stream -- a refused render must not leave a partial payload behind.');

            // ...and the refusal must SAY WHY. Carried across from cu 60878 when that
            // codeunit was deleted (#250): of 60878's two assertions this is the one this
            // file did not already make, and it was passing on all 8 cloud legs at the
            // moment it was removed (run 34099499973). See #256.
            //
            // WHY THIS IS IN THE FALSE ARM ONLY. On a tier that renders there is no error to
            // read -- SaveAs returned true, nothing failed, and GetLastErrorText holds
            // whatever unrelated text an earlier statement happened to leave behind. Asserting
            // it there would be asserting on a value this test did not produce. The error text
            // exists only where the render was refused.
            //
            // WHY NO asserterror. SaveReportAsFormatCoreAsync returns a result rather than
            // throwing, so nothing propagates to AL and there is no statement for asserterror
            // to wrap. The platform still SETS the last-error text on its way to returning
            // false, and GetLastErrorText reads it -- which is what 60878 measured.
            //
            // AND IT CAN FAIL, which is what makes it worth adding. Assert.ExpectedError
            // (cu 60021) takes its comparison branch whenever the expected text is non-empty,
            // because the no-error shortcut requires BOTH sides empty; it then fails unless
            // StrPos(GetLastErrorText, Expected) > 0. With no error in scope GetLastErrorText
            // is '', a non-empty needle is not found in it, StrPos returns 0, and the
            // assertion raises ExpectedErrorFailed. A tier that began refusing silently, or
            // with different text, turns this red rather than sliding past it.
            Assert.ExpectedError('RDLC report rendering is not implemented on Linux BC');
        end;
    end;
}
