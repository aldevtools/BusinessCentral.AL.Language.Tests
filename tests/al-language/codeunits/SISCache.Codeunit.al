// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIS Setup (60607)
//
// Deliberately shaped like Base App codeunit 347 "Auto Format": SingleInstance, with a
// global record it reads once and caches behind a boolean. That global is a record HANDLE,
// and the handle is what goes null when the tree it hangs off is disposed.
//
// OWNED BY ONE TEST CODEUNIT: "Test SingleInstance Scope Exit" (60613). Its two siblings own
// SIS Run Scope Cache (60625) and SIS Failed Scope Cache (60626). A SingleInstance instance
// is company-scoped and is not reset between test codeunits, so while all three shared this
// one, whichever ran first latched it and decided the other two's answers (corpus #261).
// Do not point a second test codeunit at it.
//
// It is also the ONLY subscriber to SIS Publisher.OnResolveCurrency, and must stay so:
// Resolve() returns whatever the last subscriber assigned, so a second subscriber would make
// 60613's Publisher.Resolve() assertions depend on subscriber dispatch order.
//
// Its object id and name are load-bearing beyond this file — TestCodeunitInventoryOrder.al
// and TestCodeunitMetadataVirtualTable.al assert on both. Neither may be changed.

codeunit 60608 "SIS Cache"
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SIS Publisher", 'OnResolveCurrency', '', false, false)]
    local procedure OnResolveCurrency(var CurrencyCode: Code[10])
    begin
        CurrencyCode := GetCurrencyCode();
    end;
}
