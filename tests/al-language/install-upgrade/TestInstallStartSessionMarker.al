// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-startsession-method
// Scope: in-scope
// Fixtures used: none
//
// Written ONLY by "Install StartSession Worker" (60448). A row here means a StartSession call
// from "Install StartSession Probe" actually ran the worker. Kept apart from "Install Seed",
// whose row count the install-seed tests assert exactly.

table 60447 "Install StartSession Marker"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Value"; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
