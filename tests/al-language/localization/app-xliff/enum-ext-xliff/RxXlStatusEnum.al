// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-work-with-translation-files
// Scope: in-scope
// Fixtures used: none; translation units "Enum RX Xl Status - EnumValue Draft / Ready - Property Caption" in
//   Translations/AL Language Coverage Tests.nl-NL.xlf (Plain has no unit)
// Facts: an extensible enum of this app whose captions this app's nl-NL file translates. The OnPrem test app extends it with its own
//   nl-NL file (tests/al-language-onprem/localization/enum-ext-xliff/RxXlStatusExtTests.al, which holds the tests and the results).
// local object: the enum and its translation units are what the tests check (al-runner issue 6924).
// BC versions: 27 - 29

enum 80030 "RX Xl Status"
{
    Extensible = true;

    value(0; Draft)
    {
        Caption = 'Draft EN';
    }
    value(1; Ready)
    {
        Caption = 'Ready EN';
    }
    value(2; Plain)
    {
        Caption = 'Plain EN';
    }
}
