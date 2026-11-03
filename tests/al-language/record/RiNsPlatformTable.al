// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-in-al
// Scope: in-scope
// Fixtures used: none (self-contained)
// Probe (writer RI, al-runtime-rs issue 5694): code in a namespace reaches the platform table Integer (namespace System.Utilities) through
//   `using System.Utilities;`, by its bare name and by its qualified name. Without the using the bare name does not compile (AL0185,
//   tests/must-not-compile/cases/2081-namespace-record-integer-without-using.al and 2082-namespace-report-dataitem-integer-without-using.al).
// BC versions: 27, 28, 29

namespace LT.RI.NsPlatform;

using System.Utilities;

codeunit 88062 "LT RI Ns Platform Table"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure UsingSystemUtilities_RecordInteger_BareAndQualified()
    var
        Number: Record Integer;
        Qualified: Record System.Utilities.Integer;
    begin
        Number.SetRange(Number, 1, 3);
        Qualified.SetRange(Number, 2, 7);
        if (Number.Count() <> 3) or (Qualified.Count() <> 6) then
            Error('LT RI counts: bare %1, qualified %2', Number.Count(), Qualified.Count());
    end;
}
