// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-excel-buffer
// local object: installation must store the generated workbook for a later test session.
table 99461 "LT Install Workbook Obs"
{
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Workbook; Blob) { }
        field(3; "Probe Error"; Text[250]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}
