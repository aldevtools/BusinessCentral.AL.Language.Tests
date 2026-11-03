// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: none
//
// Ordinary (SingleInstance=false, the default) codeunit — contrast case. Every
// codeunit variable of this type must get its OWN fresh instance, unlike
// "Test SIC Single".

codeunit 60598 "Test SIC Multi"
{
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
