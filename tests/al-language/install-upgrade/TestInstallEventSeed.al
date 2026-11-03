// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: none
//
// Target table for the rows an event SUBSCRIBER writes while the install
// trigger is running. Kept separate from "Install Seed" (60617) on purpose:
// the tests over that table assert an exact row count, so anything written by
// a different mechanism has to land somewhere else to keep those counts
// meaningful.

table 60832 "Install Event Seed"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Source"; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
