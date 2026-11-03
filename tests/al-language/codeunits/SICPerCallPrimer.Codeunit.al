// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIC Per Call Probe (60629)
//
// Contrast-case counterpart to SIC Session Scoped Primer (60628): crosses the same codeunit
// boundary, but bumps the ordinary (SingleInstance = false) probe, whose state must NOT be
// visible to the caller afterwards.

codeunit 60630 "SIC Per Call Primer"
{
    trigger OnRun()
    var
        PerCall: Codeunit "SIC Per Call Probe";
    begin
        PerCall.Bump();
    end;
}
