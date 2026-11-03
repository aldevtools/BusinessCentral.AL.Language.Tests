// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIS Failed Scope Cache (60626)
//
// Primes the cache and then FAILS. The rollback path is where a scope is disposed outright
// rather than merely detached, which is what takes the cached instance with it.

codeunit 60612 "SIS Failing Runner"
{
    trigger OnRun()
    var
        Cache: Codeunit "SIS Failed Scope Cache";
    begin
        Cache.GetCurrencyCode();
        Error('deliberate');
    end;
}
