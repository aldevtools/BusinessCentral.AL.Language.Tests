// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); helper codeunit 71928 (not a test codeunit)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the emit version number of the missing-object error (the Observer scrubs it in the text, so it is cut out here and observed as a number: the value, the value div 1000, mod 1000), the same number for a missing codeunit, table (RecordRef.Open), page and report, and the caller named in the text when the call runs in the test codeunit and in a helper codeunit.
// BC versions: 29 (27 and 28 by CI; the number differs per major: record each major's value)

codeunit 71928 "LT P160 Missing Caller"
{
    procedure RunMissingCodeunit()
    begin
        Codeunit.Run(71998);
    end;
}

