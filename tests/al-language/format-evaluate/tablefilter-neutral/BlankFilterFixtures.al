// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: Cloud-compatible. BC versions: 27.5+.
// local object: the enum's blank member and the filter target's field types are under test.
enum 69004 "FMT Blank Member Choice"
{
    Extensible = false;
    value(0; " ") { Caption = ' '; }
    value(1; Marked) { Caption = 'Marked'; }
}
table 69024 "FMT Blank Filter Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Choice; Enum "FMT Blank Member Choice") { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
