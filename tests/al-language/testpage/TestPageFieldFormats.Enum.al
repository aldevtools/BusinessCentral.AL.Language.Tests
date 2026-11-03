// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: (none)

enum 69932 "TPF Enum"
{
    Extensible = true;

    value(0; One) { Caption = 'Eins'; }
    value(1; Two) { Caption = 'Zwei'; }
    value(2; Three) { Caption = 'Drei'; }
}
