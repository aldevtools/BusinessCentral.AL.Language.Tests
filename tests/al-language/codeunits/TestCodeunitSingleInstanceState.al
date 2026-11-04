// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: none
//
// SingleInstance=true codeunit: exactly one instance per session in real BC, so
// StoredValue set through one handle/variable must be visible through a different
// handle/variable of the same codeunit within the same test.
//
// OWNED BY ONE TEST CODEUNIT: "Test Codeunit SingleInstance" (60599). A SingleInstance
// instance is company-scoped and is not reset between test codeunits, so a second test
// codeunit reading this fixture would see whatever 60599 left behind and its answer would
// depend on run order (corpus #261). 60599's own test is safe because it ASSIGNS an
// absolute value before reading it back rather than relying on a starting state.

codeunit 60597 "Test SIC Single"
{
    SingleInstance = true;

    var
        StoredValue: Integer;

    procedure SetValue(V: Integer)
    begin
        StoredValue := V;
    end;

    procedure GetValue(): Integer
    begin
        exit(StoredValue);
    end;
}
