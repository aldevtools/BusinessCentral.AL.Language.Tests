// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Test Page Enum Field Grade (60688)
//
// Members live on a separate object, not on the field that uses it — which is the whole
// difference this suite is about.
//
// Captions are deliberately identical to the member names. Whether BC's TestPage resolves a
// member by name or by caption when the two differ is a real question, but it is not one this
// suite has verified against a service tier, so it asserts nothing about it.

enum 60688 "Test Page Enum Field Grade"
{
    Extensible = false;

    value(0; Low) { Caption = 'Low'; }
    value(1; Mid) { Caption = 'Mid'; }
    value(2; High) { Caption = 'High'; }
}
