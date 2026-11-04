// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIS Setup (60607)
//
// Private cache for "Test SingleInstance Failed Scp" (60615). Same shape and the same
// reasoning as SIS Run Scope Cache (60625): a per-test-codeunit cache, and no
// EventSubscriber, because 60615 primes through Codeunit.Run rather than event dispatch.

codeunit 60626 "SIS Failed Scope Cache"
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
