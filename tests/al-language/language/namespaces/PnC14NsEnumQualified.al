// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-directive
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC NsEnum (71092)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Namespaces "Enum::Ns.Sub.\"Name\".FromInteger(n) / .Names(), Ns.Sub.\"Name\"::Value and Enum::Ns.Sub.\"Name\"::Value" (qualified forms, no using)
// BC versions: 29 (27 and 28 by CI)

namespace LTPnC.Other;

codeunit 71120 "LT PnC Ns Enum Qualified"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Forms_Qualified()
    var
        Observer: Codeunit "Probe Observer";
        E: Enum LTPnC.Enums."LT PnC NsEnum";
        Names: List of [Text];
        Name: Text;
        Joined: Text;
    begin
        E := Enum::LTPnC.Enums."LT PnC NsEnum"::"Third Value";
        Observer.Observe('enumPrefix.value', Format(E));
        E := LTPnC.Enums."LT PnC NsEnum"::First;
        Observer.Observe('typeName.value', Format(E));
        E := Enum::LTPnC.Enums."LT PnC NsEnum".FromInteger(3);
        Observer.Observe('fromInteger', Format(E));
        Names := Enum::LTPnC.Enums."LT PnC NsEnum".Names();
        foreach Name in Names do begin
            Joined += Name + ',';
        end;
        Observer.Observe('names', Joined);
        Observer.Observe('ordinals', Format(Enum::LTPnC.Enums."LT PnC NsEnum".Ordinals().Count()));
        Observer.Expect('enumPrefix.value', 'Third Caption');
        Observer.Expect('typeName.value', 'First');
        Observer.Expect('fromInteger', 'Third Caption');
        Observer.Expect('names', 'First,Third Value,');
        Observer.Expect('ordinals', '2');
        Observer.Verify();
    end;
}
