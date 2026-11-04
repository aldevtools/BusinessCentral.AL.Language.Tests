// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: none
//
// Publishes the event the SingleInstance cache subscribes to. The real failure (Base App
// codeunit 347 "Auto Format") is reached exactly this way — through event dispatch, not a
// direct call — and dispatch is what resolves the codeunit against a scope that then ends.

codeunit 60610 "SIS Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnResolveCurrency(var CurrencyCode: Code[10])
    begin
    end;

    procedure Resolve(): Code[10]
    var
        CurrencyCode: Code[10];
    begin
        OnResolveCurrency(CurrencyCode);
        exit(CurrencyCode);
    end;
}
