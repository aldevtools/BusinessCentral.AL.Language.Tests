// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-new-method
// Scope: in-scope
// Fixtures used: NRB Header (60649)
//
// Header table for the New()-record-init suite: just the parent a SubPageLink points at, the
// same shape as the ASK / TSPL / PKFL header fixtures.

table 60649 "NRB Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
