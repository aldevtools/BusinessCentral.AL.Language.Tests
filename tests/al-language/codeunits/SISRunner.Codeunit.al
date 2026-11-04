// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIS Run Scope Cache (60625)
//
// Primes the SingleInstance cache from inside a Codeunit.Run scope — a real, disposable
// scope of its own.

codeunit 60611 "SIS Runner"
{
    trigger OnRun()
    var
        Cache: Codeunit "SIS Run Scope Cache";
    begin
        Cache.GetCurrencyCode();
    end;
}
