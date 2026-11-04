// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-field-setvalue-method
// Scope: in-scope
// Fixtures used: Spaced Field Row (60247)
//
// Backing table for the spaced-field-control OnValidate suite (companion to
// TestPageSpacedActionName, which covers spaced ACTION names). Payload is the
// field two controls bind; Marker records which control's page OnValidate ran.

table 60247 "Spaced Field Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Payload; Text[100]) { }
        field(3; Marker; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
