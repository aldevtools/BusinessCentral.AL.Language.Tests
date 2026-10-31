// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Shared fixture: untranslated object and field names.
table 67021 "ALT TF Plain Target"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Report Type"; Option)
        {
            OptionMembers = DIAM,LGDIAM;
        }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
