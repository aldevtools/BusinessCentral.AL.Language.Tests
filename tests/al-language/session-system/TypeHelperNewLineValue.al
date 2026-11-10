// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system-text-typehelper
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 10 "Type Helper" (System Application)
// Probe: al-runner issue 6924 (Type Helper.NewLine, the platform class Microsoft.Dynamics.Nav.SystemEnvironment.SystemEnvironment).
// Facts: the full value of Type Helper.NewLine: its length and the character code of each character, next to CRLFSeparator and LFSeparator.
//   CnSessionLeads.al TypeHelper_NewLine_CharacterCodes only pins that the last character is LF (code 10); it ignores the rest.
//   Microsoft's own TestNewLine (TypeHelperUnitTests.Codeunit.al:508-515) asserts NewLine = CRLFSeparator, so CR LF (13,10) is expected.
// Measured: not yet. The expected values below are those of Microsoft's test. The bc-linux server writes CR LF only with its
//   Environment.NewLine patch (bc-linux issues 227 and 228, pinned in the corpus by pull request 1280): a result from a CI run before
//   that pin may be LF (10, length 1). If the first CI run observes LF, the Expect lines change to what real BC gave, not the other way round.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 74500 "LT TH NewLine Value"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Codes(Value: Text) Codes: Text
    var
        Ch: Char;
        Code: Integer;
        i: Integer;
    begin
        for i := 1 to StrLen(Value) do begin
            Ch := Value[i];
            Code := Ch;
            if Codes <> '' then
                Codes += ',';
            Codes += Format(Code);
        end;
    end;

    [Test]
    procedure TypeHelper_NewLine_FullValue()
    var
        Observer: Codeunit "Probe Observer";
        TypeHelper: Codeunit "Type Helper";
        NL: Text;
    begin
        NL := TypeHelper.NewLine();
        Observer.Observe('NewLine length', Format(StrLen(NL)));
        Observer.Observe('NewLine codes', Codes(NL));
        Observer.Observe('NewLine = CRLFSeparator', Format(NL = TypeHelper.CRLFSeparator()));
        Observer.Observe('NewLine = LFSeparator', Format(NL = TypeHelper.LFSeparator()));
        Observer.Observe('CRLFSeparator codes', Codes(TypeHelper.CRLFSeparator()));
        Observer.Observe('LFSeparator codes', Codes(TypeHelper.LFSeparator()));
        Observer.Expect('NewLine length', '2');
        Observer.Expect('NewLine codes', '13,10');
        Observer.Expect('NewLine = CRLFSeparator', 'Yes');
        Observer.Expect('NewLine = LFSeparator', 'No');
        Observer.Expect('CRLFSeparator codes', '13,10');
        Observer.Expect('LFSeparator codes', '10');
        Observer.Verify();
    end;
}
