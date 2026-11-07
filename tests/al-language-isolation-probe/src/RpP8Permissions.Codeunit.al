namespace ALLanguage.IsolationProbe;

// Probe P8 (ADR-066 of al-runtime-rs): this codeunit sets no TestPermissions property. The
// reader (61346) reads the FunctionTestPermissions value OnBeforeTestRun got for each method:
// one without an attribute (the question), and two with an explicit attribute as controls.
// The bodies touch no table, so the permission set does not matter to them.
codeunit 61345 "LT RP P8 Permissions"
{
    Subtype = Test;

    [Test]
    procedure P8_NoAttribute()
    begin
    end;

    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure P8_Restrictive()
    begin
    end;

    [Test]
    [TestPermissions(TestPermissions::NonRestrictive)]
    procedure P8_NonRestrictive()
    begin
    end;
}
