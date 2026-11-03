// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIS Setup (60607)
//
// Private cache for "Test SingleInstance Run Scope" (60614). Same shape as SIS Cache
// (60608) — SingleInstance, a global record read once and latched behind a boolean.
//
// WHY A SECOND CACHE RATHER THAN A RESET ON THE FIRST ONE. A SingleInstance instance is
// registered on the session's company and lives until that company scope is disposed, so
// three test codeunits sharing one cache means the first one to read it decides what the
// other two see. That is BC behaving as specified; the fault was the shared fixture. Adding
// a reset procedure would not fix it either, because the reset is exactly the state these
// tests exist to prove is kept — see the file header on TestSingleInstanceRunScope.al.
//
// NO EventSubscriber HERE, DELIBERATELY. SIS Cache (60608) subscribes to
// SIS Publisher.OnResolveCurrency, and that publisher's Resolve() returns whatever the LAST
// subscriber assigned. A second subscriber on the same event would make that return value
// depend on subscriber dispatch order — reintroducing an order dependency in the exact place
// this change removes one. 60614 primes through Codeunit.Run, never through dispatch, so it
// needs no subscriber at all.

codeunit 60625 "SIS Run Scope Cache"
{
    SingleInstance = true;

    var
        Setup: Record "SIS Setup";
        SetupRead: Boolean;
        ReadCount: Integer;

    procedure GetCurrencyCode(): Code[10]
    begin
        if not SetupRead then begin
            Setup.Get('MAIN');
            ReadCount += 1;
        end;
        SetupRead := true;
        exit(Setup."Currency Code");
    end;

    procedure GetReadCount(): Integer
    begin
        exit(ReadCount);
    end;
}
