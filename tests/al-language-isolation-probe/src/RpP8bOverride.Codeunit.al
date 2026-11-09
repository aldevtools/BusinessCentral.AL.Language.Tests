namespace ALLanguage.IsolationProbe;

// Probe P8b (ADR-066 of al-runtime-rs): the codeunit property says Disabled, one method carries
// an attribute. "LT RP Reader B" (61349) reads the FunctionTestPermissions value OnBeforeTestRun
// got for the method: the attribute or the codeunit's property.
codeunit 61348 "LT RP P8b Override"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TestPermissions(TestPermissions::NonRestrictive)]
    procedure P8b_AttributeOverCodeunitProperty()
    begin
    end;
}
