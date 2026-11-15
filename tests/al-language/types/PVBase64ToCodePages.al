// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/base64convert/base64convert-codeunit
// Scope: in-scope
// Probe: not run yet. Observe form: run on BC 27.5, 28.5 and 29.0, then turn each Observe into an Expect with the value the tier gave.
//
// System Application "Base64 Convert".ToBase64(Text, TextEncoding, CodePage) with an encoding and a code page that
// PVBase64.al does not measure (it measures Windows with 1252 and 28591, UTF8 with 65001). The docs say the code page
// applies "if TextEncoding is MsDos or Windows". al-runner issue 8069: al-runner refuses UTF8 with 1252 and 28591;
// MSDos with 1252 or 28591 and Windows or MSDos with 65001 keep the runner's answer until this probe measures them.
// Each cell is its own TryFunction call, so an error in one cell does not hide the others; the error text and code are observed.
// Fixtures used: self-contained codeunit 99984 (check the id against open probe branches)
// BC versions: 27.5, 28.5, 29.0

codeunit 99984 "PV Base64 To Code Pages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryTo(Value: Text; Encoding: TextEncoding; CodePage: Integer; var Result: Text)
    var
        Base64: Codeunit "Base64 Convert";
    begin
        Result := Base64.ToBase64(Value, Encoding, CodePage);
    end;

    local procedure Cell(Observer: Codeunit "Probe Observer"; Name: Text; Value: Text; Encoding: TextEncoding; CodePage: Integer)
    var
        Result: Text;
    begin
        if TryTo(Value, Encoding, CodePage, Result) then
            Observer.Observe(Name, Result)
        else
            Observer.Observe(Name, 'error: ' + GetLastErrorCode() + ': ' + GetLastErrorText());
    end;

    [Test]
    procedure ToBase64_EncodingAndCodePage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // 'äöü' is C3 A4 C3 B6 C3 BC in UTF-8 (w6TDtsO8) and E4 F6 FC in Windows-1252 and Latin-1 (5Pb8).
        Cell(Observer, 'utf8_1252', 'äöü', TextEncoding::UTF8, 1252);
        Cell(Observer, 'utf8_28591', 'äöü', TextEncoding::UTF8, 28591);
        Cell(Observer, 'msdos_1252', 'äöü', TextEncoding::MSDos, 1252);
        Cell(Observer, 'msdos_28591', 'äöü', TextEncoding::MSDos, 28591);
        Cell(Observer, 'windows_65001', 'äöü', TextEncoding::Windows, 65001);
        Cell(Observer, 'msdos_65001', 'äöü', TextEncoding::MSDos, 65001);
        // The reporter's value: two times U+00FF (w7/Dvw== in UTF-8, //8= in Windows-1252).
        Cell(Observer, 'utf8_1252_ydiaeresis', 'ÿÿ', TextEncoding::UTF8, 1252);
        // The euro sign: 0x80 in Windows-1252, not in Latin-1.
        Cell(Observer, 'utf8_1252_euro', '€', TextEncoding::UTF8, 1252);
        Observer.Verify();
    end;
}
